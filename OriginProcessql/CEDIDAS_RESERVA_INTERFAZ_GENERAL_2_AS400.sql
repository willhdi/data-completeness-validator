/*Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ
  Intermediario Liberty.RESERVAS.POLIZA_INTERMEDIARIO
  Corretaje     Liberty_Pruebas_Actuaria.dbo.polizas_corretaje_iaxis
  Tomadores     Liberty.APOYO.DWH_TOMADORES
  Tabla final   ##cedidas_reserva_final_devengada_tmp */

SET NOCOUNT ON;


/* LIMPIEZA  */

IF OBJECT_ID('tempdb..#CLAVES_ASOCIADAS_IAXIS') IS NOT NULL DROP TABLE #CLAVES_ASOCIADAS_IAXIS;

IF OBJECT_ID('tempdb..#TOMADORES_CEDIDAS_NORMALIZADO') IS NOT NULL DROP TABLE #TOMADORES_CEDIDAS_NORMALIZADO;
IF OBJECT_ID('tempdb..#TOMADORES_CEDIDAS_INTERMEDIARIO') IS NOT NULL DROP TABLE #TOMADORES_CEDIDAS_INTERMEDIARIO;
IF OBJECT_ID('tempdb..#TOMADORES_CEDIDAS_POLIZA') IS NOT NULL DROP TABLE #TOMADORES_CEDIDAS_POLIZA;

IF OBJECT_ID('tempdb..#CEDIDAS_FUENTE') IS NOT NULL DROP TABLE #CEDIDAS_FUENTE;
IF OBJECT_ID('tempdb..#POLIZA_INTERMEDIARIO_IAXIS_CEDIDAS') IS NOT NULL DROP TABLE #POLIZA_INTERMEDIARIO_IAXIS_CEDIDAS;

IF OBJECT_ID('tempdb..#CORRETAJE_BASE_CEDIDAS') IS NOT NULL DROP TABLE #CORRETAJE_BASE_CEDIDAS;
IF OBJECT_ID('tempdb..#CORRETAJE_LIDERES_CEDIDAS') IS NOT NULL DROP TABLE #CORRETAJE_LIDERES_CEDIDAS;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_RESUMEN_CEDIDAS') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_RESUMEN_CEDIDAS;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_APLICABLES_CEDIDAS') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_APLICABLES_CEDIDAS;

IF OBJECT_ID('tempdb..#CEDIDAS_INTERMEDIARIO_CANDIDATOS') IS NOT NULL DROP TABLE #CEDIDAS_INTERMEDIARIO_CANDIDATOS;
IF OBJECT_ID('tempdb..#CEDIDAS_INTERMEDIARIO_RESUELTO') IS NOT NULL DROP TABLE #CEDIDAS_INTERMEDIARIO_RESUELTO;

IF OBJECT_ID('tempdb..#CEDIDAS_BASE') IS NOT NULL DROP TABLE #CEDIDAS_BASE;
IF OBJECT_ID('tempdb..#CEDIDAS_CON_CORRETAJE') IS NOT NULL DROP TABLE #CEDIDAS_CON_CORRETAJE;

IF OBJECT_ID('tempdb..#CEDIDAS_GENERAL') IS NOT NULL DROP TABLE #CEDIDAS_GENERAL;
IF OBJECT_ID('tempdb..#CEDIDAS_COCORRETAJE_DETALLE') IS NOT NULL DROP TABLE #CEDIDAS_COCORRETAJE_DETALLE;
IF OBJECT_ID('tempdb..#CEDIDAS_COCORRETAJE') IS NOT NULL DROP TABLE #CEDIDAS_COCORRETAJE;

IF OBJECT_ID('tempdb..#cedidas_reserva_final_devengada_tmp') IS NOT NULL DROP TABLE #cedidas_reserva_final_devengada_tmp;
IF OBJECT_ID('tempdb..##cedidas_reserva_final_devengada_tmp') IS NOT NULL DROP TABLE ##cedidas_reserva_final_devengada_tmp;


