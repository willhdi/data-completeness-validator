/* Liberty.RESERVAS.CEDIDAS_TERREMOTO_RESERVA_INTERFAZ
   ##cedidas_terremoto_reserva_final_devengada_tmp */

SET NOCOUNT ON;


/* LIMPIEZA */

IF OBJECT_ID('tempdb..#CLAVES_ASOCIADAS_IAXIS') IS NOT NULL DROP TABLE #CLAVES_ASOCIADAS_IAXIS;

IF OBJECT_ID('tempdb..#TOMADORES_CTER_NORMALIZADO') IS NOT NULL DROP TABLE #TOMADORES_CTER_NORMALIZADO;
IF OBJECT_ID('tempdb..#TOMADORES_CTER_INTERMEDIARIO') IS NOT NULL DROP TABLE #TOMADORES_CTER_INTERMEDIARIO;
IF OBJECT_ID('tempdb..#TOMADORES_CTER_POLIZA') IS NOT NULL DROP TABLE #TOMADORES_CTER_POLIZA;

IF OBJECT_ID('tempdb..#CEDIDAS_TERREMOTO_WORK') IS NOT NULL DROP TABLE #CEDIDAS_TERREMOTO_WORK;
IF OBJECT_ID('tempdb..#INTERMEDIARIOS_UNICOS_DWH_CTER') IS NOT NULL DROP TABLE #INTERMEDIARIOS_UNICOS_DWH_CTER;
IF OBJECT_ID('tempdb..#DWH_DOCUMENTO_REAL_CTER') IS NOT NULL DROP TABLE #DWH_DOCUMENTO_REAL_CTER;

IF OBJECT_ID('tempdb..#CEDIDAS_TERREMOTO_BASE') IS NOT NULL DROP TABLE #CEDIDAS_TERREMOTO_BASE;

IF OBJECT_ID('tempdb..#CORRETAJE_BASE_CTER') IS NOT NULL DROP TABLE #CORRETAJE_BASE_CTER;
IF OBJECT_ID('tempdb..#CORRETAJE_LIDERES_CTER') IS NOT NULL DROP TABLE #CORRETAJE_LIDERES_CTER;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_RESUMEN_CTER') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_RESUMEN_CTER;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_APLICABLES_CTER') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_APLICABLES_CTER;

IF OBJECT_ID('tempdb..#CEDIDAS_TERREMOTO_CON_CORRETAJE') IS NOT NULL DROP TABLE #CEDIDAS_TERREMOTO_CON_CORRETAJE;

IF OBJECT_ID('tempdb..#CEDIDAS_TERREMOTO_GENERAL') IS NOT NULL DROP TABLE #CEDIDAS_TERREMOTO_GENERAL;
IF OBJECT_ID('tempdb..#CEDIDAS_TERREMOTO_COCORRETAJE_DETALLE') IS NOT NULL DROP TABLE #CEDIDAS_TERREMOTO_COCORRETAJE_DETALLE;
IF OBJECT_ID('tempdb..#CEDIDAS_TERREMOTO_COCORRETAJE') IS NOT NULL DROP TABLE #CEDIDAS_TERREMOTO_COCORRETAJE;

IF OBJECT_ID('tempdb..#cedidas_terremoto_reserva_final_devengada_tmp') IS NOT NULL DROP TABLE #cedidas_terremoto_reserva_final_devengada_tmp;
IF OBJECT_ID('tempdb..##cedidas_terremoto_reserva_final_devengada_tmp') IS NOT NULL DROP TABLE ##cedidas_terremoto_reserva_final_devengada_tmp;


/* VARIABLES */

DECLARE @PERIODO_INI_CTER INT = 202601;
DECLARE @PERIODO_FIN_CTER INT = 202605;

DECLARE @MACRO_CEDIDA_TERREMOTO VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_CEDIDA_TERREMOTO VARCHAR(100) = 'Devengada_Cedida_Terremoto';

DECLARE @MACRO_COCORRETAJE_CTER VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_COCORRETAJE_CTER VARCHAR(120) = 'Devengada_Cedida_Terremoto_CO-Corretaje';

