/* Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS
   ##cedidas_reserva_iaxis_final_devengada_tmp */

SET NOCOUNT ON;


/*LIMPIEZA */

IF OBJECT_ID('tempdb..#CLAVES_ASOCIADAS_IAXIS') IS NOT NULL DROP TABLE #CLAVES_ASOCIADAS_IAXIS;

IF OBJECT_ID('tempdb..#TOMADORES_IAXIS_NORMALIZADO') IS NOT NULL DROP TABLE #TOMADORES_IAXIS_NORMALIZADO;
IF OBJECT_ID('tempdb..#TOMADORES_IAXIS_INTERMEDIARIO') IS NOT NULL DROP TABLE #TOMADORES_IAXIS_INTERMEDIARIO;
IF OBJECT_ID('tempdb..#TOMADORES_IAXIS_POLIZA') IS NOT NULL DROP TABLE #TOMADORES_IAXIS_POLIZA;

IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_FUENTE') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_FUENTE;
IF OBJECT_ID('tempdb..#POLIZA_INTERMEDIARIO_IAXIS_CERT') IS NOT NULL DROP TABLE #POLIZA_INTERMEDIARIO_IAXIS_CERT;

IF OBJECT_ID('tempdb..#DWH_RECIBO_DOCUMENTO_IAXIS') IS NOT NULL DROP TABLE #DWH_RECIBO_DOCUMENTO_IAXIS;

IF OBJECT_ID('tempdb..#CORRETAJE_BASE_IAXIS') IS NOT NULL DROP TABLE #CORRETAJE_BASE_IAXIS;
IF OBJECT_ID('tempdb..#CORRETAJE_LIDERES_IAXIS') IS NOT NULL DROP TABLE #CORRETAJE_LIDERES_IAXIS;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_RESUMEN_IAXIS') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_RESUMEN_IAXIS;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_APLICABLES_IAXIS') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_APLICABLES_IAXIS;

IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_INTERMEDIARIO_CANDIDATOS') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_INTERMEDIARIO_CANDIDATOS;
IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_INTERMEDIARIO_RESUELTO') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_INTERMEDIARIO_RESUELTO;

IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_BASE') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_BASE;
IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_CON_CORRETAJE') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_CON_CORRETAJE;

IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_GENERAL') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_GENERAL;
IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_COCORRETAJE_DETALLE') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_COCORRETAJE_DETALLE;
IF OBJECT_ID('tempdb..#CEDIDAS_IAXIS_COCORRETAJE') IS NOT NULL DROP TABLE #CEDIDAS_IAXIS_COCORRETAJE;

IF OBJECT_ID('tempdb..#cedidas_reserva_iaxis_final_devengada_tmp') IS NOT NULL DROP TABLE #cedidas_reserva_iaxis_final_devengada_tmp;
IF OBJECT_ID('tempdb..##cedidas_reserva_iaxis_final_devengada_tmp') IS NOT NULL DROP TABLE ##cedidas_reserva_iaxis_final_devengada_tmp;


/* VARIABLES */

DECLARE @PERIODO_INI_CED_IAXIS INT = 202601;
DECLARE @PERIODO_FIN_CED_IAXIS INT = 202605;

DECLARE @MACRO_CEDIDA_IAXIS VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_CEDIDA_IAXIS VARCHAR(80) = 'Devengada_Cedida_IAXIS';

DECLARE @MACRO_COCORRETAJE_IAXIS VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_COCORRETAJE_IAXIS VARCHAR(100) = 'Devengada_Cedida_IAXIS_CO-Corretaje';

DECLARE @FUENTE_CEDIDA_IAXIS VARCHAR(150) = 'Liberty.[RESERVAS].[CEDIDAS_RESERVA_INTERFAZ_IAXIS]';


/* CLAVES IAXIS */
/*
SELECT DISTINCT
    TRY_CONVERT(BIGINT, g.CLAVE_INICIAL_ASOCIADA) AS intermediario_lide
INTO #CLAVES_ASOCIADAS_IAXIS
FROM Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g
WHERE g.cia = 'IAXIS'
  AND g.CLAVE_INICIAL_ASOCIADA IS NOT NULL
  AND TRY_CONVERT(BIGINT, g.CLAVE_INICIAL_ASOCIADA) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CLAVES_ASOCIADAS_IAXIS
ON #CLAVES_ASOCIADAS_IAXIS(intermediario_lide);
*/

