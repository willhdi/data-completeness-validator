/********************
SALVAMENTOS AS400
*********************/

USE Liberty_Pruebas_Actuaria


declare
@periodo_contable varchar(6)=202512


if OBJECT_ID('tempdb.dbo.#salvamentos_As400','U') is not null drop table #salvamentos_as400

select 
DTPEKN	AS  PERIODO_CONTABLE
,DTITCG AS	INTERMEDIARIO_LIDE
,DTITCG AS	INTERMEDIARIO_LIDE_CO
,d.sbu
,DTRACG AS 	RAMO_PROD
,DTPZNU AS	POLIZA
,null as modalidad
,null as Agrupador
,null as tipo_riesgo
,DTSCLD	as  SUCURSAL_PROD
,DTSCNU AS  cod_sucursal
,DTDCNU AS	DOCUMENTO
,DTDCNU AS	DOCUMENTO_FINAL
,DTCTNU AS	CERTIFICADO
,DTRCNU AS	NRO_RADC_SINIESTRO
,DTTDNT AS  NIT_TOMADOR
,'SALVAMENTOS' AS Macro_concepto
,'Salvamentos_As400' as Concepto
,DTVRPO as VALOR_CONCEPTO
,'[AS400].[REFIGVDT]' as fuente_primaria
into #salvamentos_As400
from liberty.[AS400].[REFIGVDT] A
----INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.DTITCG AND g.cia = 'IAXIS'
left join liberty.apoyo.dwh_sbu_ramo_prod d on a.DTRACG = d.ramo_prod 
where DTPEKN >= @periodo_contable AND DTTNNU IN (30)

union all 

select 
DTPEKN	AS  PERIODO_CONTABLE
,DTITCG AS	INTERMEDIARIO_LIDE
,c.AGENTE AS	INTERMEDIARIO_LIDE_CO
,d.sbu
,DTRACG AS 	RAMO_PROD
,DTPZNU AS	POLIZA
,null as modalidad
,null as Agrupador
,null as tipo_riesgo
,DTSCLD	as  SUCURSAL_PROD
,DTSCNU AS  cod_sucursal
,DTDCNU AS	DOCUMENTO
,DTDCNU AS	DOCUMENTO_FINAL
,DTCTNU AS	CERTIFICADO
,DTRCNU AS	numero_siniestro
,DTTDNT AS  NIT_TOMADOR
,'SALVAMENTOS' AS Macro_concepto
,'Salvamentos_As400_Corretaje' as Concepto
,DTVRPO*(c.participacion/100) as VALOR_CONCEPTO
,'[AS400].[REFIGVDT]' as fuente_primaria
 from liberty.[AS400].[REFIGVDT] A
---INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.DTITCG AND g.cia = 'IAXIS'
INNER join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis c on (a.DTRACG =  c.RAMO_PROD AND a.DTPZNU=c.POLIZA and a.DTCTNU=c.certificado AND a.DTDCNU=c.DOCUMENTO_PRIMA)
left join liberty.apoyo.dwh_sbu_ramo_prod d on a.DTRACG = d.ramo_prod 
where DTPEKN >= @periodo_contable AND DTTNNU IN (30)

/********************
SALVAMENTOS IAXIS
*********************/

drop table #salvamentos_iaxis
select 
substring(cast(IVFECI as varchar(8)),0,7) AS PERIODO_CONTABLE
,IVCLVI as Intermediario_lide
,IVCLVI as Intermediario_lide_co
,d.sbu
,IVRAMO as ramo_prod
,b.poliza
,null as modalidad
,null as Agrupador
,null as tipo_riesgo
,IVSUCL as sucursal_prod
,IVSUCL as cod_sucursal
,b.documento
,b.documento as documento_final
,b.certificado as certificado
,IVNRSI as numero_siniestro
,IVTIDT as Tipo_Identi_Tomador
,IVIDTO as Identificacion_Tomador
,'SALVAMENTOS' AS Macro_concepto
,'Salvamentos_IAXIS' as Concepto
,IVVRIV AS VALOR_CONCEPTO
,'[AS400].[F590475]' as fuente_primaria
into #salvamentos_iaxis
from liberty.[AS400].[F590475] a
---INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA =a.IVCLVI AND g.cia = 'IAXIS'
left join liberty.apoyo.dwh_sbu_ramo_prod d on a.IVRAMO = d.ramo_prod 
left join (select radicacion,poliza,certificado,documento,intermediario_lide, ramo_prod, sucursal_prod,count(*) as conteo from liberty.sini.dwh_s_maestro_d
			group by radicacion,poliza,certificado,documento,intermediario_lide, ramo_prod, sucursal_prod) b on a.IVNRSI = b.RADICACION and a.IVSUCL = SUCURSAL_PROD and a.IVCLVI=INTERMEDIARIO_LIDE and a.IVRAMO=b.ramo_prod