DECLARE @FUENTE_CEDIDA_TERREMOTO VARCHAR(150) = 'Liberty.[RESERVAS].[CEDIDAS_TERREMOTO_RESERVA_INTERFAZ]';

----SI TIENE CORRETAJE COLOCAR concepto = Ajuste_reserva_tecnica   

/* CLAVES IAXIS */

SELECT DISTINCT
    LTRIM(RTRIM(CAST(g.CLAVE_INICIAL_ASOCIADA AS VARCHAR(50)))) AS intermediario_lide
INTO #CLAVES_ASOCIADAS_IAXIS
FROM Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g
WHERE g.cia = 'IAXIS'
  AND g.CLAVE_INICIAL_ASOCIADA IS NOT NULL
  AND LTRIM(RTRIM(CAST(g.CLAVE_INICIAL_ASOCIADA AS VARCHAR(50)))) <> '';

CREATE NONCLUSTERED INDEX IX_CLAVES_ASOCIADAS_IAXIS
ON #CLAVES_ASOCIADAS_IAXIS(intermediario_lide);


/* TOMADORES NORMALIZADOS */

SELECT
    LTRIM(RTRIM(CAST(t.COD_RAMO_PROD AS VARCHAR(50)))) AS ramo_prod,
    LTRIM(RTRIM(CAST(t.NRO_POLIZA AS VARCHAR(50)))) AS poliza,
    LTRIM(RTRIM(CAST(t.COD_INTERMEDIARIO AS VARCHAR(50)))) AS cod_intermediario,

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
INTO #TOMADORES_CTER_NORMALIZADO
FROM Liberty.APOYO.DWH_TOMADORES t
WHERE t.COD_RAMO_PROD IS NOT NULL
  AND t.NRO_POLIZA IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_TOMADORES_CTER_NORMALIZADO
ON #TOMADORES_CTER_NORMALIZADO
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
            PARTITION BY t.ramo_prod, t.poliza, t.cod_intermediario
            ORDER BY
                COALESCE(t.FECHA_ACTUALIZACION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC,
                COALESCE(t.FECHA_EJECUCION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC
        ) AS rn
    FROM #TOMADORES_CTER_NORMALIZADO t
    WHERE t.cod_intermediario IS NOT NULL
      AND t.cod_intermediario <> ''
)
SELECT
    ramo_prod,
    poliza,
    cod_intermediario,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_CTER_INTERMEDIARIO
FROM TOMADOR_INTERMEDIARIO
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_CTER_INTERMEDIARIO
ON #TOMADORES_CTER_INTERMEDIARIO
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
            PARTITION BY t.ramo_prod, t.poliza
            ORDER BY
                COALESCE(t.FECHA_ACTUALIZACION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC,
                COALESCE(t.FECHA_EJECUCION_DWH, CONVERT(DATETIME, '19000101', 112)) DESC
        ) AS rn
    FROM #TOMADORES_CTER_NORMALIZADO t
)
SELECT
    ramo_prod,
    poliza,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_CTER_POLIZA
FROM TOMADOR_POLIZA
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_CTER_POLIZA
ON #TOMADORES_CTER_POLIZA
(
    ramo_prod,
    poliza
);


/* PRINCIPAL */