/* TOMADORES NORMALIZADOS */

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
INTO #TOMADORES_IAXIS_NORMALIZADO
FROM Liberty.APOYO.DWH_TOMADORES t
WHERE t.COD_RAMO_PROD IS NOT NULL
  AND t.NRO_POLIZA IS NOT NULL
  AND TRY_CONVERT(BIGINT, t.NRO_POLIZA) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_TOMADORES_IAXIS_NORMALIZADO
ON #TOMADORES_IAXIS_NORMALIZADO
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
    FROM #TOMADORES_IAXIS_NORMALIZADO t
    WHERE t.cod_intermediario IS NOT NULL
)
SELECT
    ramo_prod,
    poliza,
    cod_intermediario,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_IAXIS_INTERMEDIARIO
FROM TOMADOR_INTERMEDIARIO
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_IAXIS_INTERMEDIARIO
ON #TOMADORES_IAXIS_INTERMEDIARIO
(
    ramo_prod,
    poliza,
    cod_intermediario
);


/* TOMADOR ÚNICO POR RAMO + PÓLIZA */

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
    FROM #TOMADORES_IAXIS_NORMALIZADO t
)
SELECT
    ramo_prod,
    poliza,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_IAXIS_POLIZA
FROM TOMADOR_POLIZA
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_IAXIS_POLIZA
ON #TOMADORES_IAXIS_POLIZA
(
    ramo_prod,
    poliza
);


/*FUENTE PRINCIPAL FILTRADA */

SELECT
    IDENTITY(BIGINT, 1, 1) AS cedida_iaxis_row_id,
    LTRIM(RTRIM(CAST(a.RAMO_PROD AS VARCHAR(20)))) AS ramo_prod,
    TRY_CONVERT(BIGINT, a.POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, a.CERTIFICADO) AS certificado,
    TRY_CONVERT(BIGINT, a.DOCUMENTO) AS recibo_fuente,
    a.PERIODO_CONTABLE_ANALISIS AS periodo_contable_analisis,
    a.PERIODO_CONTABLE AS periodo_contable_origen,
    CAST(ISNULL(a.VALOR_RESERVA_CONTABLE, 0) AS DECIMAL(28,6)) *-1 AS valor_base,
    CAST(ISNULL(NULLIF(LTRIM(RTRIM(a.MODALIDAD)), ''), 'NULL') AS VARCHAR(20)) AS modalidad,
    CAST('NULL' AS VARCHAR(50)) AS agrupador,
    CAST('NULL' AS VARCHAR(20)) AS tipo_riesgo,
    a.CUENTA,
    a.LIBRO
INTO #CEDIDAS_IAXIS_FUENTE
FROM Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS a
WHERE a.PERIODO_CONTABLE_ANALISIS BETWEEN @PERIODO_INI_CED_IAXIS AND @PERIODO_FIN_CED_IAXIS
  AND a.CUENTA IN ('510305','410305')
  AND a.LIBRO <> 'AG'
  AND a.RAMO_PROD IS NOT NULL
  AND a.POLIZA IS NOT NULL
  AND a.CERTIFICADO IS NOT NULL
  AND a.DOCUMENTO IS NOT NULL
  AND TRY_CONVERT(BIGINT, a.POLIZA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, a.CERTIFICADO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, a.DOCUMENTO) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_IAXIS_FUENTE_ROW
ON #CEDIDAS_IAXIS_FUENTE(cedida_iaxis_row_id);

CREATE NONCLUSTERED INDEX IX_CEDIDAS_IAXIS_FUENTE_LLAVE
ON #CEDIDAS_IAXIS_FUENTE
(
    ramo_prod,
    poliza,
    certificado,
    recibo_fuente
);


/*POLIZA_INTERMEDIARIO IAXIS POR RAMO + PÓLIZA + CERTIFICADO*/

SELECT DISTINCT
    LTRIM(RTRIM(CAST(inter.RAMO_PROD AS VARCHAR(20)))) AS ramo_prod,
    TRY_CONVERT(BIGINT, inter.POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, inter.CERTIFICADO) AS certificado,
    TRY_CONVERT(BIGINT, inter.INTERMEDIARIO_LIDE) AS intermediario_lide