/* VARIABLES */

DECLARE @PERIODO_INI_CED INT = 202601;
DECLARE @PERIODO_FIN_CED INT = 202605;

DECLARE @MACRO_CEDIDA VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_CEDIDA VARCHAR(80) = 'Devengada_Cedida';

DECLARE @MACRO_COCORRETAJE_CED VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_COCORRETAJE_CED VARCHAR(100) = 'Devengada_Cedida_CO-Corretaje';

DECLARE @FUENTE_CEDIDA VARCHAR(150) = 'Liberty.[RESERVAS].[CEDIDAS_RESERVA_INTERFAZ]';


/*  UNIVERSO DE CLAVES IAXIS */
/*
SELECT DISTINCT
    TRY_CONVERT(BIGINT, b.CLAVE_INICIAL_ASOCIADA) AS intermediario_lide
INTO #CLAVES_ASOCIADAS_IAXIS
FROM Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores b
WHERE b.cia = 'IAXIS'
  AND b.CLAVE_INICIAL_ASOCIADA IS NOT NULL
  AND TRY_CONVERT(BIGINT, b.CLAVE_INICIAL_ASOCIADA) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CLAVES_ASOCIADAS_IAXIS
ON #CLAVES_ASOCIADAS_IAXIS(intermediario_lide);

*/
/*  TOMADORES NORMALIZADOS */

SELECT
    CAST(NULLIF(LTRIM(RTRIM(CAST(t.COD_RAMO_PROD AS VARCHAR(20)))), '') AS VARCHAR(20)) AS ramo_prod,
    TRY_CONVERT(BIGINT, t.NRO_POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, t.COD_INTERMEDIARIO) AS cod_intermediario,

    CAST(
        ISNULL(NULLIF(LTRIM(RTRIM(CAST(t.TIPO_DOCUMENTO_TOMADOR AS VARCHAR(10)))), ''), 'NULL')
        AS VARCHAR(10)
    ) AS tipo_identifi_tomador,

    CAST(
        ISNULL(NULLIF(LTRIM(RTRIM(CAST(t.NRO_DOCUMENTO_TOMADOR AS VARCHAR(50)))), ''), 'NULL')
        AS VARCHAR(50)
    ) AS Numero_identificacion_tomador,

    t.FECHA_ACTUALIZACION_DWH,
    t.FECHA_EJECUCION_DWH
INTO #TOMADORES_CEDIDAS_NORMALIZADO
FROM Liberty.APOYO.DWH_TOMADORES t
WHERE t.COD_RAMO_PROD IS NOT NULL
  AND t.NRO_POLIZA IS NOT NULL
  AND TRY_CONVERT(BIGINT, t.NRO_POLIZA) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_TOMADORES_CEDIDAS_NORMALIZADO
ON #TOMADORES_CEDIDAS_NORMALIZADO
(
    ramo_prod,
    poliza,
    cod_intermediario
);


/* TOMADOR ÚNICO POR RAMO + PÓLIZA + INTERMEDIARIO */