SELECT
    IDENTITY(BIGINT, 1, 1) AS cedida_terremoto_row_id,

    a.COMPANIA,
    TRY_CONVERT(INT, a.SUCURSAL_LIDE) AS sucursal_lide,

    LTRIM(RTRIM(CAST(a.RAMO_PROD AS VARCHAR(50)))) AS ramo_prod,
    LTRIM(RTRIM(CAST(a.POLIZA AS VARCHAR(50)))) AS poliza,
   case when a.RAMO_PROD in ('900754','900758','','900745','10001','900779','900742','900748','10000','900746') and a.CERTIFICADO is null then 0 else LTRIM(RTRIM(CAST(a.CERTIFICADO AS VARCHAR(50)))) end AS certificado, ---- ramos que solo tienen certificado por la l abase de terremoto generalmente vienen sin certificado

    /* En esta tabla DOCUMENTO es RECIBO */
    LTRIM(RTRIM(CAST(a.DOCUMENTO AS VARCHAR(50)))) AS recibo_fuente,

    a.PERIODO_CONTABLE_ANALISIS AS periodo_contable_analisis,
    a.PERIODO_CONTABLE AS periodo_contable_origen,

    CAST(ISNULL(a.VALOR_RESERVA_CONTABLE, 0) AS DECIMAL(28,6)) AS valor_base,

    CAST(ISNULL(NULLIF(LTRIM(RTRIM(a.MODALIDAD)), ''), 'NULL') AS VARCHAR(20)) AS modalidad,
    CAST('NULL' AS VARCHAR(50)) AS agrupador,
    CAST('NULL' AS VARCHAR(20)) AS tipo_riesgo,

    a.CUENTA AS cuenta,
    a.LIBRO AS libro,
    a.FUENTE_INTERFAZ AS fuente_interfaz,

    LTRIM(RTRIM(CAST(inter.INTERMEDIARIO_LIDE AS VARCHAR(50)))) AS intermediario_lide,

    CAST(
        CASE 
            WHEN inter.INTERMEDIARIO_LIDE IS NOT NULL 
                THEN '01_POLIZA_INTERMEDIARIO_RAMO_POLIZA_CERTIFICADO'
            ELSE '00_PENDIENTE'
        END AS VARCHAR(100)
    ) AS fuente_intermediario_lide,

    CAST(0 AS INT) AS requiere_revision_intermediario
INTO #CEDIDAS_TERREMOTO_WORK
FROM Liberty.RESERVAS.CEDIDAS_TERREMOTO_RESERVA_INTERFAZ a
LEFT JOIN Liberty.RESERVAS.POLIZA_INTERMEDIARIO inter
    ON  inter.ramo_prod = a.ramo_prod
    AND inter.poliza = a.poliza
    AND inter.certificado = a.certificado
WHERE a.PERIODO_CONTABLE_ANALISIS BETWEEN @PERIODO_INI_CTER AND @PERIODO_FIN_CTER
  AND TRY_CONVERT(BIGINT, a.CUENTA) IN (410305, 510305, 419595)
  AND UPPER(LTRIM(RTRIM(CAST(a.FUENTE_INTERFAZ AS VARCHAR(50))))) = 'TERR'
  AND ISNULL(LTRIM(RTRIM(CAST(a.LIBRO AS VARCHAR(20)))), '') <> 'AG';

CREATE NONCLUSTERED INDEX IX_CEDIDAS_TERREMOTO_WORK_01
ON #CEDIDAS_TERREMOTO_WORK
(
    ramo_prod,
    poliza,
    certificado,
    recibo_fuente,
    intermediario_lide
);

CREATE NONCLUSTERED INDEX IX_CEDIDAS_TERREMOTO_WORK_ROW
ON #CEDIDAS_TERREMOTO_WORK(cedida_terremoto_row_id);


/* ACTUALIZACIÓN INTERMEDIARIO 1 */

UPDATE a
SET
    a.intermediario_lide =
        CASE 
            WHEN a.sucursal_lide = 94 THEN '9400'
            ELSE LTRIM(RTRIM(CAST(inter.INTERMEDIARIO_LIDE AS VARCHAR(50))))
        END,
    a.fuente_intermediario_lide =
        CASE
            WHEN a.sucursal_lide = 94 THEN '02_SUCURSAL_94_9400'
            WHEN inter.INTERMEDIARIO_LIDE IS NOT NULL THEN '03_POLIZA_INTERMEDIARIO_RAMO_POLIZA'
            ELSE a.fuente_intermediario_lide
        END
FROM #CEDIDAS_TERREMOTO_WORK a
LEFT JOIN Liberty.RESERVAS.POLIZA_INTERMEDIARIO inter
    ON  inter.ramo_prod = a.ramo_prod
    AND inter.poliza = a.poliza
WHERE a.intermediario_lide IS NULL
   OR a.intermediario_lide = '';


/* INTERMEDIARIOS ÚNICOS DESDE DWH_POLIZAS_H */

SELECT
    x.ramo_prod,
    x.poliza,
    x.intermediario_lide