INTO #POLIZA_INTERMEDIARIO_IAXIS_CERT
FROM Liberty.RESERVAS.POLIZA_INTERMEDIARIO inter
--INNER JOIN #CLAVES_ASOCIADAS_IAXIS g
--    ON g.intermediario_lide = TRY_CONVERT(BIGINT, inter.INTERMEDIARIO_LIDE)
WHERE inter.RAMO_PROD IS NOT NULL
  AND inter.POLIZA IS NOT NULL
  AND inter.CERTIFICADO IS NOT NULL
  AND inter.INTERMEDIARIO_LIDE IS NOT NULL
  AND TRY_CONVERT(BIGINT, inter.POLIZA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, inter.CERTIFICADO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, inter.INTERMEDIARIO_LIDE) IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_POLIZA_INTERMEDIARIO_IAXIS_CERT
ON #POLIZA_INTERMEDIARIO_IAXIS_CERT
(
    ramo_prod,
    poliza,
    certificado,
    intermediario_lide
);


/* POLIZAS_H RESUMIDA */

SELECT
    LTRIM(RTRIM(CAST(dwh.RAMO_PROD AS VARCHAR(20)))) AS ramo_prod,
    TRY_CONVERT(BIGINT, dwh.POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, dwh.CERTIFICADO) AS certificado,
    TRY_CONVERT(BIGINT, dwh.RECIBO) AS recibo,

    MAX(TRY_CONVERT(BIGINT, dwh.DOCUMENTO)) AS documento_resuelto,

    COUNT(*) AS registros_dwh,
    COUNT(DISTINCT TRY_CONVERT(BIGINT, dwh.DOCUMENTO)) AS documentos_distintos
INTO #DWH_RECIBO_DOCUMENTO_IAXIS
FROM liberty.prod.dwh_polizas_h dwh
WHERE dwh.RAMO_PROD IS NOT NULL
  AND dwh.POLIZA IS NOT NULL
  AND dwh.CERTIFICADO IS NOT NULL
  AND dwh.RECIBO IS NOT NULL
  AND dwh.DOCUMENTO IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.POLIZA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.CERTIFICADO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.RECIBO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.DOCUMENTO) IS NOT NULL
GROUP BY
    LTRIM(RTRIM(CAST(dwh.RAMO_PROD AS VARCHAR(20)))),
    TRY_CONVERT(BIGINT, dwh.POLIZA),
    TRY_CONVERT(BIGINT, dwh.CERTIFICADO),
    TRY_CONVERT(BIGINT, dwh.RECIBO);

CREATE NONCLUSTERED INDEX IX_DWH_RECIBO_DOCUMENTO_IAXIS
ON #DWH_RECIBO_DOCUMENTO_IAXIS
(
    ramo_prod,
    poliza,
    certificado,
    recibo,
    documento_resuelto
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
INTO #CORRETAJE_BASE_IAXIS
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

CREATE NONCLUSTERED INDEX IX_CORRETAJE_BASE_IAXIS
ON #CORRETAJE_BASE_IAXIS
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente,
    es_lider
);


/*  DOCUMENTOS APLICABLES A CO-CORRETAJE */

SELECT DISTINCT
    cb.ramo_prod,
    cb.poliza,
    cb.certificado,
    cb.documento,
    cb.agente AS agente_lider
INTO #CORRETAJE_LIDERES_IAXIS
FROM #CORRETAJE_BASE_IAXIS cb
WHERE cb.es_lider = 1;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_LIDERES_IAXIS
ON #CORRETAJE_LIDERES_IAXIS
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
INTO #CORRETAJE_DOCS_RESUMEN_IAXIS
FROM #CORRETAJE_BASE_IAXIS cb
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
INTO #CORRETAJE_DOCS_APLICABLES_IAXIS
FROM #CORRETAJE_DOCS_RESUMEN_IAXIS r
INNER JOIN #CORRETAJE_LIDERES_IAXIS l
    ON  l.ramo_prod = r.ramo_prod
    AND l.poliza = r.poliza
    AND l.certificado = r.certificado
    AND l.documento = r.documento
WHERE r.registros_lider > 0
  AND r.registros_asociados > 0;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_DOCS_APLICABLES_IAXIS
ON #CORRETAJE_DOCS_APLICABLES_IAXIS
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente_lider
);


/*  CANDIDATOS DE INTERMEDIARIO */

