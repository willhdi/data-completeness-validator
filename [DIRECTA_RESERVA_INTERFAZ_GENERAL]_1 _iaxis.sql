/* DIRECTA_RESERVA_INTERFAZ 
   ##directa_reserva_final_devengada_tmp
   Liberty.APOYO.DWH_TOMADORES
*/

SET NOCOUNT ON;

/* LIMPIEZA */

IF OBJECT_ID('tempdb..#CLAVES_ASOCIADAS_IAXIS') IS NOT NULL DROP TABLE #CLAVES_ASOCIADAS_IAXIS;

IF OBJECT_ID('tempdb..#TOMADORES_DIRECTA_NORMALIZADO') IS NOT NULL DROP TABLE #TOMADORES_DIRECTA_NORMALIZADO;
IF OBJECT_ID('tempdb..#TOMADORES_DIRECTA_INTERMEDIARIO') IS NOT NULL DROP TABLE #TOMADORES_DIRECTA_INTERMEDIARIO;
IF OBJECT_ID('tempdb..#TOMADORES_DIRECTA_POLIZA') IS NOT NULL DROP TABLE #TOMADORES_DIRECTA_POLIZA;

IF OBJECT_ID('tempdb..#DIRECTA_BASE') IS NOT NULL DROP TABLE #DIRECTA_BASE;
IF OBJECT_ID('tempdb..#CORRETAJE_BASE_DIRECTA') IS NOT NULL DROP TABLE #CORRETAJE_BASE_DIRECTA;
IF OBJECT_ID('tempdb..#CORRETAJE_LIDERES_DIRECTA') IS NOT NULL DROP TABLE #CORRETAJE_LIDERES_DIRECTA;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_RESUMEN_DIRECTA') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_RESUMEN_DIRECTA;
IF OBJECT_ID('tempdb..#CORRETAJE_DOCS_APLICABLES_DIRECTA') IS NOT NULL DROP TABLE #CORRETAJE_DOCS_APLICABLES_DIRECTA;
IF OBJECT_ID('tempdb..#DIRECTA_CON_CORRETAJE') IS NOT NULL DROP TABLE #DIRECTA_CON_CORRETAJE;
IF OBJECT_ID('tempdb..#DIRECTA_GENERAL') IS NOT NULL DROP TABLE #DIRECTA_GENERAL;
IF OBJECT_ID('tempdb..#DIRECTA_COCORRETAJE_DETALLE') IS NOT NULL DROP TABLE #DIRECTA_COCORRETAJE_DETALLE;
IF OBJECT_ID('tempdb..#DIRECTA_COCORRETAJE') IS NOT NULL DROP TABLE #DIRECTA_COCORRETAJE;
IF OBJECT_ID('tempdb..#directa_reserva_final_devengada_tmp') IS NOT NULL DROP TABLE #directa_reserva_final_devengada_tmp;
IF OBJECT_ID('tempdb..##directa_reserva_final_devengada_tmp') IS NOT NULL DROP TABLE ##directa_reserva_final_devengada_tmp;


/* VARIABLES */

DECLARE @PERIODO_INI_DIRECTA INT = 202601;
DECLARE @PERIODO_FIN_DIRECTA INT = 202605;

DECLARE @MACRO_DIRECTA VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_DIRECTA VARCHAR(80) = 'Devengada_Directa';

DECLARE @MACRO_COCORRETAJE_DIRECTA VARCHAR(50) = 'Devengada';
DECLARE @CONCEPTO_COCORRETAJE_DIRECTA VARCHAR(100) = 'Devengada_Directa_CO-Corretaje';

DECLARE @FUENTE_DIRECTA VARCHAR(150) = 'Liberty.[RESERVAS].[DIRECTA_RESERVA_INTERFAZ]';


/* UNIVERSO CLAVES IAXIS */
/*

SELECT DISTINCT
    CAST(b.CLAVE_INICIAL_ASOCIADA AS BIGINT) AS intermediario_lide
INTO #CLAVES_ASOCIADAS_IAXIS
FROM Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores b
WHERE b.cia = 'IAXIS'
  AND b.CLAVE_INICIAL_ASOCIADA IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CLAVES_ASOCIADAS_IAXIS
ON #CLAVES_ASOCIADAS_IAXIS(intermediario_lide);
*/