;WITH TOMADOR_INTERMEDIARIO AS
(
    SELECT
        t.*,
        ROW_NUMBER() OVER
        (
            PARTITION BY
                t.ramo_prod,
                t.poliza,
                t.cod_intermediario
            ORDER BY
                COALESCE(t.FECHA_ACTUALIZACION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC,
                COALESCE(t.FECHA_EJECUCION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC
        ) AS rn
    FROM #TOMADORES_CEDIDAS_NORMALIZADO t
    WHERE t.cod_intermediario IS NOT NULL
)
SELECT
    ramo_prod,
    poliza,
    cod_intermediario,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_CEDIDAS_INTERMEDIARIO
FROM TOMADOR_INTERMEDIARIO
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_CEDIDAS_INTERMEDIARIO
ON #TOMADORES_CEDIDAS_INTERMEDIARIO
(
    ramo_prod,
    poliza,
    cod_intermediario
);


/* TOMADOR ÚNICO POR RAMO + PÓLIZA
   Fallback cuando no cruce por intermediario. */

;WITH TOMADOR_POLIZA AS
(
    SELECT
        t.*,
        ROW_NUMBER() OVER
        (
            PARTITION BY
                t.ramo_prod,
                t.poliza
            ORDER BY
                COALESCE(t.FECHA_ACTUALIZACION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC,
                COALESCE(t.FECHA_EJECUCION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC
        ) AS rn
    FROM #TOMADORES_CEDIDAS_NORMALIZADO t
)
SELECT
    ramo_prod,
    poliza,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_CEDIDAS_POLIZA
FROM TOMADOR_POLIZA
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_CEDIDAS_POLIZA
ON #TOMADORES_CEDIDAS_POLIZA
(
    ramo_prod,
    poliza
);


/*  FUENTE CEDIDAS FILTRADA Y NORMALIZADA */

SELECT
    IDENTITY(BIGINT, 1, 1) AS cedida_row_id,

    LTRIM(RTRIM(CAST(a.RAMO_PROD AS VARCHAR(20)))) AS ramo_prod,
    TRY_CONVERT(BIGINT, a.POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, a.CERTIFICADO) AS certificado,
    TRY_CONVERT(BIGINT, a.DOCUMENTO) AS documento,

    a.PERIODO_CONTABLE_ANALISIS AS periodo_contable_analisis,
    a.PERIODO_CONTABLE AS periodo_contable_origen,

    CAST(ISNULL(a.VALOR_RESERVA_CONTABLE, 0) AS DECIMAL(28,6))*-1 AS valor_base,

    CAST(ISNULL(NULLIF(LTRIM(RTRIM(a.MODALIDAD)), ''), 'NULL') AS VARCHAR(20)) AS modalidad,
    CAST('NULL' AS VARCHAR(50)) AS agrupador,
    CAST('NULL' AS VARCHAR(20)) AS tipo_riesgo,

    a.CUENTA,
    a.LIBRO
INTO #CEDIDAS_FUENTE
FROM Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ a
WHERE a.PERIODO_CONTABLE_ANALISIS BETWEEN @PERIODO_INI_CED AND @PERIODO_FIN_CED
  AND a.CUENTA IN ('510305','410305')
  AND a.LIBRO <> 'AG'
  AND a.RAMO_PROD IS NOT NULL
  AND a.POLIZA IS NOT NULL
  AND a.CERTIFICADO IS NOT NULL
  AND TRY_CONVERT(BIGINT, a.POLIZA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, a.CERTIFICADO) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_FUENTE_LLAVE
ON #CEDIDAS_FUENTE
(
    ramo_prod,
    poliza,
    certificado,
    documento
);

CREATE NONCLUSTERED INDEX IX_CEDIDAS_FUENTE_ROW_ID
ON #CEDIDAS_FUENTE
(
    cedida_row_id
);


/* POLIZA_INTERMEDIARIO IAXIS A NIVEL DETALLE */

SELECT DISTINCT
    LTRIM(RTRIM(CAST(inter.RAMO_PROD AS VARCHAR(20)))) AS ramo_prod,
    TRY_CONVERT(BIGINT, inter.POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, inter.CERTIFICADO) AS certificado,
    TRY_CONVERT(BIGINT, inter.INTERMEDIARIO_LIDE) AS intermediario_lide
INTO #POLIZA_INTERMEDIARIO_IAXIS_CEDIDAS
FROM Liberty.RESERVAS.POLIZA_INTERMEDIARIO inter
---INNER JOIN #CLAVES_ASOCIADAS_IAXIS g
---    ON g.intermediario_lide = TRY_CONVERT(BIGINT, inter.INTERMEDIARIO_LIDE)
WHERE inter.RAMO_PROD IS NOT NULL
  AND inter.POLIZA IS NOT NULL
  AND inter.CERTIFICADO IS NOT NULL
  AND inter.INTERMEDIARIO_LIDE IS NOT NULL
  AND TRY_CONVERT(BIGINT, inter.POLIZA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, inter.CERTIFICADO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, inter.INTERMEDIARIO_LIDE) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_POLIZA_INTERMEDIARIO_IAXIS_CEDIDAS
ON #POLIZA_INTERMEDIARIO_IAXIS_CEDIDAS
(
    ramo_prod,
    poliza,
    certificado,
    intermediario_lide
);


/*  BASE CORRETAJE IAXIS */

SELECT DISTINCT
    c.SSEGURO,
    LTRIM(RTRIM(CAST(c.RAMO_PROD AS VARCHAR(20)))) AS ramo_prod,
    TRY_CONVERT(BIGINT, c.POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, c.CERTIFICADO) AS certificado,
    TRY_CONVERT(BIGINT, c.DOCUMENTO_PRIMA) AS documento,
    TRY_CONVERT(BIGINT, c.AGENTE) AS agente,

    CAST(ISNULL(TRY_CONVERT(INT, c.ES_LIDER), 0) AS INT) AS es_lider,
    CAST(ISNULL(TRY_CONVERT(DECIMAL(18,6), c.PARTICIPACION), 0) AS DECIMAL(18,6)) AS participacion,

    CAST(
        CASE
            WHEN ISNULL(TRY_CONVERT(INT, c.ES_LIDER), 0) = 1
                 AND ISNULL(TRY_CONVERT(DECIMAL(18,6), c.PARTICIPACION), 0) < 0
                THEN ISNULL(TRY_CONVERT(DECIMAL(18,6), c.PARTICIPACION), 0) / 100.00

            WHEN ISNULL(TRY_CONVERT(INT, c.ES_LIDER), 0) = 1
                THEN (ISNULL(TRY_CONVERT(DECIMAL(18,6), c.PARTICIPACION), 0) - 100.00) / 100.00

            ELSE ISNULL(TRY_CONVERT(DECIMAL(18,6), c.PARTICIPACION), 0) / 100.00
        END
    AS DECIMAL(18,8)) AS factor_corretaje
INTO #CORRETAJE_BASE_CEDIDAS
FROM Liberty_Pruebas_Actuaria.dbo.polizas_corretaje_iaxis c
WHERE c.RAMO_PROD IS NOT NULL
  AND c.POLIZA IS NOT NULL
  AND c.CERTIFICADO IS NOT NULL
  AND c.DOCUMENTO_PRIMA IS NOT NULL
  AND c.AGENTE IS NOT NULL
  AND TRY_CONVERT(BIGINT, c.POLIZA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, c.CERTIFICADO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, c.DOCUMENTO_PRIMA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, c.AGENTE) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_BASE_CEDIDAS
ON #CORRETAJE_BASE_CEDIDAS
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente,
    es_lider
);


/* DOCUMENTOS APLICABLES A CO-CORRETAJE */

SELECT DISTINCT
    cb.ramo_prod,
    cb.poliza,
    cb.certificado,
    cb.documento,
    cb.agente AS agente_lider
INTO #CORRETAJE_LIDERES_CEDIDAS
FROM #CORRETAJE_BASE_CEDIDAS cb
WHERE cb.es_lider = 1;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_LIDERES_CEDIDAS
ON #CORRETAJE_LIDERES_CEDIDAS
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente_lider
);


SELECT
    cb.ramo_prod,
    cb.poliza,
    cb.certificado,
    cb.documento,
    COUNT(*) AS registros_corretaje,
    SUM(CASE WHEN cb.es_lider = 1 THEN 1 ELSE 0 END) AS registros_lider,
    SUM(CASE WHEN cb.es_lider <> 1 THEN 1 ELSE 0 END) AS registros_asociados,
    SUM(ISNULL(cb.factor_corretaje, 0)) AS suma_factor_corretaje
INTO #CORRETAJE_DOCS_RESUMEN_CEDIDAS
FROM #CORRETAJE_BASE_CEDIDAS cb
GROUP BY
    cb.ramo_prod,
    cb.poliza,
    cb.certificado,
    cb.documento;


SELECT
    r.ramo_prod,
    r.poliza,
    r.certificado,
    r.documento,
    l.agente_lider,
    r.registros_corretaje,
    r.registros_lider,
    r.registros_asociados,
    r.suma_factor_corretaje
INTO #CORRETAJE_DOCS_APLICABLES_CEDIDAS
FROM #CORRETAJE_DOCS_RESUMEN_CEDIDAS r
INNER JOIN #CORRETAJE_LIDERES_CEDIDAS l
    ON  l.ramo_prod = r.ramo_prod
    AND l.poliza = r.poliza
    AND l.certificado = r.certificado
    AND l.documento = r.documento
WHERE r.registros_lider > 0
  AND r.registros_asociados > 0;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_DOCS_APLICABLES_CEDIDAS
ON #CORRETAJE_DOCS_APLICABLES_CEDIDAS
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente_lider
);


/* CANDIDATOS DE INTERMEDIARIO POR CEDIDA */

SELECT
    a.cedida_row_id,
    a.ramo_prod,
    a.poliza,
    a.certificado,
    a.documento,
    a.periodo_contable_analisis,
    a.periodo_contable_origen,
    a.valor_base,
    a.modalidad,
    a.agrupador,
    a.tipo_riesgo,
    a.CUENTA,
    a.LIBRO,

    inter.intermediario_lide AS intermediario_inicial,

    CASE 
        WHEN ca.agente_lider IS NOT NULL THEN 1 
        ELSE 0 
    END AS tiene_match_corretaje_documento
INTO #CEDIDAS_INTERMEDIARIO_CANDIDATOS
FROM #CEDIDAS_FUENTE a
INNER JOIN #POLIZA_INTERMEDIARIO_IAXIS_CEDIDAS inter
    ON  inter.ramo_prod = a.ramo_prod
    AND inter.poliza = a.poliza
    AND inter.certificado = a.certificado
LEFT JOIN #CORRETAJE_DOCS_APLICABLES_CEDIDAS ca
    ON  ca.ramo_prod = a.ramo_prod
    AND ca.poliza = a.poliza
    AND ca.certificado = a.certificado
    AND ca.documento = a.documento
    AND ca.agente_lider = inter.intermediario_lide;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_INTERMEDIARIO_CANDIDATOS
ON #CEDIDAS_INTERMEDIARIO_CANDIDATOS
(
    cedida_row_id,
    ramo_prod,
    poliza,
    certificado,
    documento,
    intermediario_inicial
);


/* INTERMEDIARIO RESUELTO */

;WITH RESUMEN AS
(
    SELECT
        c.*,

        COUNT(*) OVER
        (
            PARTITION BY c.cedida_row_id
        ) AS candidatos_total,

        SUM(c.tiene_match_corretaje_documento) OVER
        (
            PARTITION BY c.cedida_row_id
        ) AS candidatos_con_match_documento,

        ROW_NUMBER() OVER
        (
            PARTITION BY c.cedida_row_id
            ORDER BY
                c.tiene_match_corretaje_documento DESC,
                c.intermediario_inicial ASC
        ) AS rn
    FROM #CEDIDAS_INTERMEDIARIO_CANDIDATOS c
)
SELECT
    cedida_row_id,
    ramo_prod,
    poliza,
    certificado,
    documento,
    periodo_contable_analisis,
    periodo_contable_origen,
    valor_base,
    modalidad,
    agrupador,
    tipo_riesgo,
    CUENTA,
    LIBRO,
    intermediario_inicial,

    CASE
        WHEN candidatos_con_match_documento = 1 THEN 'MATCH_CORRETAJE_DOCUMENTO'
        WHEN candidatos_con_match_documento > 1 THEN 'MULTIPLE_MATCH_CORRETAJE_DOCUMENTO'
        WHEN candidatos_total = 1 THEN 'UNICO_POLIZA_INTERMEDIARIO'
        ELSE 'MULTIPLE_POLIZA_INTERMEDIARIO_SIN_MATCH_DOCUMENTO'
    END AS regla_intermediario,

    CASE
        WHEN candidatos_con_match_documento > 1 THEN 1
        WHEN candidatos_con_match_documento = 0 AND candidatos_total > 1 THEN 1
        ELSE 0
    END AS requiere_revision
INTO #CEDIDAS_INTERMEDIARIO_RESUELTO
FROM RESUMEN
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_INTERMEDIARIO_RESUELTO
ON #CEDIDAS_INTERMEDIARIO_RESUELTO
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    intermediario_inicial
);