SELECT
    f.cedida_iaxis_row_id,
    f.ramo_prod,
    f.poliza,
    f.certificado,
    f.recibo_fuente,
    dwh.documento_resuelto,
    dwh.documentos_distintos,
    f.periodo_contable_analisis,
    f.periodo_contable_origen,
    f.valor_base,
    f.modalidad,
    f.agrupador,
    f.tipo_riesgo,
    f.CUENTA,
    f.LIBRO,
    inter.intermediario_lide AS intermediario_inicial,
    CASE
        WHEN ca.agente_lider IS NOT NULL THEN 1
        ELSE 0
    END AS tiene_match_corretaje_documento
INTO #CEDIDAS_IAXIS_INTERMEDIARIO_CANDIDATOS
FROM #CEDIDAS_IAXIS_FUENTE f
INNER JOIN #POLIZA_INTERMEDIARIO_IAXIS_CERT inter
    ON  inter.ramo_prod = f.ramo_prod
    AND inter.poliza = f.poliza
    AND inter.certificado = f.certificado

LEFT JOIN #DWH_RECIBO_DOCUMENTO_IAXIS dwh
    ON  dwh.ramo_prod = f.ramo_prod
    AND dwh.poliza = f.poliza
    AND dwh.certificado = f.certificado
    AND dwh.recibo = f.recibo_fuente

LEFT JOIN #CORRETAJE_DOCS_APLICABLES_IAXIS ca
    ON  ca.ramo_prod = f.ramo_prod
    AND ca.poliza = f.poliza
    AND ca.certificado = f.certificado
    AND ca.documento = dwh.documento_resuelto
    AND ca.agente_lider = inter.intermediario_lide;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_IAXIS_INTERMEDIARIO_CANDIDATOS
ON #CEDIDAS_IAXIS_INTERMEDIARIO_CANDIDATOS
(
    cedida_iaxis_row_id,
    ramo_prod,
    poliza,
    certificado,
    documento_resuelto,
    intermediario_inicial
);


/* INTERMEDIARIO RESUELTO */

;WITH RESUMEN AS
(
    SELECT
        c.*,

        COUNT(*) OVER
        (
            PARTITION BY c.cedida_iaxis_row_id
        ) AS intermediarios_candidatos_total,

        SUM(c.tiene_match_corretaje_documento) OVER
        (
            PARTITION BY c.cedida_iaxis_row_id
        ) AS intermediarios_con_match_corretaje,

        ROW_NUMBER() OVER
        (
            PARTITION BY c.cedida_iaxis_row_id
            ORDER BY
                c.tiene_match_corretaje_documento DESC,
                c.intermediario_inicial ASC
        ) AS rn
    FROM #CEDIDAS_IAXIS_INTERMEDIARIO_CANDIDATOS c
)
SELECT
    cedida_iaxis_row_id,
    ramo_prod,
    poliza,
    certificado,
    recibo_fuente,
    documento_resuelto,

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
        WHEN documento_resuelto IS NULL THEN 'SIN_DOCUMENTO_RESUELTO_POLIZAS_H'
        WHEN ISNULL(documentos_distintos, 0) > 1 THEN 'DOCUMENTO_MAX_POLIZAS_H_MULTIPLE'
        ELSE 'DOCUMENTO_MAX_POLIZAS_H_UNICO'
    END AS regla_documento,

    CASE
        WHEN documento_resuelto IS NULL THEN 1
        WHEN ISNULL(documentos_distintos, 0) > 1 THEN 1
        ELSE 0
    END AS requiere_revision_documento,

    CASE
        WHEN intermediarios_con_match_corretaje = 1 THEN 'MATCH_CORRETAJE_DOCUMENTO'
        WHEN intermediarios_con_match_corretaje > 1 THEN 'MULTIPLE_MATCH_CORRETAJE_DOCUMENTO'
        WHEN intermediarios_candidatos_total = 1 THEN 'UNICO_POLIZA_INTERMEDIARIO_CERTIFICADO'
        ELSE 'MULTIPLE_POLIZA_INTERMEDIARIO_CERTIFICADO'
    END AS regla_intermediario,

    CASE
        WHEN intermediarios_con_match_corretaje > 1 THEN 1
        WHEN intermediarios_con_match_corretaje = 0 AND intermediarios_candidatos_total > 1 THEN 1
        ELSE 0
    END AS requiere_revision_intermediario,

    CASE
        WHEN documento_resuelto IS NULL THEN 1
        WHEN ISNULL(documentos_distintos, 0) > 1 THEN 1
        WHEN intermediarios_con_match_corretaje > 1 THEN 1
        WHEN intermediarios_con_match_corretaje = 0 AND intermediarios_candidatos_total > 1 THEN 1
        ELSE 0
    END AS requiere_revision