/* TOMADORES NORMALIZADOS */

SELECT
    CAST(NULLIF(LTRIM(RTRIM(CAST(t.COD_RAMO_PROD AS VARCHAR(20)))), '') AS VARCHAR(20)) AS ramo_prod,
    TRY_CAST(t.NRO_POLIZA AS BIGINT) AS poliza,
    TRY_CAST(t.COD_INTERMEDIARIO AS BIGINT) AS cod_intermediario,

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
INTO #TOMADORES_DIRECTA_NORMALIZADO
FROM Liberty.APOYO.DWH_TOMADORES t
WHERE t.COD_RAMO_PROD IS NOT NULL
  AND t.NRO_POLIZA IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_TOMADORES_DIRECTA_NORMALIZADO
ON #TOMADORES_DIRECTA_NORMALIZADO
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
    FROM #TOMADORES_DIRECTA_NORMALIZADO t
    WHERE t.cod_intermediario IS NOT NULL
)
SELECT
    ramo_prod,
    poliza,
    cod_intermediario,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_DIRECTA_INTERMEDIARIO
FROM TOMADOR_INTERMEDIARIO
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_DIRECTA_INTERMEDIARIO
ON #TOMADORES_DIRECTA_INTERMEDIARIO
(
    ramo_prod,
    poliza,
    cod_intermediario
);


/* TOMADOR ÚNICO POR RAMO + PÓLIZA 
   Este sirve como respaldo cuando no cruza por intermediario.
*/

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
    FROM #TOMADORES_DIRECTA_NORMALIZADO t
)
SELECT
    ramo_prod,
    poliza,
    tipo_identifi_tomador,
    Numero_identificacion_tomador
INTO #TOMADORES_DIRECTA_POLIZA
FROM TOMADOR_POLIZA
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_TOMADORES_DIRECTA_POLIZA
ON #TOMADORES_DIRECTA_POLIZA
(
    ramo_prod,
    poliza
);




/* BASE DIRECTA FILTRADA */

SELECT
    a.ramo_prod,
    a.poliza,
    a.certificado,
    a.documento,
    a.periodo_contable_analisis,
    a.periodo_contable AS periodo_contable_origen,

    CAST(a.INTERMEDIARIO_LIDE AS BIGINT) AS intermediario_inicial,

    CASE WHEN CUENTA in ('510310','410315','510315','41310','510305','410305') THEN CAST(ISNULL(a.valor_reserva_contable, 0) AS DECIMAL(28,6)) *-1 ELSE CAST(ISNULL(a.valor_reserva_contable, 0) AS DECIMAL(28,6)) END AS valor_base,

    CAST(ISNULL(NULLIF(LTRIM(RTRIM(a.MODALIDAD)), ''), 'NULL') AS VARCHAR(20)) AS modalidad,
    CAST('NULL' AS VARCHAR(50)) AS agrupador,
    CAST(ISNULL(NULLIF(LTRIM(RTRIM(a.RIESGO)), ''), 'NULL') AS VARCHAR(20)) AS tipo_riesgo,

    /* CAMPOS TOMADOR DESDE Liberty.APOYO.DWH_TOMADORES */
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

    a.Cuenta,
    a.Libro
INTO #DIRECTA_BASE
FROM Liberty.RESERVAS.DIRECTA_RESERVA_INTERFAZ a
--INNER JOIN #CLAVES_ASOCIADAS_IAXIS b
--    ON b.intermediario_lide = CAST(a.INTERMEDIARIO_LIDE AS BIGINT)

LEFT JOIN #TOMADORES_DIRECTA_INTERMEDIARIO ti
    ON  ti.ramo_prod = CAST(NULLIF(LTRIM(RTRIM(CAST(a.ramo_prod AS VARCHAR(20)))), '') AS VARCHAR(20))
    AND ti.poliza = TRY_CAST(a.poliza AS BIGINT)
    AND ti.cod_intermediario = TRY_CAST(a.INTERMEDIARIO_LIDE AS BIGINT)

LEFT JOIN #TOMADORES_DIRECTA_POLIZA tp
    ON  tp.ramo_prod = CAST(NULLIF(LTRIM(RTRIM(CAST(a.ramo_prod AS VARCHAR(20)))), '') AS VARCHAR(20))
    AND tp.poliza = TRY_CAST(a.poliza AS BIGINT)