/*  BASE CEDIDAS CON TOMADOR */

SELECT
    r.cedida_row_id,
    r.ramo_prod,
    r.poliza,
    r.certificado,
    r.documento,
    r.periodo_contable_analisis,
    r.periodo_contable_origen,
    CAST(r.intermediario_inicial AS BIGINT) AS intermediario_inicial,
    r.valor_base,
    r.modalidad,
    r.agrupador,
    r.tipo_riesgo,
    CAST(
        COALESCE(
            ti.tipo_identifi_tomador,
            tp.tipo_identifi_tomador,
            'NULL'
        ) AS VARCHAR(10)  ) AS tipo_identifi_tomador,
    CAST(
        COALESCE(
            ti.Numero_identificacion_tomador,
            tp.Numero_identificacion_tomador,
            'NULL'
        ) AS VARCHAR(50) ) AS Numero_identificacion_tomador,
    r.regla_intermediario,
    r.requiere_revision,
    r.CUENTA,
    r.LIBRO
INTO #CEDIDAS_BASE
FROM #CEDIDAS_INTERMEDIARIO_RESUELTO r

LEFT JOIN #TOMADORES_CEDIDAS_INTERMEDIARIO ti
    ON  ti.ramo_prod = r.ramo_prod
    AND ti.poliza = r.poliza
    AND ti.cod_intermediario = r.intermediario_inicial