INTO #INTERMEDIARIOS_UNICOS_DWH_CTER
FROM
(
    SELECT
        LTRIM(RTRIM(CAST(dwh.ramo_prod AS VARCHAR(50)))) AS ramo_prod,
        LTRIM(RTRIM(CAST(dwh.poliza AS VARCHAR(50)))) AS poliza,
        LTRIM(RTRIM(CAST(dwh.intermediario_lide AS VARCHAR(50)))) AS intermediario_lide,

        ROW_NUMBER() OVER
        (
            PARTITION BY
                LTRIM(RTRIM(CAST(dwh.ramo_prod AS VARCHAR(50)))),
                LTRIM(RTRIM(CAST(dwh.poliza AS VARCHAR(50))))
            ORDER BY
                TRY_CONVERT(BIGINT, dwh.intermediario_lide) ASC,
                LTRIM(RTRIM(CAST(dwh.intermediario_lide AS VARCHAR(50)))) ASC
        ) AS rn
    FROM liberty.prod.dwh_polizas_h dwh
    WHERE dwh.PERIODO_CONTABLE >= 202001
      AND dwh.ramo_prod IS NOT NULL
      AND dwh.poliza IS NOT NULL
      AND dwh.intermediario_lide IS NOT NULL
) x
WHERE x.rn = 1;

CREATE NONCLUSTERED INDEX IX_INTERMEDIARIOS_UNICOS_DWH_CTER
ON #INTERMEDIARIOS_UNICOS_DWH_CTER
(
    ramo_prod,
    poliza,
    intermediario_lide
);


/*  ACTUALIZACIÓN INTERMEDIARIO 2 */

UPDATE a
SET
    a.intermediario_lide = b.intermediario_lide,
    a.fuente_intermediario_lide = '04_DWH_POLIZAS_H_RAMO_POLIZA'
FROM #CEDIDAS_TERREMOTO_WORK a
LEFT JOIN #INTERMEDIARIOS_UNICOS_DWH_CTER b
    ON  b.ramo_prod = a.ramo_prod
    AND b.poliza = a.poliza
WHERE (a.intermediario_lide IS NULL OR a.intermediario_lide = '')
  AND b.intermediario_lide IS NOT NULL;


/* DOCUMENTO REAL DESDE DWH_POLIZAS_H */

SELECT
    LTRIM(RTRIM(CAST(dwh.ramo_prod AS VARCHAR(50)))) AS ramo_prod,
    LTRIM(RTRIM(CAST(dwh.poliza AS VARCHAR(50)))) AS poliza,
    LTRIM(RTRIM(CAST(dwh.certificado AS VARCHAR(50)))) AS certificado,
    LTRIM(RTRIM(CAST(dwh.recibo AS VARCHAR(50)))) AS recibo,

    MAX(LTRIM(RTRIM(CAST(dwh.documento AS VARCHAR(50))))) AS documento_real,

    COUNT(*) AS registros_dwh,
    COUNT(DISTINCT LTRIM(RTRIM(CAST(dwh.documento AS VARCHAR(50))))) AS documentos_distintos
INTO #DWH_DOCUMENTO_REAL_CTER
FROM liberty.prod.dwh_polizas_h dwh
WHERE dwh.ramo_prod IS NOT NULL
  AND dwh.poliza IS NOT NULL
  AND dwh.certificado IS NOT NULL
  AND dwh.recibo IS NOT NULL
  AND dwh.documento IS NOT NULL
GROUP BY
    LTRIM(RTRIM(CAST(dwh.ramo_prod AS VARCHAR(50)))),
    LTRIM(RTRIM(CAST(dwh.poliza AS VARCHAR(50)))),
    LTRIM(RTRIM(CAST(dwh.certificado AS VARCHAR(50)))),
    LTRIM(RTRIM(CAST(dwh.recibo AS VARCHAR(50))));

CREATE NONCLUSTERED INDEX IX_DWH_DOCUMENTO_REAL_CTER
ON #DWH_DOCUMENTO_REAL_CTER
(
    ramo_prod,
    poliza,
    certificado,
    recibo,
    documento_real
);


/* BASE FINAL IAXIS + DOCUMENTO REAL + TOMADOR */