INTO #CEDIDAS_IAXIS_INTERMEDIARIO_RESUELTO
FROM RESUMEN
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_IAXIS_INTERMEDIARIO_RESUELTO
ON #CEDIDAS_IAXIS_INTERMEDIARIO_RESUELTO
(
    ramo_prod,
    poliza,
    certificado,
    documento_resuelto,
    intermediario_inicial
);


/* BASE FINAL CON TOMADOR */

SELECT
    r.cedida_iaxis_row_id,
    r.ramo_prod,
    r.poliza,
    r.certificado,
    r.recibo_fuente,
    r.documento_resuelto,
    r.periodo_contable_analisis,
    r.periodo_contable_origen,
    r.intermediario_inicial,
    r.valor_base,
    r.modalidad,
    r.agrupador,
    r.tipo_riesgo,

    CAST(
        COALESCE(
            ti.tipo_identifi_tomador,
            tp.tipo_identifi_tomador,
            'NULL'
        ) AS VARCHAR(10)
    ) AS tipo_identifi_tomador,

    CAST(
        COALESCE(
            ti.Numero_identificacion_tomador,
            tp.Numero_identificacion_tomador,
            'NULL'
        ) AS VARCHAR(50)
    ) AS Numero_identificacion_tomador,

    r.regla_documento,
    r.requiere_revision_documento,
    r.regla_intermediario,
    r.requiere_revision_intermediario,
    r.requiere_revision,

    r.CUENTA,
    r.LIBRO
INTO #CEDIDAS_IAXIS_BASE
FROM #CEDIDAS_IAXIS_INTERMEDIARIO_RESUELTO r

LEFT JOIN #TOMADORES_IAXIS_INTERMEDIARIO ti
    ON  ti.ramo_prod = r.ramo_prod
    AND ti.poliza = r.poliza
    AND ti.cod_intermediario = r.intermediario_inicial

LEFT JOIN #TOMADORES_IAXIS_POLIZA tp
    ON  tp.ramo_prod = r.ramo_prod
    AND tp.poliza = r.poliza;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_IAXIS_BASE
ON #CEDIDAS_IAXIS_BASE
(
    ramo_prod,
    poliza,
    certificado,
    documento_resuelto,
    intermediario_inicial
);


/* BASE QUE SÍ TIENE CO-CORRETAJE */

SELECT
    d.*
INTO #CEDIDAS_IAXIS_CON_CORRETAJE
FROM #CEDIDAS_IAXIS_BASE d
INNER JOIN #CORRETAJE_DOCS_APLICABLES_IAXIS ca
    ON  ca.ramo_prod = d.ramo_prod
    AND ca.poliza = d.poliza
    AND ca.certificado = d.certificado
    AND ca.documento = d.documento_resuelto
    AND ca.agente_lider = d.intermediario_inicial;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_IAXIS_CON_CORRETAJE
ON #CEDIDAS_IAXIS_CON_CORRETAJE
(
    ramo_prod,
    poliza,
    certificado,
    documento_resuelto,
    intermediario_inicial
);


/*  DEVENGADA CEDIDA IAXIS */

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
    CAST(@MACRO_CEDIDA_IAXIS AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_CEDIDA_IAXIS AS VARCHAR(80)) AS concepto,
    CAST(SUM(d.valor_base) AS DECIMAL(28,6)) AS valor_concepto,
    CAST(@FUENTE_CEDIDA_IAXIS AS VARCHAR(150)) AS fuente_primaria,
    d.regla_documento,
    d.regla_intermediario,
    d.requiere_revision_documento,
    d.requiere_revision_intermediario,
    d.requiere_revision
INTO #CEDIDAS_IAXIS_GENERAL
FROM #CEDIDAS_IAXIS_BASE d
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
    d.regla_documento,
    d.regla_intermediario,
    d.requiere_revision_documento,
    d.requiere_revision_intermediario,
    d.requiere_revision;


/*  CO-CORRETAJE DETALLE */