LEFT JOIN #TOMADORES_CEDIDAS_POLIZA tp
    ON  tp.ramo_prod = r.ramo_prod
    AND tp.poliza = r.poliza;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_BASE_LLAVE
ON #CEDIDAS_BASE
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    intermediario_inicial
);


/*  CEDIDAS QUE TIENEN CO-CORRETAJE */

SELECT
    d.*
INTO #CEDIDAS_CON_CORRETAJE
FROM #CEDIDAS_BASE d
INNER JOIN #CORRETAJE_DOCS_APLICABLES_CEDIDAS ca
    ON  ca.ramo_prod = d.ramo_prod
    AND ca.poliza = d.poliza
    AND ca.certificado = d.certificado
    AND ca.documento = d.documento
    AND ca.agente_lider = d.intermediario_inicial;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_CON_CORRETAJE
ON #CEDIDAS_CON_CORRETAJE
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    intermediario_inicial
);


/* BLOQUE ORIGINAL CEDIDA */

SELECT
    CAST('HDISC' AS VARCHAR(10)) AS compania,
    d.periodo_contable_analisis AS periodo_contable,
    d.intermediario_inicial,
    d.intermediario_inicial AS intermediario_final_asociado,
    d.ramo_prod,
    d.poliza,
    d.modalidad,
    d.agrupador,
    d.tipo_riesgo,
    d.tipo_identifi_tomador,
    d.Numero_identificacion_tomador,
    CAST(@MACRO_CEDIDA AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_CEDIDA AS VARCHAR(80)) AS concepto,
    CAST(SUM(d.valor_base) AS DECIMAL(28,6)) AS valor_concepto,
    CAST(@FUENTE_CEDIDA AS VARCHAR(150)) AS fuente_primaria,
    d.regla_intermediario,
    d.requiere_revision