SELECT
    w.cedida_terremoto_row_id,
    w.ramo_prod,
    w.poliza,
    w.certificado,
    w.recibo_fuente,

    dwh.documento_real,

    CASE
        WHEN dwh.documento_real IS NULL THEN 'SIN_DOCUMENTO_REAL_POLIZAS_H'
        WHEN ISNULL(dwh.documentos_distintos, 0) > 1 THEN 'DOCUMENTO_REAL_MULTIPLE_POLIZAS_H'
        ELSE 'DOCUMENTO_REAL_UNICO_POLIZAS_H'
    END AS regla_documento,

    CASE
        WHEN dwh.documento_real IS NULL THEN 1
        WHEN ISNULL(dwh.documentos_distintos, 0) > 1 THEN 1
        ELSE 0
    END AS requiere_revision_documento,

    w.periodo_contable_analisis,
    w.periodo_contable_origen,

    w.intermediario_lide AS intermediario_inicial,
    w.fuente_intermediario_lide,
    w.requiere_revision_intermediario,

    w.valor_base,
    w.modalidad,
    w.agrupador,
    w.tipo_riesgo,

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

    w.cuenta,
    w.libro,
    w.fuente_interfaz
INTO #CEDIDAS_TERREMOTO_BASE
FROM #CEDIDAS_TERREMOTO_WORK w

---INNER JOIN #CLAVES_ASOCIADAS_IAXIS g
---    ON g.intermediario_lide = w.intermediario_lide

LEFT JOIN #DWH_DOCUMENTO_REAL_CTER dwh
    ON  dwh.ramo_prod = w.ramo_prod
    AND dwh.poliza = w.poliza
    AND dwh.certificado = w.certificado
    AND dwh.recibo = w.recibo_fuente

LEFT JOIN #TOMADORES_CTER_INTERMEDIARIO ti
    ON  ti.ramo_prod = w.ramo_prod
    AND ti.poliza = w.poliza
    AND ti.cod_intermediario = w.intermediario_lide

LEFT JOIN #TOMADORES_CTER_POLIZA tp
    ON  tp.ramo_prod = w.ramo_prod
    AND tp.poliza = w.poliza;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_TERREMOTO_BASE
ON #CEDIDAS_TERREMOTO_BASE
(
    ramo_prod,
    poliza,
    certificado,
    documento_real,
    intermediario_inicial
);


/* BASE CORRETAJE */

SELECT DISTINCT
    c.SSEGURO,
    LTRIM(RTRIM(CAST(c.RAMO_PROD AS VARCHAR(50)))) AS ramo_prod,
    LTRIM(RTRIM(CAST(c.POLIZA AS VARCHAR(50)))) AS poliza,
    LTRIM(RTRIM(CAST(c.CERTIFICADO AS VARCHAR(50)))) AS certificado,
    LTRIM(RTRIM(CAST(c.DOCUMENTO_PRIMA AS VARCHAR(50)))) AS documento,
    LTRIM(RTRIM(CAST(c.AGENTE AS VARCHAR(50)))) AS agente,

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
INTO #CORRETAJE_BASE_CTER
FROM Liberty_Pruebas_Actuaria.dbo.polizas_corretaje_iaxis c
WHERE c.RAMO_PROD IS NOT NULL
  AND c.POLIZA IS NOT NULL
  AND c.CERTIFICADO IS NOT NULL
  AND c.DOCUMENTO_PRIMA IS NOT NULL
  AND c.AGENTE IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_BASE_CTER
ON #CORRETAJE_BASE_CTER
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
INTO #CORRETAJE_LIDERES_CTER
FROM #CORRETAJE_BASE_CTER cb
WHERE cb.es_lider = 1;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_LIDERES_CTER
ON #CORRETAJE_LIDERES_CTER
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
INTO #CORRETAJE_DOCS_RESUMEN_CTER
FROM #CORRETAJE_BASE_CTER cb
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
INTO #CORRETAJE_DOCS_APLICABLES_CTER
FROM #CORRETAJE_DOCS_RESUMEN_CTER r
INNER JOIN #CORRETAJE_LIDERES_CTER l
    ON  l.ramo_prod = r.ramo_prod
    AND l.poliza = r.poliza
    AND l.certificado = r.certificado
    AND l.documento = r.documento