SELECT
    CAST('HDISC' AS VARCHAR(10)) AS compania,
    d.periodo_contable_analisis AS periodo_contable,
    d.intermediario_inicial,
    cb.agente AS intermediario_final_asociado,
    d.ramo_prod,
    d.poliza,
    d.certificado,
    d.recibo_fuente,
    d.documento_resuelto,
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
    CAST(@MACRO_COCORRETAJE_IAXIS AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_COCORRETAJE_IAXIS AS VARCHAR(100)) AS concepto,
    CAST(@FUENTE_CEDIDA_IAXIS AS VARCHAR(150)) AS fuente_primaria,
    d.regla_documento,
    d.regla_intermediario,
    d.requiere_revision_documento,
    d.requiere_revision_intermediario,
    d.requiere_revision
INTO #CEDIDAS_IAXIS_COCORRETAJE_DETALLE
FROM #CEDIDAS_IAXIS_CON_CORRETAJE d
INNER JOIN #CORRETAJE_BASE_IAXIS cb
    ON  cb.ramo_prod = d.ramo_prod
    AND cb.poliza = d.poliza
    AND cb.certificado = d.certificado
    AND cb.documento = d.documento_resuelto
WHERE ISNULL(cb.factor_corretaje, 0) <> 0;


/* CO-CORRETAJE AGRUPADO */

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
    dc.regla_documento,
    dc.regla_intermediario,
    dc.requiere_revision_documento,
    dc.requiere_revision_intermediario,
    dc.requiere_revision
INTO #CEDIDAS_IAXIS_COCORRETAJE
FROM #CEDIDAS_IAXIS_COCORRETAJE_DETALLE dc
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
    dc.regla_documento,
    dc.regla_intermediario,
    dc.requiere_revision_documento,
    dc.requiere_revision_intermediario,
    dc.requiere_revision;

/*  FINAL LOCAL */

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
    x.regla_documento,
    x.regla_intermediario,
    x.requiere_revision_documento,
    x.requiere_revision_intermediario,
    x.requiere_revision
INTO #cedidas_reserva_iaxis_final_devengada_tmp
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
        regla_documento,
        regla_intermediario,
        requiere_revision_documento,
        requiere_revision_intermediario,
        requiere_revision
    FROM #CEDIDAS_IAXIS_GENERAL

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
        regla_documento,
        regla_intermediario,
        requiere_revision_documento,
        requiere_revision_intermediario,
        requiere_revision
    FROM #CEDIDAS_IAXIS_COCORRETAJE
) x;


/* FINAL GLOBAL */

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
    regla_documento,
    regla_intermediario,
    requiere_revision_documento,
    requiere_revision_intermediario,
    requiere_revision
INTO ##cedidas_reserva_iaxis_final_devengada_tmp
FROM #cedidas_reserva_iaxis_final_devengada_tmp;

CREATE NONCLUSTERED INDEX IX_global_cedidas_reserva_iaxis_final_devengada_tmp
ON ##cedidas_reserva_iaxis_final_devengada_tmp
(
    periodo_contable,
    ramo_prod,
    poliza,
    intermediario_inicial,
    intermediario_final_asociado,
    concepto
);
 

 drop table liberty_pruebas_actuaria.dbo.cedidas_reserva_general_iaxis
 SELECT * 
 INTO liberty_pruebas_actuaria.dbo.cedidas_reserva_general_iaxis
 FROM ##cedidas_reserva_iaxis_final_devengada_tmp


------------------------long c



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
WHERE c.object_id = OBJECT_ID('tempdb..##cedidas_reserva_iaxis_final_devengada_tmp')
ORDER BY
    c.column_id;



-------VALIDACIÓN ----------------------------------------------------


select periodo_contable , sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_general_iaxis group by periodo_contable order by periodo_contable 
select periodo_contable , sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp group by periodo_contable order by periodo_contable 

select periodo_contable ,ramo_prod, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp_N where periodo_contable = 202602  group by periodo_contable, ramo_prod order by periodo_contable 
select periodo_contable ,ramo_prod, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp  where periodo_contable = 202602 group by periodo_contable, ramo_prod order by periodo_contable 

select periodo_contable ,poliza, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp_N where periodo_contable = 202602 and ramo_prod = '10024' group by periodo_contable, poliza order by periodo_contable 
select periodo_contable ,poliza, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp  where periodo_contable = 202602 and ramo_prod = '10024' group by periodo_contable, poliza order by periodo_contable 