INTO #CEDIDAS_GENERAL
FROM #CEDIDAS_BASE d
GROUP BY
    d.periodo_contable_analisis,
    d.intermediario_inicial,
    d.ramo_prod,
    d.poliza,
    d.modalidad,
    d.agrupador,
    d.tipo_riesgo,
    d.tipo_identifi_tomador,
    d.Numero_identificacion_tomador,
    d.regla_intermediario,
    d.requiere_revision;


/*  BLOQUE CO-CORRETAJE DETALLE */

SELECT
    CAST('HDISC' AS VARCHAR(10)) AS compania,
    d.periodo_contable_analisis AS periodo_contable,
    d.intermediario_inicial,
    cb.agente AS intermediario_final_asociado,
    d.ramo_prod,
    d.poliza,
    d.certificado,
    d.documento,
    d.modalidad,
    d.agrupador,
    d.tipo_riesgo,
    d.tipo_identifi_tomador,
    d.Numero_identificacion_tomador,
    cb.es_lider,
    cb.participacion,
    cb.factor_corretaje,
    d.valor_base,
    CAST(ROUND(d.valor_base * cb.factor_corretaje, 2) AS DECIMAL(28,6)) AS valor_concepto,
    CAST(@MACRO_COCORRETAJE_CED AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_COCORRETAJE_CED AS VARCHAR(100)) AS concepto,
    CAST(@FUENTE_CEDIDA AS VARCHAR(150)) AS fuente_primaria,
    d.regla_intermediario,
    d.requiere_revision