WHERE r.registros_lider > 0
  AND r.registros_asociados > 0;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_DOCS_APLICABLES_CTER
ON #CORRETAJE_DOCS_APLICABLES_CTER
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente_lider
);


/* BASE CON CO-CORRETAJE */

SELECT
    d.*
INTO #CEDIDAS_TERREMOTO_CON_CORRETAJE
FROM #CEDIDAS_TERREMOTO_BASE d
INNER JOIN #CORRETAJE_DOCS_APLICABLES_CTER ca
    ON  ca.ramo_prod = d.ramo_prod
    AND ca.poliza = d.poliza
    AND ca.certificado = d.certificado
    AND ca.documento = d.documento_real
    AND ca.agente_lider = d.intermediario_inicial;

CREATE NONCLUSTERED INDEX IX_CEDIDAS_TERREMOTO_CON_CORRETAJE
ON #CEDIDAS_TERREMOTO_CON_CORRETAJE
(
    ramo_prod,
    poliza,
    certificado,
    documento_real,
    intermediario_inicial
);


/* BLOQUE BASE DEVENGADA CEDIDA TERREMOTO */

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

    CAST(@MACRO_CEDIDA_TERREMOTO AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_CEDIDA_TERREMOTO AS VARCHAR(100)) AS concepto,

    CAST(SUM(d.valor_base) AS DECIMAL(28,6)) *-1 AS valor_concepto, --- hago este ajuste por que no cuadr acon lo de david de PU

    CAST(@FUENTE_CEDIDA_TERREMOTO AS VARCHAR(150)) AS fuente_primaria,

    d.fuente_intermediario_lide,
    d.regla_documento,
    d.requiere_revision_documento,
    d.requiere_revision_intermediario
INTO #CEDIDAS_TERREMOTO_GENERAL
FROM #CEDIDAS_TERREMOTO_BASE d
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
    d.fuente_intermediario_lide,
    d.regla_documento,
    d.requiere_revision_documento,
    d.requiere_revision_intermediario;

 /* BLOQUE CO-CORRETAJE DETALLE */

SELECT
    CAST('HDISC' AS VARCHAR(10)) AS compania,
    d.periodo_contable_analisis AS periodo_contable,
    d.intermediario_inicial,
    cb.agente AS intermediario_final_asociado,
    d.ramo_prod,
    d.poliza,
    d.certificado,
    d.recibo_fuente,
    d.documento_real,

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

    CAST(@MACRO_COCORRETAJE_CTER AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_COCORRETAJE_CTER AS VARCHAR(120)) AS concepto,

    CAST(@FUENTE_CEDIDA_TERREMOTO AS VARCHAR(150)) AS fuente_primaria,

    d.fuente_intermediario_lide,
    d.regla_documento,
    d.requiere_revision_documento,
    d.requiere_revision_intermediario
INTO #CEDIDAS_TERREMOTO_COCORRETAJE_DETALLE
FROM #CEDIDAS_TERREMOTO_CON_CORRETAJE d
INNER JOIN #CORRETAJE_BASE_CTER cb
    ON  cb.ramo_prod = d.ramo_prod
    AND cb.poliza = d.poliza
    AND cb.certificado = d.certificado
    AND cb.documento = d.documento_real
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

    dc.fuente_intermediario_lide,
    dc.regla_documento,
    dc.requiere_revision_documento,
    dc.requiere_revision_intermediario
INTO #CEDIDAS_TERREMOTO_COCORRETAJE
FROM #CEDIDAS_TERREMOTO_COCORRETAJE_DETALLE dc
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
    dc.fuente_intermediario_lide,
    dc.regla_documento,
    dc.requiere_revision_documento,
    dc.requiere_revision_intermediario;


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
    x.fuente_intermediario_lide,
    x.regla_documento,
    x.requiere_revision_documento,
    x.requiere_revision_intermediario