SELECT
    periodo_contable,
    concepto,
    COUNT(*) AS registros,
    SUM(valor_concepto) AS total_valor,
    SUM(CASE WHEN Numero_identificacion_tomador = 'NULL' THEN 1 ELSE 0 END) AS registros_sin_tomador,
    SUM(CASE WHEN requiere_revision = 1 THEN 1 ELSE 0 END) AS registros_requieren_revision
FROM ##cedidas_reserva_iaxis_final_devengada_tmp
GROUP BY
    periodo_contable,
    concepto
ORDER BY
    periodo_contable,
    concepto;
    
   
   ----VALIDACION TABLKAS ORIGINALES 
  

DECLARE @PERIODO_INI INT = 202601;
DECLARE @PERIODO_FIN INT = 202603;

IF OBJECT_ID('tempdb..#cedidas_iaxis_base_val') IS NOT NULL
    DROP TABLE #cedidas_iaxis_base_val;

IF OBJECT_ID('tempdb..#dwh_polizas_h_val') IS NOT NULL
    DROP TABLE #dwh_polizas_h_val;


/*BASE ORIGINAL Fuente + POLIZA_INTERMEDIARIO por ramo + póliza + certificado */

SELECT
    a.*,
    inter.INTERMEDIARIO_LIDE
INTO #cedidas_iaxis_base_val
FROM Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS a
LEFT JOIN Liberty.RESERVAS.POLIZA_INTERMEDIARIO inter
    ON  inter.ramo_prod = a.ramo_prod
    AND inter.poliza = a.poliza
    AND inter.certificado = a.certificado
WHERE a.PERIODO_CONTABLE_ANALISIS BETWEEN @PERIODO_INI AND @PERIODO_FIN;


/* VALIDADORA BASE SIN POLIZAS_H */

SELECT
    a.PERIODO_CONTABLE_ANALISIS,
    COUNT(*) AS registros,
    SUM(a.valor_reserva_contable) AS valor_base_sin_polizas_h
FROM #cedidas_iaxis_base_val a
INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g
    ON g.CLAVE_INICIAL_ASOCIADA = a.INTERMEDIARIO_LIDE
   AND g.cia = 'IAXIS'
WHERE a.cuenta IN ('510305','410305')
  AND a.libro <> 'AG'
GROUP BY
    a.PERIODO_CONTABLE_ANALISIS
ORDER BY
    a.PERIODO_CONTABLE_ANALISIS;


/*POLIZAS_H RESUMIDA PARA VALIDAR DOCUMENTO REAL
   Una fila por ramo + póliza + certificado + recibo. */

SELECT
    LTRIM(RTRIM(CAST(dwh.RAMO_PROD AS VARCHAR(20)))) AS ramo_prod,
    TRY_CONVERT(BIGINT, dwh.POLIZA) AS poliza,
    TRY_CONVERT(BIGINT, dwh.CERTIFICADO) AS certificado,
    TRY_CONVERT(BIGINT, dwh.RECIBO) AS recibo,

    MAX(TRY_CONVERT(BIGINT, dwh.DOCUMENTO)) AS documento_resuelto,

    COUNT(*) AS registros_dwh,
    COUNT(DISTINCT TRY_CONVERT(BIGINT, dwh.DOCUMENTO)) AS documentos_distintos
INTO #dwh_polizas_h_val
FROM liberty.prod.dwh_polizas_h dwh
WHERE dwh.RAMO_PROD IS NOT NULL
  AND dwh.POLIZA IS NOT NULL
  AND dwh.CERTIFICADO IS NOT NULL
  AND dwh.RECIBO IS NOT NULL
  AND dwh.DOCUMENTO IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.POLIZA) IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.CERTIFICADO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.RECIBO) IS NOT NULL
  AND TRY_CONVERT(BIGINT, dwh.DOCUMENTO) IS NOT NULL
GROUP BY
    LTRIM(RTRIM(CAST(dwh.RAMO_PROD AS VARCHAR(20)))),
    TRY_CONVERT(BIGINT, dwh.POLIZA),
    TRY_CONVERT(BIGINT, dwh.CERTIFICADO),
    TRY_CONVERT(BIGINT, dwh.RECIBO);


/*  VALIDADORA DE BASE VS POLIZAS_H*/