INTO #CEDIDAS_COCORRETAJE_DETALLE
FROM #CEDIDAS_CON_CORRETAJE d
INNER JOIN #CORRETAJE_BASE_CEDIDAS cb
    ON  cb.ramo_prod = d.ramo_prod
    AND cb.poliza = d.poliza
    AND cb.certificado = d.certificado
    AND cb.documento = d.documento
WHERE ISNULL(cb.factor_corretaje, 0) <> 0;


/* BLOQUE CO-CORRETAJE AGRUPADO */

SELECT
    dc.compania,
    dc.periodo_contable,
    dc.intermediario_inicial,
    dc.intermediario_final_asociado,
    dc.ramo_prod,
    dc.poliza,
    dc.modalidad,
    dc.agrupador,
    dc.tipo_riesgo,
    dc.tipo_identifi_tomador,
    dc.Numero_identificacion_tomador,
    dc.macro_concepto,
    dc.concepto,
    CAST(SUM(dc.valor_concepto) AS DECIMAL(28,6)) AS valor_concepto,
    dc.fuente_primaria,
    dc.regla_intermediario,
    dc.requiere_revision
INTO #CEDIDAS_COCORRETAJE
FROM #CEDIDAS_COCORRETAJE_DETALLE dc
GROUP BY
    dc.compania,
    dc.periodo_contable,
    dc.intermediario_inicial,
    dc.intermediario_final_asociado,
    dc.ramo_prod,
    dc.poliza,
    dc.modalidad,
    dc.agrupador,
    dc.tipo_riesgo,
    dc.tipo_identifi_tomador,
    dc.Numero_identificacion_tomador,
    dc.macro_concepto,
    dc.concepto,
    dc.fuente_primaria,
    dc.regla_intermediario,
    dc.requiere_revision;


/* FINAL LOCAL */

SELECT
    x.compania,
    x.periodo_contable,
    x.intermediario_inicial,
    x.intermediario_final_asociado,
    x.ramo_prod,
    x.poliza,
    x.modalidad,
    x.agrupador,
    x.tipo_riesgo,
    x.tipo_identifi_tomador,
    x.Numero_identificacion_tomador,
    x.macro_concepto,
    x.concepto,
    CAST(x.valor_concepto AS DECIMAL(28,6)) AS valor_concepto,
    x.fuente_primaria,
    x.regla_intermediario,
    x.requiere_revision
