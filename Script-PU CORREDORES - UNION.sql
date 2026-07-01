USE [Liberty_Pruebas_Actuaria];

---IF OBJECT_ID([Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION) IS NOT NULL
    DROP TABLE [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo;


/* FACT GLOBAL PU CORREDORES - VERSIÓN OPTIMIZADA*/


WITH union_base AS (

    /*PRIMAS PU CORREDORES */
    SELECT
        CAST([Compania] AS VARCHAR(20)) AS Compania,
        TRY_CONVERT(INT, [periodo_contable]) AS periodo_contable,
        CAST([intermediario_inicial] AS VARCHAR(50)) AS intermediario_inicial,
        CAST([intermediario_final_asociado] AS VARCHAR(50)) AS intermediario_final_asociado,
        CAST([ramo_prod] AS VARCHAR(50)) AS ramo_prod,
        CAST([poliza] AS VARCHAR(80)) AS poliza,
        CAST([modalidad] AS VARCHAR(80)) AS modalidad,
        CAST([agrupador] AS VARCHAR(80)) AS agrupador,
        CAST([tipo_riesgo] AS VARCHAR(80)) AS tipo_riesgo,
        CAST([tipo_identifi_tomador] AS VARCHAR(20)) AS tipo_identifi_tomador,
        CAST([Numero_identificacion_tomador] AS VARCHAR(80)) AS Numero_identificacion_tomador,
        CAST([macro_concepto] AS VARCHAR(150)) AS macro_concepto,
        CAST([concepto] AS VARCHAR(150)) AS concepto,
        TRY_CONVERT(DECIMAL(38, 6), [valor_concepto]) AS valor_concepto,
        CAST([fuente_primaria] AS VARCHAR(150)) AS fuente_primaria,
        CAST('Emitida_general' AS VARCHAR(150)) AS tabla_origen
    FROM [Liberty_Pruebas_Actuaria].[dbo].Emitida_general A 
		INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.[intermediario_inicial] AND g.cia = a.[Compania]
		WHERE [periodo_contable] >= 202501


    UNION ALL


    /*SINIESTROS */
    SELECT
        CAST([Compania] AS VARCHAR(20)) AS Compania,
        TRY_CONVERT(INT, [periodo_contable]) AS periodo_contable,
        CAST([intermediario_inicial] AS VARCHAR(50)) AS intermediario_inicial,
        CAST([intermediario_final_asociado] AS VARCHAR(50)) AS intermediario_final_asociado,
        CAST([ramo_prod] AS VARCHAR(50)) AS ramo_prod,
        CAST([poliza] AS VARCHAR(80)) AS poliza,
        CAST([modalidad] AS VARCHAR(80)) AS modalidad,
        CAST([agrupador] AS VARCHAR(80)) AS agrupador,
        CAST([tipo_riesgo] AS VARCHAR(80)) AS tipo_riesgo,
        CAST([tipo_identifi_tomador] AS VARCHAR(20)) AS tipo_identifi_tomador,
        CAST([Numero_identificacion_tomador] AS VARCHAR(80)) AS Numero_identificacion_tomador,
        CAST([macro_concepto] AS VARCHAR(150)) AS macro_concepto,
        CAST([concepto] AS VARCHAR(150)) AS concepto,
        TRY_CONVERT(DECIMAL(38, 6), [valor_concepto])*-1 AS valor_concepto,
        CAST([fuente_primaria] AS VARCHAR(150)) AS fuente_primaria,
        CAST('SINIESTROS_GENERAL_IAXIS' AS VARCHAR(150)) AS tabla_origen
    FROM liberty_pruebas_actuaria.dbo.SINIESTROS_GENERAL_IAXIS a --------- aqui validar PU_CORREDORES_SINIESTROS
	INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.[intermediario_inicial] AND g.cia = A.[Compania]
    WHERE [periodo_contable] >= 202601 and MACRO_CONCEPTO IN ('SALVAMENTOS','RECOBROS') 

	 
	 UNION ALL


    /*SINIESTROS */
    SELECT
        CAST([Compania] AS VARCHAR(20)) AS Compania,
        TRY_CONVERT(INT, [periodo_contable]) AS periodo_contable,
        CAST([intermediario_inicial] AS VARCHAR(50)) AS intermediario_inicial,
        CAST([intermediario_final_asociado] AS VARCHAR(50)) AS intermediario_final_asociado,
        CAST([ramo_prod] AS VARCHAR(50)) AS ramo_prod,
        CAST([poliza] AS VARCHAR(80)) AS poliza,
        CAST([modalidad] AS VARCHAR(80)) AS modalidad,
        CAST([agrupador] AS VARCHAR(80)) AS agrupador,
        CAST([tipo_riesgo] AS VARCHAR(80)) AS tipo_riesgo,
        CAST([tipo_identifi_tomador] AS VARCHAR(20)) AS tipo_identifi_tomador,
        CAST([Numero_identificacion_tomador] AS VARCHAR(80)) AS Numero_identificacion_tomador,
        CAST([macro_concepto] AS VARCHAR(150)) AS macro_concepto,
        CAST([concepto] AS VARCHAR(150)) AS concepto,
        TRY_CONVERT(DECIMAL(38, 6), [valor_concepto]) AS valor_concepto,
        CAST([fuente_primaria] AS VARCHAR(150)) AS fuente_primaria,
        CAST('SINIESTROS_GENERAL_IAXIS' AS VARCHAR(150)) AS tabla_origen
    FROM liberty_pruebas_actuaria.dbo.SINIESTROS_GENERAL_IAXIS a --------- aqui validar PU_CORREDORES_SINIESTROS
	INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.[intermediario_inicial] AND g.cia = A.[Compania]
    WHERE [periodo_contable] >= 202601 and MACRO_CONCEPTO NOT IN ('SALVAMENTOS','RECOBROS') 



    UNION ALL


    /* SINIESTROS SISE */
    SELECT
        CAST([Compania] AS VARCHAR(20)) AS Compania,
        TRY_CONVERT(INT, [periodo_contable]) AS periodo_contable,
        CAST([intermediario_inicial] AS VARCHAR(50)) AS intermediario_inicial,
        CAST([intermediario_final_asociadao] AS VARCHAR(50)) AS intermediario_final_asociado,------ campo con mala escritura en la tabla 
        CAST([ramo_prod] AS VARCHAR(50)) AS ramo_prod,
        CAST([poliza] AS VARCHAR(80)) AS poliza,
        CAST([modalidad] AS VARCHAR(80)) AS modalidad,
        CAST([agrupador] AS VARCHAR(80)) AS agrupador,
        CAST([tipo_riesgo] AS VARCHAR(80)) AS tipo_riesgo,
        CAST([tipo_identifi_tomador] AS VARCHAR(20)) AS tipo_identifi_tomador,
        CAST([Numero_identificacion_tomador] AS VARCHAR(80)) AS Numero_identificacion_tomador,
        CAST([macro_concepto] AS VARCHAR(150)) AS macro_concepto,
        CAST([concepto] AS VARCHAR(150)) AS concepto,
        TRY_CONVERT(DECIMAL(38, 6), [valor_concepto]) AS valor_concepto,
        CAST([fuente_primaria] AS VARCHAR(150)) AS fuente_primaria,
        CAST('SINIESTROS_GENERAL_SISE' AS VARCHAR(150)) AS tabla_origen
    FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISE A
	INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.[intermediario_inicial] AND g.cia = A.[Compania]
    WHERE [periodo_contable] >= 202601 



    UNION ALL


    /* DEVENGADA */
    SELECT
        CAST([Compania] AS VARCHAR(20)) AS Compania,
        TRY_CONVERT(INT, [periodo_contable]) AS periodo_contable,
        CAST([intermediario_inicial] AS VARCHAR(50)) AS intermediario_inicial,
        CAST([intermediario_final] AS VARCHAR(50)) AS intermediario_final_asociado,
        CAST([ramo_prod] AS VARCHAR(50)) AS ramo_prod,
        CAST([poliza] AS VARCHAR(80)) AS poliza,
        CAST([modalidad] AS VARCHAR(80)) AS modalidad,
        CAST([agrupador] AS VARCHAR(80)) AS agrupador,
        CAST([tipo_riesgo] AS VARCHAR(80)) AS tipo_riesgo,
        CAST([TIPO_DOC_TOMADOR] AS VARCHAR(20)) AS tipo_identifi_tomador,
        CAST([DOCUMENTO_TOMADOR] AS VARCHAR(80)) AS Numero_identificacion_tomador,
        CAST([macroconcepto] AS VARCHAR(150)) AS macro_concepto,
        CAST([concepto] AS VARCHAR(150)) AS concepto,
        TRY_CONVERT(DECIMAL(38, 6), [valor_concepto]) AS valor_concepto,
        CAST([fuente_primaria] AS VARCHAR(150)) AS fuente_primaria,
        CAST('PU_CORREDORES_DEVENGADA' AS VARCHAR(150)) AS tabla_origen
    FROM liberty_pruebas_actuaria.dbo.DEVENGADA_general A
			INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.[intermediario_inicial] AND g.cia = a.[Compania]
		WHERE [periodo_contable] >= 202601


    UNION ALL


    /*FACULTATIVAS */
    
    SELECT
        CAST([Compania] AS VARCHAR(20)) AS Compania,
        TRY_CONVERT(INT, [periodo_contable]) AS periodo_contable,
        CAST([intermediario_inicial] AS VARCHAR(50)) AS intermediario_inicial,
        CAST([intermediario_final_asociado] AS VARCHAR(50)) AS intermediario_final_asociado,
        CAST([ramo_prod] AS VARCHAR(50)) AS ramo_prod,
        CAST([poliza] AS VARCHAR(80)) AS poliza,
        CAST([modalidad] AS VARCHAR(80)) AS modalidad,
        CAST([agrupador] AS VARCHAR(80)) AS agrupador,
        CAST([tipo_riesgo] AS VARCHAR(80)) AS tipo_riesgo,
        CAST([tipo_identifi_tomador] AS VARCHAR(20)) AS tipo_identifi_tomador,
        CAST([Numero_identificacion_tomador] AS VARCHAR(80)) AS Numero_identificacion_tomador,
        CAST([macro_concepto] AS VARCHAR(150)) AS macro_concepto,
        CAST([concepto] AS VARCHAR(150)) AS concepto,

        CASE
            WHEN TRY_CONVERT(DECIMAL(38, 6), [valor_concepto]) > 0
                THEN TRY_CONVERT(DECIMAL(38, 6), [valor_concepto]) * -1
            ELSE TRY_CONVERT(DECIMAL(38, 6), [valor_concepto])
        END AS valor_concepto,

        CAST([fuente_primaria] AS VARCHAR(150)) AS fuente_primaria,
        CAST('Facultativas' AS VARCHAR(150)) AS tabla_origen
    FROM [Liberty_Pruebas_Actuaria].[dbo].[Facultativas] a
	INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.[intermediario_final_asociado] AND g.cia = a.[Compania] and a.Compania = g.cia
	WHERE [periodo_contable] >= 202601
)


SELECT
    /* CAMPOS BASE DE LA FACT */
    ub.Compania,
    ub.periodo_contable,
    ub.intermediario_inicial,
    ub.intermediario_final_asociado,
    ub.ramo_prod,
    ub.poliza,
    ub.modalidad,
    ub.agrupador,
    ub.tipo_riesgo,
    ub.tipo_identifi_tomador,
    ub.Numero_identificacion_tomador,
    ub.macro_concepto,
    ub.concepto,
    ub.valor_concepto,
    ub.fuente_primaria,
    ub.tabla_origen,


    /*LLAVES TÉCNICAS PARA MODELO POWER BI*/

    /* Relación con DIM_PERIODO */
    CASE
        WHEN ub.periodo_contable IS NULL THEN 'SIN_PERIODO'
        ELSE CAST(ub.periodo_contable AS VARCHAR(20))
    END AS key_periodo,


    /* Relación con DIM_RED_COMERCIAL */
    CASE
        WHEN x.intermediario_final_asociado_clean IS NULL THEN 'SIN_RED_COMERCIAL'
        ELSE x.intermediario_final_asociado_clean
    END AS key_red_comercial,


    /* Solo diagnóstico, no usar como relación principal */
    COALESCE(
        x.intermediario_final_asociado_clean,
        x.intermediario_inicial_clean,
        'SIN_RED_COMERCIAL'
    ) AS key_red_comercial_fallback,


    /* Relación con DIM_TOMADOR */
    CASE
        WHEN x.tipo_identifi_tomador_clean IS NULL
          OR x.numero_identificacion_tomador_clean IS NULL
            THEN 'SIN_TOMADOR'
        ELSE CONCAT(
            x.tipo_identifi_tomador_clean,
            '|',
            x.numero_identificacion_tomador_clean
        )
    END AS key_tomador,


    /* Relación con DIM_RAMO */
    CASE
        WHEN x.compania_clean IS NULL
          OR x.ramo_prod_clean IS NULL
            THEN 'SIN_RAMO'
        ELSE CONCAT(
            x.compania_clean,
            '|',
            x.ramo_prod_clean
        )
    END AS key_ramo,


    /* Llave útil para póliza */
    CASE
        WHEN x.compania_clean IS NULL
          OR x.ramo_prod_clean IS NULL
          OR x.poliza_clean IS NULL
            THEN 'SIN_POLIZA'
        ELSE CONCAT(
            x.compania_clean,
            '|',
            x.ramo_prod_clean,
            '|',
            x.poliza_clean
        )
    END AS key_poliza,


    /* Relación con DIM_EXCLUSIONES, según reunión: ramo + póliza */
    CASE
        WHEN x.ramo_prod_clean IS NULL
          OR x.poliza_clean IS NULL
            THEN 'SIN_EXCLUSION'
        ELSE CONCAT(
            x.ramo_prod_clean,
            '|',
            x.poliza_clean
        )
    END AS key_exclusion,


    /* Alternativa si exclusiones llega con compañía */
    CASE
        WHEN x.compania_clean IS NULL
          OR x.ramo_prod_clean IS NULL
          OR x.poliza_clean IS NULL
            THEN 'SIN_EXCLUSION_COMPANIA'
        ELSE CONCAT(
            x.compania_clean,
            '|',
            x.ramo_prod_clean,
            '|',
            x.poliza_clean
        )
    END AS key_exclusion_compania,


    /* Relación con DIM_CONCEPTO */
    CASE
        WHEN x.macro_concepto_clean IS NULL
          AND x.concepto_clean IS NULL
            THEN 'SIN_CONCEPTO'
        ELSE CONCAT(
            COALESCE(x.macro_concepto_clean, 'SIN_MACRO_CONCEPTO'),
            '|',
            COALESCE(x.concepto_clean, 'SIN_CONCEPTO')
        )
    END AS key_concepto,


    /* Relación con DIM_FUENTE */
    CONCAT(
        COALESCE(x.tabla_origen_clean, 'SIN_TABLA_ORIGEN'),
        '|',
        COALESCE(x.fuente_primaria_clean, 'SIN_FUENTE_PRIMARIA')
    ) AS key_fuente,


    /* FLAGS Y VALORES DE APOYO */

    CASE
        WHEN x.tabla_origen_clean LIKE '%FACULTATIVA%'
          OR x.concepto_clean LIKE '%FACULT%'
            THEN 1
        ELSE 0
    END AS flag_facultativo,

    CASE
        WHEN x.tabla_origen_clean LIKE '%FACULTATIVA%'
          OR x.concepto_clean LIKE '%FACULT%'
            THEN 'Facultativo'
        ELSE 'No facultativo'
    END AS marca_facultativo,


    /* Valor sin facultativos */
    CASE
        WHEN x.tabla_origen_clean LIKE '%FACULTATIVA%'
          OR x.concepto_clean LIKE '%FACULT%'
            THEN 0
        ELSE ISNULL(ub.valor_concepto, 0)
    END AS valor_concepto_sin_facultativo,


    /* Valor facultativo separado */
    CASE
        WHEN x.tabla_origen_clean LIKE '%FACULTATIVA%'
          OR x.concepto_clean LIKE '%FACULT%'
            THEN ISNULL(ub.valor_concepto, 0)
        ELSE 0
    END AS valor_facultativo,


    /* Valor neto: conserva todo, pero facultativos ya vienen negativos */
    ISNULL(ub.valor_concepto, 0) AS valor_concepto_neto_facultativo


INTO [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo

FROM union_base ub

CROSS APPLY (
    SELECT
        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.Compania AS VARCHAR(20))))), '') AS compania_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.intermediario_inicial AS VARCHAR(50))))), '') AS intermediario_inicial_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.intermediario_final_asociado AS VARCHAR(50))))), '') AS intermediario_final_asociado_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.ramo_prod AS VARCHAR(50))))), '') AS ramo_prod_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.poliza AS VARCHAR(80))))), '') AS poliza_clean,

        CASE
            WHEN UPPER(LTRIM(RTRIM(CAST(ub.tipo_identifi_tomador AS VARCHAR(20))))) IN ('NIT', 'N') THEN 'N'
            WHEN UPPER(LTRIM(RTRIM(CAST(ub.tipo_identifi_tomador AS VARCHAR(20))))) IN ('CC', 'C', 'CEDULA', 'CÉDULA') THEN 'C'
            ELSE NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.tipo_identifi_tomador AS VARCHAR(20))))), '')
        END AS tipo_identifi_tomador_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.Numero_identificacion_tomador AS VARCHAR(80))))), '') AS numero_identificacion_tomador_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.macro_concepto AS VARCHAR(150))))), '') AS macro_concepto_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.concepto AS VARCHAR(150))))), '') AS concepto_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.fuente_primaria AS VARCHAR(150))))), '') AS fuente_primaria_clean,

        NULLIF(UPPER(LTRIM(RTRIM(CAST(ub.tabla_origen AS VARCHAR(150))))), '') AS tabla_origen_clean
) x;