SELECT
    a.PERIODO_CONTABLE_ANALISIS,

    COUNT(*) AS registros_base,
    SUM(a.valor_reserva_contable) AS valor_base,
    SUM(CASE 
            WHEN dwh.documento_resuelto IS NOT NULL 
            THEN 1 ELSE 0 
        END) AS registros_con_polizas_h,
    SUM(CASE 
            WHEN dwh.documento_resuelto IS NOT NULL 
            THEN a.valor_reserva_contable ELSE 0 
        END) AS valor_con_polizas_h,
    SUM(CASE 
            WHEN dwh.documento_resuelto IS NULL 
            THEN 1 ELSE 0 
        END) AS registros_sin_polizas_h,
    SUM(CASE 
            WHEN dwh.documento_resuelto IS NULL 
            THEN a.valor_reserva_contable ELSE 0 
        END) AS valor_sin_polizas_h,
    SUM(CASE 
            WHEN dwh.documentos_distintos > 1 
            THEN 1 ELSE 0 
        END) AS registros_con_multiples_documentos_polizas_h
FROM #cedidas_iaxis_base_val a
INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g
    ON g.CLAVE_INICIAL_ASOCIADA = a.INTERMEDIARIO_LIDE
   AND g.cia = 'IAXIS'

LEFT JOIN #dwh_polizas_h_val dwh
    ON  dwh.ramo_prod = LTRIM(RTRIM(CAST(a.RAMO_PROD AS VARCHAR(20))))
    AND dwh.poliza = TRY_CONVERT(BIGINT, a.POLIZA)
    AND dwh.certificado = TRY_CONVERT(BIGINT, a.CERTIFICADO)
    AND dwh.recibo = TRY_CONVERT(BIGINT, a.DOCUMENTO)

WHERE a.cuenta IN ('510305','410305')
  AND a.libro <> 'AG'
GROUP BY
    a.PERIODO_CONTABLE_ANALISIS
ORDER BY
    a.PERIODO_CONTABLE_ANALISIS;


/* COMPARATIVO CONTRA TABLA FINAL */

WITH validadora_base AS
(
    SELECT
        a.PERIODO_CONTABLE_ANALISIS AS periodo_contable,
        SUM(a.valor_reserva_contable) AS valor_base_sin_polizas_h
    FROM #cedidas_iaxis_base_val a
    INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g
        ON g.CLAVE_INICIAL_ASOCIADA = a.INTERMEDIARIO_LIDE
       AND g.cia = 'IAXIS'
    WHERE a.cuenta IN ('510305','410305')
      AND a.libro <> 'AG'
    GROUP BY
        a.PERIODO_CONTABLE_ANALISIS
),
tabla_final AS
(
    SELECT
        periodo_contable,
        SUM(valor_concepto) AS valor_tabla_final
    FROM ##cedidas_reserva_iaxis_final_devengada_tmp
    WHERE concepto = 'Devengada_Cedida_IAXIS'
    GROUP BY
        periodo_contable
)
SELECT
    COALESCE(v.periodo_contable, t.periodo_contable) AS periodo_contable,
    v.valor_base_sin_polizas_h,
    t.valor_tabla_final,
    ISNULL(t.valor_tabla_final, 0) - ISNULL(v.valor_base_sin_polizas_h, 0) AS diferencia
FROM validadora_base v
FULL OUTER JOIN tabla_final t
    ON t.periodo_contable = v.periodo_contable
ORDER BY
    COALESCE(v.periodo_contable, t.periodo_contable);
    
   
   
   
-----------   QUERY DAVID 
   IF OBJECT_ID('tempdb.. #cedidas_iaxis') IS NOT NULL
    DROP TABLE  #cedidas_iaxis;
   
   select a.*,inter.INTERMEDIARIO_LIDE
into #cedidas_iaxis
from Liberty.[RESERVAS].CEDIDAS_RESERVA_INTERFAZ_IAXIS a
left join  LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO  inter on inter.ramo_prod = a.ramo_prod and inter.poliza = a.poliza and inter.certificado = a.certificado
where PERIODO_CONTABLE_ANALISIS >= 202601


-------- RESULTADO FINAL

select PERIODO_CONTABLE_ANALISIS,sum(valor_reserva_contable) as valor from #cedidas_iaxis a
INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = a.INTERMEDIARIO_LIDE AND g.cia = 'IAXIS'
where  a.cuenta in ('510305','410305') AND  a.libro <> 'AG'
group by PERIODO_CONTABLE_ANALISIS