where substring(cast(IVFECI as varchar(8)),0,7) >= @periodo_contable and IVCTIV IN (530) 


drop table #salvamentos_iaxis_co
select 
a.PERIODO_CONTABLE
,a.Intermediario_lide
,c.agente as Intermediario_lide_co
,a.sbu	
,a.ramo_prod
,a.poliza
,a.modalidad
,a.Agrupador
,a.tipo_riesgo
,a.sucursal_prod
,a.cod_sucursal
,a.documento
,a.documento_final
,a.certificado
,a.numero_siniestro
,a.Tipo_Identi_Tomador
,a.Identificacion_Tomador
,a.Macro_concepto
,'Salvamentos_IAXIS_corretaje' as Concepto
,a.VALOR_CONCEPTO*(c.participacion/100) as VALOR_CONCEPTO
,a.fuente_primaria
into #salvamentos_iaxis_co
from #salvamentos_iaxis a
INNER join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis c on a.ramo_prod =  c.RAMO_PROD AND a.poliza=c.POLIZA and a.certificado=c.certificado AND a.documento=c.DOCUMENTO_PRIMA

/**********************
INSERT PU_CPOREDORES_SINIESTROS
**********************/
select 
'HDISC' AS COMPANIA
,PERIODO_CONTABLE
,Intermediario_lide	AS intermediario_inicial
,Intermediario_lide_co as itermediario_final_asociadao

,ramo_prod
,poliza	
,modalidad
,Agrupador
,tipo_riesgo	
,Tipo_Identi_Tomador as tipo_identifi_tomador	
,Identificacion_Tomador as Numero_identificacion_tomador
,Macro_concepto	
,Concepto	
,SUM(VALOR_CONCEPTO) AS VALOR_CONCEPTO
,fuente_primaria
INTO #SALVAMENTOS_COMPLETO
from #salvamentos_iaxis
GROUP BY 
PERIODO_CONTABLE
,Intermediario_lide	
,Intermediario_lide_co

,ramo_prod
,poliza	
,modalidad
,Agrupador
,tipo_riesgo	
,Tipo_Identi_Tomador	
,Identificacion_Tomador
,Macro_concepto	
,Concepto	
,fuente_primaria

union all

select 
'HDISC' AS COMPANIA
,PERIODO_CONTABLE
,Intermediario_lide	AS intermediario_inicial
,Intermediario_lide_co as itermediario_final_asociadao

,ramo_prod
,poliza	
,modalidad
,Agrupador
,tipo_riesgo	
,Tipo_Identi_Tomador as tipo_identifi_tomador
,Identificacion_Tomador as Numero_identificacion_tomador
,Macro_concepto	
,Concepto	
,SUM(VALOR_CONCEPTO) AS VALOR_CONCEPTO
,fuente_primaria
from #salvamentos_iaxis_co
GROUP BY 
PERIODO_CONTABLE
,Intermediario_lide	
,Intermediario_lide_co  

,ramo_prod
,poliza	
,modalidad
,Agrupador
,tipo_riesgo	
,Tipo_Identi_Tomador	
,Identificacion_Tomador
,Macro_concepto	
,Concepto	
,fuente_primaria


UNION ALL 

SELECT
'HDISC' AS COMPANIA
,PERIODO_CONTABLE
,Intermediario_lide	AS intermediario_inicial
,Intermediario_lide_co as itermediario_final_asociadao

,ramo_prod
,poliza	
,modalidad
,Agrupador
,tipo_riesgo	
,NULL as tipo_identifi_tomador
,NIT_TOMADOR as Numero_identificacion_tomador
,Macro_concepto	
,Concepto	
,SUM(VALOR_CONCEPTO) AS VALOR_CONCEPTO
,fuente_primaria
FROM #salvamentos_As400
GROUP BY 
PERIODO_CONTABLE
,Intermediario_lide	
,Intermediario_lide_co

,ramo_prod
,poliza	
,modalidad
,Agrupador
,tipo_riesgo	
,NIT_TOMADOR
,Macro_concepto	
,Concepto	
,fuente_primaria



INSERT INTO liberty_pruebas_actuaria.dbo.SINIESTROS_GENERAL_IAXIS 

SELECT * FROM #SALVAMENTOS_COMPLETO



---- finalll --- 
SELECT * FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS where concepto = 'Salvamentos_IAXIS' ORDER BY poliza

