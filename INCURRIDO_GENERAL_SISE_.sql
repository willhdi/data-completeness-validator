/**********************************
Canal
*************************************/

drop table if exists canal;

SELECT * 
into #canal
FROM OPENQUERY(CODMHDI, '
  SELECT a.FEC_EMI,a.NRO_POL,a.COD_SUC,a.CANAL_COMERCIAL_HDI,a.CANAL_COMERCIAL,MODALIDAD,AGRUPADOR,TIPO_RIESGO
  FROM (
      SELECT ROW_NUMBER () over (partition BY NRO_POL,COD_SUC order by fec_emi desc) as ID ,CONVERT(date,FEC_EMI) as FEC_EMI,NRO_POL,COD_SUC,CANAL_COMERCIAL_HDI,CANAL_COMERCIAL, COD_PRODUCTO as MODALIDAD, COD_GRUPO AS AGRUPADOR, SEGMENTO_AUTOS AS TIPO_RIESGO
      FROM PLANEACION_RPT.dbo.PRODUCCION_COMPLETA
      WHERE AAAA_PROCESO >= ''2020''  and NRO_POL = 4000059
    ) a
  WHERE ID = 1 ')
;

--select * from #Corretaje_HDI

/******************************
TABLA CORRETAJE 
*******************************/
DROP TABLE if exists Corretaje_HDI;
SELECT * 
INTO #Corretaje_HDI
FROM OPENQUERY(CODMHDI, 'select distinct cia,cod_ramo_cial,cod_suc,NRO_POL,COD_AGENTE ,PJE_PARTIC_AGENTE,CONVERT(DATE,FEC_VIG_DESDE) AS FEC_VIG_DESDE,CONVERT(DATE,FEC_VIG_HASTA)  AS FEC_VIG_HASTA 
from PLANEACION_RPT.dbo.PRODUCCION_COMPLETA
where PJE_PARTIC_AGENTE  <> 100  and NRO_POL = 4000059 ')
;


DROP TABLE if exists #Corretaje_HDI2
select a.* 
into #Corretaje_HDI2
from (
	SELECT * from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_Sise
	--row_number() over (partition by cod_ramo_cial,NRO_POL,cod_suc,cod_agente order by fec_vig_desde desc) as id
	--FROM  liberty_pruebas_actuaria.dbo.Corretaje_HDI2
	--where NRO_POL = 4000005 and cod_ramo_cial = '88' 
	) a
--where id = 1



/**********************************

selct * from Corretaje_HDI
Liquidados
*************************************/

drop table if exists #incurrido_fusion;
select *
into #incurrido_fusion
from [Liberty_Pruebas_Actuaria].Attrition.[acc_sise_appgenerali_siniestros_incurridos_fusion]
WHERE fecha_hasta_reporte >='2025-12-01' and pliza = 4000059 --EOMONTH(GETDATE(),-1)--'2026-03-31'
;


----select top 5 * from [Liberty_Pruebas_Actuaria].Attrition.[acc_sise_appgenerali_siniestros_incurridos_fusion] where poliza = 

drop table [Liberty_Pruebas_Actuaria].dbo.incurrido_fusion_hdi_GENERAL
SELECT  * 
INTO [Liberty_Pruebas_Actuaria].dbo.incurrido_fusion_hdi_GENERAL
FROM #incurrido_fusion


/* --Validador

SELECT * FROM [Liberty_Pruebas_Actuaria].dbo.incurrido_fusion_hdi_mayo WHERE PLIZA = 4000012 AND CDIGO_RAMO_COMERCIAL = '24' AND FECHA_EMISIN

select sum(a.valor_incurrido_neto) as VALOR_CONCEPTO from #incurrido_fusion a
INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = A.cdigo_agente_principal AND g.cia = 'SISE'
where pliza = 4000068*/

---select *  from #incurrido where periodo_contable = 202601 and poliza = 4000012 and ramo_prod = 24 

drop table if exists #incurrido
SELECT 
  cast(FORMAT(a.fecha_hasta_reporte,'yyyyMM') as int) as periodo_contable
  , a.cdigo_ramo_comercial as ramo_prod
  , a.pliza as poliza
  , case
      when a.cdigo_ramo_comercial = 82 and a.compaa = 'Generales' THEN 'OTH'  
      when a.cdigo_ramo_comercial = 82 and a.compaa = 'Vida' THEN 'LIF'
      WHEN a.cdigo_ramo_comercial = 14 THEN 'HEL' 
      WHEN a.cdigo_ramo_comercial = 10 THEN 'OTH' 
      when cdigo_ramo_tcnico = 3 then 'AUT'
      WHEN compaa = 'Generales' AND cdigo_ramo_tcnico <> 3 THEN 'OTH' 
      when compaa = 'Vida' THEN 'LIF'
    END AS SBU
   , a.cdigo_agente_principal as INTERMEDIARIO_LIDE
   , a.cdigo_ramo_tcnico AS cod_profitcenter
   , a.ramo_tcnico AS desc_profitcenter
   , a.cdigo_ramo_comercial AS cod_sbu_sap
   , a.ramo_comercial AS desc_sbu_sap
   , case
        when a.tipo_estimacion in ('HONORARIOS','INDEMNIZACION','GASTOS DE INDEMNIZACION') then 'LIQUIDADOS_FUSION_BRUTO' 
        when a.tipo_estimacion in ('SALVAMENTOS','GASTOS DE SALVAMENTO') then 'LIQUIDADOS_FUSION_Salvamentos'
        when a.tipo_estimacion in ('RECOBRO','GASTOS DE RECOBRO') then 'LIQUIDADOS_FUSION_Recobros'
      end AS Concepto_nivel_3
   , 'INTERFAZ_AUT' AS Concepto_nivel_2
   , case
          when a.tipo_estimacion in ('HONORARIOS','INDEMNIZACION','GASTOS DE INDEMNIZACION') then 'INCURRIDO'
          when a.tipo_estimacion in ('SALVAMENTOS','GASTOS DE SALVAMENTO') then 'SALVAMENTOS'
          when a.tipo_estimacion in ('RECOBRO','GASTOS DE RECOBRO') then 'RECOBROS'
        end AS Concepto_nivel_1
      , 'TOTAL_CLAIMS' AS Concepto_nivel_0
	  --, Marca_corretaje
      , a.cdigo_agente_principal as COD_INTERMEDIARIO
      , case
          when a.cdigo_sucursal = 10 and nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13 then 600
          else a.cdigo_sucursal
        end as COD_SUCURSAL ---- arreglo para el negocio cotrafa
      , case
            when a.cdigo_sucursal = 10 and nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13 then 600
            else a.cdigo_sucursal
          end as Suc_cont
      , a.cdigo_sucursal as Business_Area
      , a.sucursal as Business_Area_Des
      , '' as Channel
      , coalesce(c.canal_comercial,canal_comercial_hdi) as canal_comercial
      , '0' as exc_consurso
      , c.Modalidad as MODALIDAD
      , c.Agrupador as AGRUPADOR
      , c.Tipo_riesgo AS TIPO_RIESGO
	  , sum(a.valor_incurrido) as VALOR_CONCEPTO
      --,case when d.PJE_PARTIC_AGENTE is null then sum(a.pagos_periodo) else sum(a.pagos_periodo)*d.PJE_PARTIC_AGENTE/100 end as VALOR_CONCEPTO
      --, sum((case when d.PJE_PARTIC_AGENTE is null then 100 else d.PJE_PARTIC_AGENTE end / 100) * a.pagos_periodo) as VALOR_CONCEPTO_p
      --,sum(a.pagos_periodo) as VALOR_CONCEPTO -- Fabio 2025-12-21 hice esta columna solo para confirmar valores, no se debe habilitar.
      ,a.tipo_doc_tomador as TIPO_DOC_TOMADOR
      ,a.nro_doc_tomador AS DOCUMENTO_TOMADOR
      ,a.tomador_pliza as TOMADOR
	  ,A.NMERO_SINIESTRO AS NUMERO_SINIESTRO
	  
      ,'HDI' AS COMPANIA
      --a.fecha_vig_desde_pol,
      --a.fecha_vig_hasta_pol
into #incurrido
from #incurrido_fusion a
left join #canal c on a.pliza=c.NRO_POL AND a.cdigo_sucursal = c.COD_SUC
WHERE a.fecha_hasta_reporte > '2025-12-01' ---= EOMONTH(GETDATE(),-1)--'2026-03-31'
group by a.fecha_hasta_reporte,a.cdigo_sucursal,a.nro_doc_tomador,a.cdigo_agente_principal, a.cdigo_ramo_comercial,a.compaa, a.cdigo_ramo_tcnico ,a.cdigo_agente_principal,a.ramo_tcnico,a.cdigo_ramo_comercial,a.ramo_comercial,
a.sucursal,c.CANAL_COMERCIAL,c.CANAL_COMERCIAL_HDI,a.pliza,a.tipo_estimacion,a.tipo_doc_tomador,a.nro_doc_tomador,a.tomador_pliza,
c.Modalidad,c.Agrupador,c.Tipo_riesgo,A.NMERO_SINIESTRO 
;


---------------------------------------------
drop table #incurrido_completo
SELECT 
'HDI' as Compania,
periodo_contable,
INTERMEDIARIO_LIDE as intermediario_inicial ,
CONVERT(BIGINT,b.cod_intermediario_homologado) AS intermediario_final_asociadao,
convert(int,ramo_prod) as ramo_prod,
convert(int,poliza) as poliza,
convert(int,a.MODALIDAD) as modalidad,
a.AGRUPADOR as agrupador,
a.TIPO_RIESGO as tipo_riesgo,
null as tipo_identifi_tomador,
a.DOCUMENTO_TOMADOR as Numero_identificacion_tomador,
'INCURRIDO' AS Macro_concepto,
'INCURRIDO' AS Concepto,
a.VALOR_CONCEPTO as valor_concepto,
'SISE' AS fuente_primaria
/*
periodo_contable,
INTERMEDIARIO_LIDE,
null  AS INTERMEDIARIO_CO,
SBU,
convert(int,ramo_prod) as ramo_prod,
convert(int,poliza) as poliza,
convert(int,a.MODALIDAD) as MODALIDAD,
a.AGRUPADOR,
a.TIPO_RIESGO,
b.COD_SUCURSAL_HOMOLOGADO as SUCURSAL_HOMOLOGADO,
convert(int,COD_SUCURSAL) as  COD_SUCURSAL,
a.DOCUMENTO_TOMADOR as documento,
a.TOMADOR,
null as documento_final,
null as certificado,
NUMERO_SINIESTRO,
'INCURRIDO' AS Macro_concepto,
'INCURRIDO' AS Concepto,
a.VALOR_CONCEPTO,
null as Libro,
'HDI' as CIA*/
into #incurrido_completo
from #incurrido a
left join (
    SELECT
        COD_INTERMEDIARIO_HDI,
        CANAL_HDI,
        COD_SUCURSAL_SUSCRIPCION_HDI,
        COD_INTERMEDIARIO_HOMOLOGADO
    FROM OPENQUERY(CODWHHDI,
        'SELECT COD_INTERMEDIARIO_HDI, CANAL_HDI, COD_SUCURSAL_SUSCRIPCION_HDI, COD_INTERMEDIARIO_HOMOLOGADO
         FROM stg.excel_com_Maestro_intermediarios_Homologados'
    ) ) b on  B.COD_INTERMEDIARIO_HDI  = a.INTERMEDIARIO_LIDE and b.CANAL_HDI  = a.canal_comercial  and
A.COD_SUCURSAL = b.COD_SUCURSAL_SUSCRIPCION_HDI 

--------
----corretaje de incurrido 

drop table if exists #incurrido_corretaje
SELECT 
  cast(FORMAT(a.fecha_hasta_reporte,'yyyyMM') as int) as periodo_contable
  , a.cdigo_ramo_comercial as ramo_prod
  , a.pliza as poliza
  , case
      when a.cdigo_ramo_comercial = 82 and a.compaa = 'Generales' THEN 'OTH'  
      when a.cdigo_ramo_comercial = 82 and a.compaa = 'Vida' THEN 'LIF'
      WHEN a.cdigo_ramo_comercial = 14 THEN 'HEL' 
      WHEN a.cdigo_ramo_comercial = 10 THEN 'OTH' 
      when cdigo_ramo_tcnico = 3 then 'AUT'
      WHEN compaa = 'Generales' AND cdigo_ramo_tcnico <> 3 THEN 'OTH' 
      when compaa = 'Vida' THEN 'LIF'
    END AS SBU
   , a.cdigo_agente_principal as INTERMEDIARIO_LIDE
   , a.cdigo_ramo_tcnico AS cod_profitcenter
   , a.ramo_tcnico AS desc_profitcenter
   , a.cdigo_ramo_comercial AS cod_sbu_sap
   , a.ramo_comercial AS desc_sbu_sap
   , case
        when a.tipo_estimacion in ('HONORARIOS','INDEMNIZACION','GASTOS DE INDEMNIZACION') then 'LIQUIDADOS_FUSION_BRUTO' 
        when a.tipo_estimacion in ('SALVAMENTOS','GASTOS DE SALVAMENTO') then 'LIQUIDADOS_FUSION_Salvamentos'
        when a.tipo_estimacion in ('RECOBRO','GASTOS DE RECOBRO') then 'LIQUIDADOS_FUSION_Recobros'
      end AS Concepto_nivel_3
   , 'INTERFAZ_AUT' AS Concepto_nivel_2
   , case
          when a.tipo_estimacion in ('HONORARIOS','INDEMNIZACION','GASTOS DE INDEMNIZACION') then 'INCURRIDO'
          when a.tipo_estimacion in ('SALVAMENTOS','GASTOS DE SALVAMENTO') then 'SALVAMENTOS'
          when a.tipo_estimacion in ('RECOBRO','GASTOS DE RECOBRO') then 'RECOBROS'
        end AS Concepto_nivel_1
      , 'TOTAL_CLAIMS' AS Concepto_nivel_0
	  --, Marca_corretaje
      , a.cdigo_agente_principal as COD_INTERMEDIARIO
      , case
          when a.cdigo_sucursal = 10 and nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13 then 600
          else a.cdigo_sucursal
        end as COD_SUCURSAL ---- arreglo para el negocio cotrafa
      , case
            when a.cdigo_sucursal = 10 and nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13 then 600
            else a.cdigo_sucursal
          end as Suc_cont
      , a.cdigo_sucursal as Business_Area
      , a.sucursal as Business_Area_Des
      , '' as Channel
      , coalesce(c.canal_comercial,canal_comercial_hdi) as canal_comercial
      , '0' as exc_consurso
      , c.Modalidad as MODALIDAD
      , c.Agrupador as AGRUPADOR
      , c.Tipo_riesgo AS TIPO_RIESGO
	  , sum(a.valor_incurrido) as VALOR_CONCEPTO
      --,case when d.PJE_PARTIC_AGENTE is null then sum(a.pagos_periodo) else sum(a.pagos_periodo)*d.PJE_PARTIC_AGENTE/100 end as VALOR_CONCEPTO
      --, sum((case when d.PJE_PARTIC_AGENTE is null then 100 else d.PJE_PARTIC_AGENTE end / 100) * a.pagos_periodo) as VALOR_CONCEPTO_p
      --,sum(a.pagos_periodo) as VALOR_CONCEPTO -- Fabio 2025-12-21 hice esta columna solo para confirmar valores, no se debe habilitar.
      ,a.tipo_doc_tomador as TIPO_DOC_TOMADOR
      ,a.nro_doc_tomador AS DOCUMENTO_TOMADOR
      ,a.tomador_pliza as TOMADOR
	  ,A.NMERO_SINIESTRO AS NUMERO_SINIESTRO
	  
      ,'HDI' AS COMPANIA,
      a.fecha_vig_desde_endo,
      a.fecha_hasta_desde_endo
into #incurrido_corretaje
from #incurrido_fusion a
left join #canal c on a.pliza=c.NRO_POL AND a.cdigo_sucursal = c.COD_SUC
WHERE a.fecha_hasta_reporte > '2025-12-01' ---= EOMONTH(GETDATE(),-1)--'2026-03-31'
group by a.fecha_hasta_reporte,a.cdigo_sucursal,a.nro_doc_tomador,a.cdigo_agente_principal, a.cdigo_ramo_comercial,a.compaa, a.cdigo_ramo_tcnico ,a.cdigo_agente_principal,a.ramo_tcnico,a.cdigo_ramo_comercial,a.ramo_comercial,
a.sucursal,c.CANAL_COMERCIAL,c.CANAL_COMERCIAL_HDI,a.pliza,a.tipo_estimacion,a.tipo_doc_tomador,a.nro_doc_tomador,a.tomador_pliza,
c.Modalidad,c.Agrupador,c.Tipo_riesgo,A.NMERO_SINIESTRO 
;


---------------------------------------------
drop table #incurrido_corretaje_completo
SELECT 
'HDI' as Compania,
periodo_contable,
b.cod_agente as intermediario_inicial ,
CONVERT(BIGINT,b.cod_intermediario_homologado) AS intermediario_final_asociadao,
convert(int,ramo_prod) as ramo_prod,
convert(int,poliza) as poliza,
convert(int,a.MODALIDAD) as modalidad,
a.AGRUPADOR as agrupador,
a.TIPO_RIESGO as tipo_riesgo,
null as tipo_identifi_tomador,
a.DOCUMENTO_TOMADOR as Numero_identificacion_tomador,
'INCURRIDO_CO-corretaje' AS Macro_concepto,
'INCURRIDO' AS Concepto,
sum(a.VALOR_CONCEPTO)*d.PJE_PARTIC_AGENTE/100  as valor_concepto,
'SISE' AS fuente_primaria
/*
periodo_contable,
INTERMEDIARIO_LIDE,
null  AS INTERMEDIARIO_CO,
SBU,
convert(int,ramo_prod) as ramo_prod,
convert(int,poliza) as poliza,
convert(int,a.MODALIDAD) as MODALIDAD,
a.AGRUPADOR,
a.TIPO_RIESGO,
b.COD_SUCURSAL_HOMOLOGADO as SUCURSAL_HOMOLOGADO,
convert(int,COD_SUCURSAL) as  COD_SUCURSAL,
a.DOCUMENTO_TOMADOR as documento,
a.TOMADOR,
null as documento_final,
null as certificado,
NUMERO_SINIESTRO,
'INCURRIDO' AS Macro_concepto,
'INCURRIDO' AS Concepto,
a.VALOR_CONCEPTO,
null as Libro,
'HDI' as CIA*/
into #incurrido_corretaje_completo
from #incurrido_corretaje a

INNER join #Corretaje_HDI2 d on (a.COD_SUCURSAL = d.cod_suc and a.ramo_prod =d.cod_ramo_cial and a.poliza = d.nro_pol and a.fecha_vig_desde_endo >= d.fec_vig_desde and a.fecha_vig_hasta_endo <=d.fec_vig_hasta )
left join (
    SELECT
        COD_INTERMEDIARIO_HDI,
        CANAL_HDI,
        COD_SUCURSAL_SUSCRIPCION_HDI,
        COD_INTERMEDIARIO_HOMOLOGADO
    FROM OPENQUERY(CODWHHDI,
        'SELECT COD_INTERMEDIARIO_HDI, CANAL_HDI, COD_SUCURSAL_SUSCRIPCION_HDI, COD_INTERMEDIARIO_HOMOLOGADO
         FROM stg.excel_com_Maestro_intermediarios_Homologados'
    ) ) b on  B.COD_INTERMEDIARIO_HDI  = b.cod_agente  and b.CANAL_HDI  = a.canal_comercial  and
A.COD_SUCURSAL = b.COD_SUCURSAL_SUSCRIPCION_HDI 

-----------------------------------------------------------------------




drop table #incurrido_reaseguro

SELECT 
cast(FORMAT(a.fecha_hasta_reporte,'yyyyMM') as int) as periodo_contable,
a.cdigo_ramo_comercial as ramo_prod,
a.pliza as poliza,
case when a.cdigo_ramo_comercial = 82 and a.compaa = 'Generales' THEN 'OTH'	
     when a.cdigo_ramo_comercial = 82 and a.compaa = 'Vida' THEN 'LIF'
	 WHEN a.cdigo_ramo_comercial = 14 THEN 'HEL' 
	 WHEN a.cdigo_ramo_comercial = 10 THEN 'OTH' 
	 when cdigo_ramo_tcnico = 3 then 'AUT'
	 WHEN compaa = 'Generales' AND cdigo_ramo_tcnico <> 3 THEN 'OTH' 
	 when compaa = 'Vida' THEN 'LIF'
END AS SBU,
a.cdigo_agente_principal as INTERMEDIARIO_LIDE,
a.cdigo_ramo_tcnico AS cod_profitcenter,
a.ramo_tcnico AS desc_profitcenter,
a.cdigo_ramo_comercial AS cod_sbu_sap,
a.ramo_comercial AS desc_sbu_sap,
'INCURRIDO_FUSION_REASEGURO' AS Concepto_nivel_3,
'INTERFAZ_AUT' AS Concepto_nivel_2,
'SINIESTROS_LIQUIDADOS_REASEGURO' AS Concepto_nivel_1,
'TOTAL_CLAIMS' AS Concepto_nivel_0,
case when a.cdigo_sucursal = 10 and  nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13  then 600 else a.cdigo_sucursal end as COD_SUCURSAL, ---- arreglo para el negocio cotrafa
case when a.cdigo_sucursal = 10 and  nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13  then 600 else a.cdigo_sucursal end as Suc_cont,
a.cdigo_sucursal as Business_Area,
a.sucursal as Business_Area_Des,
'' as Channel,
coalesce(c.canal_comercial,canal_comercial_hdi) as canal_comercial,
'0' as exc_consurso,
       c.Modalidad as MODALIDAD
      , c.Agrupador as AGRUPADOR
      , c.Tipo_riesgo AS TIPO_RIESGO,
--case when d.PJE_PARTIC_AGENTE is null then sum(a.valor_incurrido) else sum(a.valor_incurrido)*d.PJE_PARTIC_AGENTE/100 end as VALOR_CONCEPTO,
--a.valor_incurrido - a.valor_incurrido_neto as VALOR_CONCEPTO,
sum(a.pagos_periodo - a.pagos_periodo_neto)*-1 as VALOR_CONCEPTO,
a.tipo_doc_tomador as TIPO_DOC_TOMADOR,
a.nro_doc_tomador AS DOCUMENTO_TOMADOR,
a.tomador_pliza as TOMADOR,
'HDI' AS COMPANIA,
A.NMERO_SINIESTRO  AS NUMERO_SINIESTRO
into #incurrido_reaseguro
from #incurrido_fusion a
left join #canal c on a.pliza=c.NRO_POL AND a.cdigo_sucursal = c.COD_SUC
WHERE a.fecha_hasta_reporte >= '2025-12-31' /*EOMONTH(GETDATE(),-1)*/  AND a.tipo_estimacion in ('HONORARIOS','INDEMNIZACION','GASTOS DE INDEMNIZACION')
group by a.fecha_hasta_reporte,a.cdigo_sucursal,a.nro_doc_tomador,a.cdigo_agente_principal, a.cdigo_ramo_comercial,a.compaa, a.cdigo_ramo_tcnico ,a.cdigo_agente_principal,a.ramo_tcnico,a.cdigo_ramo_comercial,a.ramo_comercial,
a.sucursal,c.CANAL_COMERCIAL,c.CANAL_COMERCIAL_HDI,a.pliza,a.tipo_estimacion,a.tipo_doc_tomador,a.nro_doc_tomador,a.tomador_pliza,
  a.fecha_vig_desde_pol,
  a.fecha_vig_hasta_pol,c.Modalidad,c.Agrupador,c.Tipo_riesgo,A.NMERO_SINIESTRO 


------------------



DROP TABLE #incurrido_reaseguro_completo
SELECT 

'HDI' as Compania,
periodo_contable,
INTERMEDIARIO_LIDE as intermediario_inicial ,
CONVERT(BIGINT,b.cod_intermediario_homologado) AS intermediario_final_asociadao,
convert(int,ramo_prod) as ramo_prod,
convert(int,poliza) as poliza,
convert(int,a.MODALIDAD) as modalidad,
a.AGRUPADOR as agrupador,
a.TIPO_RIESGO as tipo_riesgo,
null as tipo_identifi_tomador,
a.DOCUMENTO_TOMADOR as Numero_identificacion_tomador,
--'INCURRIDO_REASEGURO' AS Macro_concepto,
'INCURRIDO' AS Macro_concepto,
'SINIESTROS_LIQUIDADOS_REASEGURO' AS Concepto,
a.VALOR_CONCEPTO as valor_concepto,
'SISE' AS fuente_primaria

/*
periodo_contable,
INTERMEDIARIO_LIDE,
null AS INTERMEDIARIO_CO,
SBU,
convert(int,ramo_prod) as ramo_prod,
convert(int,poliza) as poliza,
convert(int,a.MODALIDAD) as MODALIDAD,
a.AGRUPADOR,
a.TIPO_RIESGO,
b.COD_SUCURSAL_HOMOLOGADO as SUCURSAL_HOMOLOGADO,
convert(int,COD_SUCURSAL) as  COD_SUCURSAL,
a.DOCUMENTO_TOMADOR as documento,
a.TOMADOR,
null as documento_final,
null as certificado,
NUMERO_SINIESTRO,
'INCURRIDO_REASEGURO' AS Macro_concepto,
'SINIESTROS_LIQUIDADOS_REASEGURO' AS Concepto,
a.VALOR_CONCEPTO,
null as Libro,
'HDI' as CIA*/

into #incurrido_reaseguro_completo
from #incurrido_reaseguro a
left join (
    SELECT
        COD_INTERMEDIARIO_HDI,
        CANAL_HDI,
        COD_SUCURSAL_SUSCRIPCION_HDI,
        COD_INTERMEDIARIO_HOMOLOGADO
    FROM OPENQUERY(CODWHHDI,
        'SELECT COD_INTERMEDIARIO_HDI, CANAL_HDI, COD_SUCURSAL_SUSCRIPCION_HDI, COD_INTERMEDIARIO_HOMOLOGADO
         FROM stg.excel_com_Maestro_intermediarios_Homologados'
    ) ) b on  B.COD_INTERMEDIARIO_HDI  = a.INTERMEDIARIO_LIDE and b.CANAL_HDI  = a.canal_comercial  and
A.COD_SUCURSAL = b.COD_SUCURSAL_SUSCRIPCION_HDI 
---INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = A.INTERMEDIARIO_LIDE AND g.cia = 'SISE';




-----------------------------------------------------------------------



drop table #incurrido_reaseguro_corretaje

SELECT 
cast(FORMAT(a.fecha_hasta_reporte,'yyyyMM') as int) as periodo_contable,
a.cdigo_ramo_comercial as ramo_prod,
a.pliza as poliza,
case when a.cdigo_ramo_comercial = 82 and a.compaa = 'Generales' THEN 'OTH'	
     when a.cdigo_ramo_comercial = 82 and a.compaa = 'Vida' THEN 'LIF'
	 WHEN a.cdigo_ramo_comercial = 14 THEN 'HEL' 
	 WHEN a.cdigo_ramo_comercial = 10 THEN 'OTH' 
	 when cdigo_ramo_tcnico = 3 then 'AUT'
	 WHEN compaa = 'Generales' AND cdigo_ramo_tcnico <> 3 THEN 'OTH' 
	 when compaa = 'Vida' THEN 'LIF'
END AS SBU,
a.cdigo_agente_principal as INTERMEDIARIO_LIDE,
a.cdigo_ramo_tcnico AS cod_profitcenter,
a.ramo_tcnico AS desc_profitcenter,
a.cdigo_ramo_comercial AS cod_sbu_sap,
a.ramo_comercial AS desc_sbu_sap,
'INCURRIDO_CORRETAJE' AS Concepto_nivel_3,
'INCURRIDO_CORRTEJAE' AS Concepto_nivel_2,
'Siniestros_incurrido_reaseguro_CO-Corretaje' AS Concepto_nivel_1,
'INCURRIDO_CORRTEJAE' AS Concepto_nivel_0,
CASE WHEN d.PARTICIPACION is not null then 1 else 0 END as Marca_corretaje,
a.cdigo_agente_principal as COD_INTERMEDIARIO,
d.COD_AGENTE AS COD_AGENTE_COCO,
case when d.PARTICIPACION is null then 100 else d.PARTICIPACION end as PARTICIPACION,
case when a.cdigo_sucursal = 10 and  nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13  then 600 else a.cdigo_sucursal end as COD_SUCURSAL, ---- arreglo para el negocio cotrafa
case when a.cdigo_sucursal = 10 and  nro_doc_tomador = 890901176 and a.cdigo_agente_principal in (4001203,759) AND a.cdigo_ramo_comercial = 13  then 600 else a.cdigo_sucursal end as Suc_cont,
a.cdigo_sucursal as Business_Area,
a.sucursal as Business_Area_Des,
'' as Channel,
coalesce(c.canal_comercial,canal_comercial_hdi) as canal_comercial,
'0' as exc_consurso,
       c.Modalidad as MODALIDAD
      , c.Agrupador as AGRUPADOR
      , c.Tipo_riesgo AS TIPO_RIESGO,
--case when d.PJE_PARTIC_AGENTE is null then sum(a.valor_incurrido) else sum(a.valor_incurrido)*d.PJE_PARTIC_AGENTE/100 end as VALOR_CONCEPTO,
--a.valor_incurrido - a.valor_incurrido_neto as VALOR_CONCEPTO,
case when d.PARTICIPACION is null THEN a.pagos_periodo - a.pagos_periodo_neto ELSE (a.pagos_periodo - a.pagos_periodo_neto)*d.PARTICIPACION/100 end as VALOR_CONCEPTO,
a.tipo_doc_tomador as TIPO_DOC_TOMADOR,
a.nro_doc_tomador AS DOCUMENTO_TOMADOR,
a.tomador_pliza as TOMADOR,
'HDI' AS COMPANIA,
A.NMERO_SINIESTRO  AS NUMERO_SINIESTRO
into #incurrido_reaseguro_corretaje
from #incurrido_fusion a
left join #canal c on a.pliza=c.NRO_POL AND a.cdigo_sucursal = c.COD_SUC
INNER join #Corretaje_HDI2 d on (a.cdigo_sucursal = d.cod_suc and a.cdigo_ramo_comercial =d.cod_ramo_cial and a.pliza = d.nro_pol and a.fecha_vig_desde_endo >= d.fec_vig_desde and a.fecha_vig_hasta_endo <=d.fec_vig_hasta )
WHERE a.fecha_hasta_reporte > '2025-12-31' --- EOMONTH(GETDATE(),-1) ;  

----select * from #Corretaje_HDI2

------------------






DROP TABLE #incurrido_reaseguro_corretaje_completo
SELECT 
'HDI' as Compania,
periodo_contable,
--INTERMEDIARIO_LIDE as intermediario_inicial ,
CASE WHEN PARTICIPACION = 100 THEN COD_INTERMEDIARIO ELSE COD_AGENTE_COCO END  AS  intermediario_inicial,
CONVERT(BIGINT,b.cod_intermediario_homologado) as intermediario_final_asociadao, ---- se ajusta cambiado la lider por la asociada de la red de homologacion - 26-05-2026
convert(int,ramo_prod) as ramo_prod,
convert(int,poliza) as poliza,
convert(int,a.MODALIDAD) as modalidad,
a.AGRUPADOR as agrupador,
a.TIPO_RIESGO as tipo_riesgo,
null as tipo_identifi_tomador,
a.DOCUMENTO_TOMADOR as Numero_identificacion_tomador,
--'Siniestros_incurrido' AS Macro_concepto,
'INCURRIDO' AS Macro_concepto,
'Siniestros_incurrido_CO-Corretaje' AS Concepto,
a.VALOR_CONCEPTO as valor_concepto,
'SISE' AS fuente_primaria
/*
SBU,
b.COD_SUCURSAL_HOMOLOGADO as SUCURSAL_HOMOLOGADO,
convert(int,COD_SUCURSAL) as  COD_SUCURSAL,
--a.TOMADOR,
null as documento_final,
null as certificado,
NUMERO_SINIESTRO,
null as Libro,*/
into #incurrido_reaseguro_corretaje_completo
from #incurrido_reaseguro_corretaje a
left join (
    SELECT
        COD_INTERMEDIARIO_HDI,
        CANAL_HDI,
        COD_SUCURSAL_SUSCRIPCION_HDI,
        COD_INTERMEDIARIO_HOMOLOGADO
    FROM OPENQUERY(CODWHHDI,
        'SELECT COD_INTERMEDIARIO_HDI, CANAL_HDI, COD_SUCURSAL_SUSCRIPCION_HDI, COD_INTERMEDIARIO_HOMOLOGADO
         FROM stg.excel_com_Maestro_intermediarios_Homologados'
    ) ) b on  B.COD_INTERMEDIARIO_HDI  = a.COD_AGENTE_COCO and b.CANAL_HDI  = a.canal_comercial  and
A.COD_SUCURSAL = b.COD_SUCURSAL_SUSCRIPCION_HDI 
---INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = A.INTERMEDIARIO_LIDE AND g.cia = 'SISE';


DROP TABLE #Incurrido_sise_completa
SELECT *
into #Incurrido_sise_completa
FROM 
(select * from #incurrido_completo 
union all
select * from #incurrido_corretaje_completo
union all 
select * from #incurrido_reaseguro_completo 
union all 
select * from #incurrido_corretaje_completo 
)x



DROP TABLE [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISE

---insert into PU_CORREDORES_SINIESTROS_SISE
select * 
into [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISE
from #Incurrido_sise_completa 
where valor_concepto <> 0





------ final codigo ----



select Compania,
periodo_contable,
intermediario_inicial,
CONVERT(BIGINT, intermediario_final_asociadao) as intermediario_final_asociadao,
ramo_prod,
poliza,
modalidad,
agrupador,
tipo_riesgo,
tipo_identifi_tomador,
Numero_identificacion_tomador,
Macro_concepto,
Concepto,
valor_concepto,
fuente_primaria
into PU_CORREDORES_SINIESTROS_SISE
 from #PU_CORREDORES_SINIESTROS_SISE




select SUM(valor_concepto)  from [Liberty_Pruebas_Actuaria].[dbo].PU_CORREDORES_SINIESTROS_SISE
where intermediario_inicial = 669 and POLIZA= 4000012 AND
periodo_coNtable = 202601 and compania = 'HDI'
group by Concepto 

select * from #incurrido_completo where periodo_contable = 202601 and poliza = 4000012 and ramo_prod = 24 



    SELECT
        COD_INTERMEDIARIO_HDI,
        CANAL_HDI,
        COD_SUCURSAL_SUSCRIPCION_HDI,
        COD_INTERMEDIARIO_HOMOLOGADO
    FROM OPENQUERY(CODWHHDI,
        'SELECT COD_INTERMEDIARIO_HDI, CANAL_HDI, COD_SUCURSAL_SUSCRIPCION_HDI, COD_INTERMEDIARIO_HOMOLOGADO
         FROM stg.excel_com_Maestro_intermediarios_Homologados') where cod_intermediario_hdi = 669






		 select SUM(VR_NOVEDAD) from liberty.[SINI].[DWH_S_NOV_CONT_D] where poliza = 8650 and periodo_contable = 202601 and TIPO_NOVEDAD not in (5,6)

		 		 select * from Liberty.PROD.DWH_POLIZAS_h where poliza = 8650 and periodo_contable >= 202501