WHERE a.periodo_contable_analisis BETWEEN @PERIODO_INI_DIRECTA AND @PERIODO_FIN_DIRECTA
  AND a.CUENTA IN ('410305','410310','410315','510305','510310','510315')
  AND a.Libro <> 'AG';

CREATE NONCLUSTERED INDEX IX_DIRECTA_BASE_LLAVE
ON #DIRECTA_BASE
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    intermediario_inicial
);


/* BASE CORRETAJE */

SELECT
    c.SSEGURO,
    c.RAMO_PROD AS ramo_prod,
    c.POLIZA AS poliza,
    c.CERTIFICADO AS certificado,
    CAST(c.DOCUMENTO_PRIMA AS INT) AS documento,
    CAST(c.AGENTE AS BIGINT) AS agente,
    CAST(ISNULL(c.ES_LIDER, 0) AS INT) AS es_lider,
    CAST(ISNULL(c.PARTICIPACION, 0) AS DECIMAL(18,6)) AS participacion,

    CAST(
        CASE
            WHEN ISNULL(c.ES_LIDER, 0) = 1
                 AND ISNULL(c.PARTICIPACION, 0) < 0
                THEN ISNULL(c.PARTICIPACION, 0) / 100.00

            WHEN ISNULL(c.ES_LIDER, 0) = 1
                THEN (ISNULL(c.PARTICIPACION, 0) - 100.00) / 100.00

            ELSE ISNULL(c.PARTICIPACION, 0) / 100.00
        END
    AS DECIMAL(18,8)) AS factor_corretaje
INTO #CORRETAJE_BASE_DIRECTA
FROM Liberty_Pruebas_Actuaria.dbo.polizas_corretaje_iaxis c
WHERE c.RAMO_PROD IS NOT NULL
  AND c.POLIZA IS NOT NULL
  AND c.CERTIFICADO IS NOT NULL
  AND c.DOCUMENTO_PRIMA IS NOT NULL
  AND c.AGENTE IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_BASE_DIRECTA_LLAVE
ON #CORRETAJE_BASE_DIRECTA
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente,
    es_lider
);


/* DOCUMENTOS APLICABLES */

SELECT DISTINCT
    cb.ramo_prod,
    cb.poliza,
    cb.certificado,
    cb.documento,
    cb.agente AS agente_lider
INTO #CORRETAJE_LIDERES_DIRECTA
FROM #CORRETAJE_BASE_DIRECTA cb
WHERE cb.es_lider = 1;

SELECT
    cb.ramo_prod,
    cb.poliza,
    cb.certificado,
    cb.documento,
    COUNT(*) AS registros_corretaje,
    SUM(CASE WHEN cb.es_lider = 1 THEN 1 ELSE 0 END) AS registros_lider,
    SUM(CASE WHEN cb.es_lider <> 1 THEN 1 ELSE 0 END) AS registros_asociados,
    SUM(ISNULL(cb.factor_corretaje, 0)) AS suma_factor_corretaje
INTO #CORRETAJE_DOCS_RESUMEN_DIRECTA
FROM #CORRETAJE_BASE_DIRECTA cb
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
INTO #CORRETAJE_DOCS_APLICABLES_DIRECTA
FROM #CORRETAJE_DOCS_RESUMEN_DIRECTA r
INNER JOIN #CORRETAJE_LIDERES_DIRECTA l
    ON  l.ramo_prod = r.ramo_prod
    AND l.poliza = r.poliza
    AND l.certificado = r.certificado
    AND l.documento = r.documento
WHERE r.registros_lider > 0
  AND r.registros_asociados > 0;

CREATE NONCLUSTERED INDEX IX_CORRETAJE_DOCS_APLICABLES_DIRECTA
ON #CORRETAJE_DOCS_APLICABLES_DIRECTA
(
    ramo_prod,
    poliza,
    certificado,
    documento,
    agente_lider
);


/* DIRECTAS CON CORRETAJE */

SELECT
    d.*