/*
DELETE FROM  [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS
WHERE MACRO_Concepto = 'RECOBROS'
*/
/******************************
MODALIDAD HDISC OTH - AJUSTADO 
*******************************/
DROP  TABLE #TABLA_MODALIDADES_OTH

SELECT DISTINCT SSEGURO,A.RAMO_PROD,POLIZA,MAX( A.COD_MODALIDAD)  AS MODALIDAD
INTO #TABLA_MODALIDADES_OTH
FROM  Liberty.prod.dwh_polizas_h A 
left join Liberty.APOYO.DWH_SBU_RAMO_PROD B ON (A.RAMO_PROD=B.RAMO_PROD)
WHERE B.SBU='OTH' AND PERIODO_CONTABLE>=202001 AND A.COD_MODALIDAD>=1
GROUP BY SSEGURO,A.RAMO_PROD,POLIZA


UPDATE a 
SET MODALIDAD	 = b.MODALIDAD
from [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS a
left join #TABLA_MODALIDADES_OTH b on a.poliza = b.poliza
where /*a.SBU = 'OTH'  AND*/ Macro_concepto = 'SALVAMENTOS'
AND COMPANIA = 'HDISC'


UPDATE a 
SET MODALIDAD = 0
from [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS  a
where /*a.SBU = 'OTH'  AND */Macro_concepto = 'SALVAMENTOS'
AND COMPANIA = 'HDISC' AND modalidad IS NULL




/***************************
MODALIDAD AUTOS HDISC - AJUSTAR
****************************/
DROP  TABLE #TABLA_MODALIDADES_AUT

SELECT DISTINCT SSEGURO,A.RAMO_PROD,POLIZA,MAX(A.COD_MODALIDAD) AS MODALIDAD
INTO #TABLA_MODALIDADES_AUT
FROM  Liberty.prod.dwh_polizas_h A 
left join Liberty.APOYO.DWH_SBU_RAMO_PROD B ON (A.RAMO_PROD=B.RAMO_PROD)
WHERE B.SBU='AUT' AND PERIODO_CONTABLE>=202001 AND A.COD_MODALIDAD>=1
GROUP BY SSEGURO,A.RAMO_PROD,POLIZA


UPDATE a 
SET MODALIDAD	 = b.MODALIDAD
FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS  a
left join #TABLA_MODALIDADES_AUT b on a.poliza = b.poliza
where /*a.SBU = 'AUT'  AND*/ Macro_concepto = 'SALVAMENTOS'
 AND COMPANIA = 'HDISC'



UPDATE a 
SET MODALIDAD	 = case when trim(RAMO_PROD) in ('6031', '6032','6033','6035','6036','6060','6061','AL','AU','AX','CT','PM','LM','6041','6042','6045','LO','LF','AT','AW','ET') THEN 1
						when trim(RAMO_PROD) in ('900792','6039','6047','6049','PO','PE','TP','800004') THEN 2
						when trim(RAMO_PROD) in ('6034','MT','MU','ME','MW','6043','6048','MO','MF') THEN 3
						when trim(RAMO_PROD) in ( '6038', '6046','TO','TT','TS','TU') THEN 4
					else  modalidad end
FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS  a
where /*a.SBU = 'AUT'   AND*/ Macro_concepto = 'SALVAMENTOS'
AND COMPANIA = 'HDISC'


UPDATE a 
SET MODALIDAD = 0
from [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS  a
where a.compania = 'HDISC' /*and a.SBU = 'AUT'*/ and MODALIDAD is null AND Macro_concepto = 'SALVAMENTOS'



/**********************
TIPO RIESGO
***********************/
UPDATE a 
SET TIPO_RIESGO	 = case when trim(RAMO_PROD) in ('6031', '6032','6033','6035','6036','6060','6061','AL','AU','AX','CT','PM','LM','6041','6042','6045','LO','LF','AT','AW','ET') THEN 1
						when trim(RAMO_PROD) in ('900792','6039','6047','6049','PO','PE','TP','800004') THEN 2
						when trim(RAMO_PROD) in ('6034','MT','MU','ME','MW','6043','6048','MO','MF') THEN 3
						when trim(RAMO_PROD) in ( '6038', '6046','TO','TT','TS','TU') THEN 4
					else  TIPO_RIESGO end
FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS  a
where /*a.SBU = 'AUT' AND*/ COMPANIA = 'HDISC'

UPDATE a 
SET TIPO_RIESGO	 = 0
FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_IAXIS  a
where  COMPANIA = 'HDISC' AND tipo_riesgo IS NULL


---- SELECT * FROM liberty_pruebas_actuaria.dbo.PU_CORREDORES_SINIESTROS  a
----where a.SBU = 'AUT'
---- AND COMPANIA = 'HDISC' AND modalidad IS NULL