INTO #cedidas_reserva_final_devengada_tmp
FROM
(
    SELECT
        compania,
        periodo_contable,
        intermediario_inicial,
        intermediario_final_asociado,
        ramo_prod,
        poliza,
        modalidad,
        agrupador,
        tipo_riesgo,
        tipo_identifi_tomador,
        Numero_identificacion_tomador,
        macro_concepto,
        concepto,
        valor_concepto,
        fuente_primaria,
        regla_intermediario,
        requiere_revision
    FROM #CEDIDAS_GENERAL

    UNION ALL

    SELECT
        compania,
        periodo_contable,
        intermediario_inicial,
        intermediario_final_asociado,
        ramo_prod,
        poliza,
        modalidad,
        agrupador,
        tipo_riesgo,
        tipo_identifi_tomador,
        Numero_identificacion_tomador,
        macro_concepto,
        concepto,
        valor_concepto,
        fuente_primaria,
        regla_intermediario,
        requiere_revision
    FROM #CEDIDAS_COCORRETAJE
) x;


/*  FINAL GLOBAL */

SELECT
    compania,
    periodo_contable,
    intermediario_inicial,
    intermediario_final_asociado,
    ramo_prod,
    poliza,
    modalidad,
    agrupador,
    tipo_riesgo,
    tipo_identifi_tomador,
    Numero_identificacion_tomador,
    macro_concepto,
    concepto,
    valor_concepto,
    fuente_primaria,
    regla_intermediario,
    requiere_revision
INTO ##cedidas_reserva_final_devengada_tmp
FROM #cedidas_reserva_final_devengada_tmp;

CREATE NONCLUSTERED INDEX IX_global_cedidas_reserva_final_devengada_tmp
ON ##cedidas_reserva_final_devengada_tmp
(
    periodo_contable,
    ramo_prod,
    poliza,
    intermediario_inicial,
    intermediario_final_asociado,
    concepto
);


DROP TABLE liberty_pruebas_actuaria.dbo.cedidas_reserva_general
select * 
into liberty_pruebas_actuaria.dbo.cedidas_reserva_general
from ##cedidas_reserva_final_devengada_tmp






--------------------long 

select periodo_contable, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_general group by periodo_contable order by periodo_contable
select periodo_contable, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_final_devengada_tmp_n group by periodo_contable order by periodo_contable



select periodo_contable,ramo_prod, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_final_devengada_tmp where periodo_contable = 202603 group by periodo_contable,ramo_prod order by periodo_contable
select periodo_contable,ramo_prod, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_final_devengada_tmp_n where periodo_contable = 202603 group by periodo_contable,ramo_prod order by periodo_contable


select poliza, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_final_devengada_tmp where periodo_contable = 202603 and ramo_prod = 'LGP' AND POLIZA = 8659 group by poliza ORDER BY POLIZA
select poliza, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_final_devengada_tmp_n where periodo_contable = 202603 and ramo_prod = 'LGP'  AND POLIZA = 8659 group by poliza ORDER BY POLIZA



SELECT
    c.name AS nombre_campo,
    t.name AS tipo_dato,
    c.max_length AS max_length_bytes,
    CASE
        WHEN t.name IN ('nvarchar', 'nchar') AND c.max_length > 0 THEN c.max_length / 2
        WHEN c.max_length = -1 THEN -1
        ELSE c.max_length
    END AS longitud_definida,
    c.precision,
    c.scale,
    c.is_nullable
FROM tempdb.sys.columns c
INNER JOIN tempdb.sys.types t
    ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('tempdb..##cedidas_reserva_final_devengada_tmp')
ORDER BY
    c.column_id;




---------------------validación


SELECT
    periodo_contable,
    concepto,
    COUNT(*) AS registros,
    SUM(valor_concepto) AS total_valor,
    SUM(CASE WHEN Numero_identificacion_tomador = 'NULL' THEN 1 ELSE 0 END) AS registros_sin_tomador,
    SUM(CASE WHEN requiere_revision = 1 THEN 1 ELSE 0 END) AS registros_requieren_revision
FROM ##cedidas_reserva_final_devengada_tmp
GROUP BY
    periodo_contable,
    concepto
ORDER BY
    periodo_contable,
    concepto;


 