/* ÍNDICES PARA POWER BI / PERFORMANCE */

CREATE CLUSTERED INDEX IX_PU_CORREDORES_UNION_01
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    periodo_contable,
    Compania,
    ramo_prod,
    poliza
);

CREATE NONCLUSTERED INDEX IX_PU_CORREDORES_UNION_RED
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    key_red_comercial
);

CREATE NONCLUSTERED INDEX IX_PU_CORREDORES_UNION_TOMADOR
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    key_tomador
);

CREATE NONCLUSTERED INDEX IX_PU_CORREDORES_UNION_RAMO
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    key_ramo
);

CREATE NONCLUSTERED INDEX IX_PU_CORREDORES_UNION_POLIZA
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    key_poliza
);

CREATE NONCLUSTERED INDEX IX_PU_CORREDORES_UNION_EXCLUSION
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    key_exclusion
);

CREATE NONCLUSTERED INDEX IX_PU_CORREDORES_UNION_CONCEPTO
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    key_concepto
);

CREATE NONCLUSTERED INDEX IX_PU_CORREDORES_UNION_FUENTE
ON [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo (
    key_fuente
);


select * from [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION
select * from [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo


SELECT * FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISE WHERE poliza= 4000059 AND RAMO_PROD = 93 AND PERIODO_CONTABLE = 202601

SELECT * FROM [Liberty_Pruebas_Actuaria].dbo.PU_CORREDORES_UNION_mayo WHERE  PERIODO_CONTABLE = 202501

SELECT * FROM Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores WHERE CLAVE_INICIAL_ASOCIADA IN (669,
76,
56)


SELECT * FROM OPENQUERY(CODWHHDI,
        'SELECT COD_INTERMEDIARIO_HDI, CANAL_HDI, COD_SUCURSAL_SUSCRIPCION_HDI, COD_INTERMEDIARIO_HOMOLOGADO
         FROM stg.excel_com_Maestro_intermediarios_Homologados') WHERE COD_INTERMEDIARIO_HDI IN (669,76,56) AND COD_INTERMEDIARIO_HOMOLOGADO = 95672
  ORDER BY COD_INTERMEDIARIO_HDI