INTO #DIRECTA_CON_CORRETAJE
FROM #DIRECTA_BASE d
INNER JOIN #CORRETAJE_DOCS_APLICABLES_DIRECTA ca
    ON  ca.ramo_prod = d.ramo_prod
    AND ca.poliza = d.poliza
    AND ca.certificado = d.certificado
    AND ca.documento = d.documento
    AND ca.agente_lider = d.intermediario_inicial;


/* BLOQUE ORIGINAL */

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
    CAST(@MACRO_DIRECTA AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_DIRECTA AS VARCHAR(80)) AS concepto,
    CAST(SUM(d.valor_base) AS DECIMAL(28,6)) AS valor_concepto,
    CAST(@FUENTE_DIRECTA AS VARCHAR(150)) AS fuente_primaria
INTO #DIRECTA_GENERAL
FROM #DIRECTA_BASE d
GROUP BY
    d.periodo_contable_analisis,
    d.intermediario_inicial,
    d.ramo_prod,
    d.poliza,
    d.modalidad,
    d.agrupador,
    d.tipo_riesgo,
    d.tipo_identifi_tomador,
    d.Numero_identificacion_tomador;


/* BLOQUE CO-CORRETAJE */

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
    CAST(@MACRO_COCORRETAJE_DIRECTA AS VARCHAR(50)) AS macro_concepto,
    CAST(@CONCEPTO_COCORRETAJE_DIRECTA AS VARCHAR(100)) AS concepto,
    CAST(@FUENTE_DIRECTA AS VARCHAR(150)) AS fuente_primaria
INTO #DIRECTA_COCORRETAJE_DETALLE
FROM #DIRECTA_CON_CORRETAJE d
INNER JOIN #CORRETAJE_BASE_DIRECTA cb
    ON  cb.ramo_prod = d.ramo_prod
    AND cb.poliza = d.poliza
    AND cb.certificado = d.certificado
    AND cb.documento = d.documento
WHERE cb.factor_corretaje <> 0;

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
    dc.fuente_primaria
INTO #DIRECTA_COCORRETAJE
FROM #DIRECTA_COCORRETAJE_DETALLE dc
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
    dc.fuente_primaria;


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
    x.fuente_primaria
INTO #directa_reserva_final_devengada_tmp
FROM
(
    SELECT * FROM #DIRECTA_GENERAL
    UNION ALL
    SELECT * FROM #DIRECTA_COCORRETAJE
) x;


/* FINAL GLOBAL */

SELECT *
INTO ##directa_reserva_final_devengada_tmp
FROM #directa_reserva_final_devengada_tmp;

CREATE NONCLUSTERED INDEX IX_global_directa_reserva_final_devengada_tmp
ON ##directa_reserva_final_devengada_tmp
(
    periodo_contable,
    ramo_prod,
    poliza,
    intermediario_inicial,
    intermediario_final_asociado,
    concepto
);


drop table liberty_pruebas_actuaria.dbo.directa_reserva_general
select *
into liberty_pruebas_actuaria.dbo.directa_reserva_general
from  ##directa_reserva_final_devengada_tmp



----------------validar long caracteres


select* from ##directa_reserva_final_devengada_tmp

select * from liberty_pruebas_actuaria.dbo.directa_reserva_general

where  poliza = 611576   ORDER BY PERIODO_CONTABLE
select * from liberty_pruebas_actuaria.dbo.directa_reserva_final_devengada_tmp

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
WHERE c.object_id = OBJECT_ID('tempdb..##directa_reserva_final_devengada_tmp')
ORDER BY
    c.column_id;
 

 select * from ##directa_reserva_final_devengada_tmp


/* CONSULTA FINAL */

SELECT *
FROM ##directa_reserva_final_devengada_tmp
ORDER BY
    periodo_contable,
    ramo_prod,
    poliza,
    intermediario_inicial,
    concepto,
    intermediario_final_asociado;


/* VALIDACIÓN RÁPIDA DE TOMADORES */

SELECT
    periodo_contable,
    concepto,
    COUNT(*) AS registros,
    SUM(valor_concepto) AS total_valor,
    SUM(CASE WHEN Numero_identificacion_tomador = 'NULL' THEN 1 ELSE 0 END) AS registros_sin_tomador
FROM ##directa_reserva_final_devengada_tmp
where periodo_contable = 202501
GROUP BY
    periodo_contable,
    concepto
ORDER BY
    periodo_contable,
    concepto;