INTO #cedidas_terremoto_reserva_final_devengada_tmp
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
        fuente_intermediario_lide,
        regla_documento,
        requiere_revision_documento,
        requiere_revision_intermediario
    FROM #CEDIDAS_TERREMOTO_GENERAL

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
        fuente_intermediario_lide,
        regla_documento,
        requiere_revision_documento,
        requiere_revision_intermediario
    FROM #CEDIDAS_TERREMOTO_COCORRETAJE
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
    fuente_intermediario_lide,
    regla_documento,
    requiere_revision_documento,
    requiere_revision_intermediario
INTO ##cedidas_terremoto_reserva_final_devengada_tmp
FROM #cedidas_terremoto_reserva_final_devengada_tmp;

CREATE NONCLUSTERED INDEX IX_global_cedidas_terremoto_reserva_final_devengada_tmp
ON ##cedidas_terremoto_reserva_final_devengada_tmp
(
    periodo_contable,
    ramo_prod,
    poliza,
    intermediario_inicial,
    intermediario_final_asociado,
    concepto
);

drop table liberty_pruebas_actuaria.dbo.cedidas_terremoto_general
select *
into liberty_pruebas_actuaria.dbo.cedidas_terremoto_general
from ##cedidas_terremoto_reserva_final_devengada_tmp
 






 -------------------------------------------- long 
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
WHERE c.object_id = OBJECT_ID('tempdb..##cedidas_terremoto_reserva_final_devengada_tmp')
ORDER BY
    c.column_id;




------VALIDAR -----

select periodo_contable,sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_terremoto_general group by periodo_contable order by periodo_contable
select periodo_contable,sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp group by periodo_contable order by periodo_contable


select ramo_prod,sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp_n where periodo_contable = 202603 group by periodo_contable , ramo_prod order by periodo_contable
select ramo_prod,sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp where periodo_contable = 202603 group by periodo_contable, ramo_prod  order by periodo_contable


select POLIZA,sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp_n where periodo_contable = 202603 and ramo_prod='LGP' group by periodo_contable , POLIZA order by POLIZA
select POLIZA,sum(valor_concepto) from liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp where periodo_contable = 202603 and ramo_prod='LGP' group by periodo_contable, POLIZA  order by POLIZA



SELECT
    periodo_contable,
    concepto,
    COUNT(*) AS registros,
    SUM(valor_concepto) AS total_valor
FROM ##cedidas_terremoto_reserva_final_devengada_tmp
GROUP BY
    periodo_contable,
    concepto
ORDER BY
    periodo_contable,
    concepto;
    
   --------------------tabla general que se llame 
   SELECT * FROM liberty_pruebas_actuaria.dbo.directa_reserva_final_devengada_tmp_N
   UNION ALL
   SELECT * FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_final_devengada_tmp_N
   UNION ALL
   SELECT * FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp_N 
   UNION ALL 
   SELECT * FROM liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp_n



   SELECT DISTINCT CONCEPTO, VALOR_CONCEPTO FROM liberty_pruebas_actuaria.dbo.directa_reserva_final_devengada_tmp_N WHERE POLIZA = 648725 AND PERIODO_CONTABLE = 202603
   UNION ALL
   SELECT DISTINCT CONCEPTO,VALOR_CONCEPTO FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_final_devengada_tmp_N WHERE POLIZA = 648725 AND PERIODO_CONTABLE = 202603
   UNION ALL
   SELECT DISTINCT CONCEPTO,VALOR_CONCEPTO FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp_N  WHERE POLIZA = 648725 AND PERIODO_CONTABLE = 202603
   UNION ALL 
   SELECT DISTINCT CONCEPTO,VALOR_CONCEPTO FROM liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp_n WHERE POLIZA = 648725 AND PERIODO_CONTABLE = 202603


   SELECT DISTINCT CONCEPTO,VALOR_CONCEPTO  FROM liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA_N WHERE POLIZA = 648725 AND PERIODO_CONTABLE = 202603
   SELECT DISTINCT CONCEPTO,VALOR_CONCEPTO  FROM liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA WHERE POLIZA = 648725 AND PERIODO_CONTABLE = 202603




   SELECT * FROM liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA WHERE RAMO_PROD = '10024' AND PERIODO_CONTABLE = 202603 ORDER BY VALOR_CONCEPTO DESC 

   SELECT TOP 5 *  FROM  Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS