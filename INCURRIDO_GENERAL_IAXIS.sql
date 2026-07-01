

/*
---- CLAVES LIDER DE NEGOCIOS EN CORRETAJE CON CLAVES QUE PARTICIPAN EN PU CORREDORES
 drop table #CLAVES_PU_CORRETAJE
 SELECT DISTINCT G.* 
 INTO #CLAVES_PU_CORRETAJE
 FROM 
  (
 select  X.clave_inicial_asociada, 'IAXIS' AS CIA
 from (
SELECT DISTINCT
       L.sseguro,
       L.AGENTE  AS clave_inicial_asociada,
       N.AGENTE  AS agente_no_lider

SELECT * FROM [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis WHERE POLIZA =517342ORDER BY SSEGURO , DOCUMENTO_PRIMA
  L
JOIN [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis N
  ON N.sseguro = L.sseguro
 AND N.es_lider = 0
 AND N.AGENTE <> L.AGENTE   -- evita combinaciones "mismo agente"
WHERE L.es_lider = 1) x 
left join Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores y on (X.agente_no_lider = Y.clave_inicial_asociada)
WHERE Y.CIA IS NOT NULL

UNION ALL 
SELECT * FROM Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores) G

*/

/**********************
INCURRIDO NOV_CONT_D
**********************/
drop table #sini_incurrido

select 
a.periodo_contable,
b.INTERMEDIARIO_LIDE as intermediario_inicial,
b.INTERMEDIARIO_LIDE AS intermediario_final_asociado,
c.sbu,
b.RAMO_PROD,
b.poliza,
b.modalidad,
null as Agrupador,
null as tipo_riesgo,
a.sucursal_prod,
a.SUCURSAL_CONTABLE as cod_sucursal,
b.documento,
null as documento_final,
a.certificado,
a.radicacion as numero_siniestro,
'INCURRIDO' AS Macro_concepto,
'Siniestros_incurrido' as Concepto,
CASE WHEN A.SIS_ORIGEN = 'N' and a.VR_P_COASEGURO = 100   THEN  a.VR_NOVEDAD 
     WHEN A.SIS_ORIGEN = 'N' and a.VR_P_COASEGURO <> 0  THEN  a.VR_NOVEDAD * ((100-a.VR_P_COASEGURO) /100)
	 WHEN A.SIS_ORIGEN = 'N' and a.VR_P_COASEGURO = 0  THEN  a.VR_NOVEDAD
	 WHEN A.SIS_ORIGEN = 'O' AND (COA.[GDPJVR]=0 or COA.[GDPJVR]=100) then a.VR_NOVEDAD
	 WHEN A.SIS_ORIGEN = 'O'	AND (COA.[GDPJVR]<>0 or COA.[GDPJVR]<>100) THEN a.VR_NOVEDAD * (COA.[GDPJVR]/100)
     else a.VR_NOVEDAD END AS VALOR_CONCEPTO
into #sini_incurrido
FROM liberty.sini.DWH_S_NOV_CONT_D  a
--INNER JOIN #CLAVES_PU_CORRETAJE g ON g.CLAVE_INICIAL_ASOCIADA = A.INTERMEDIARIO_LIDE AND g.cia = 'IAXIS'
left join liberty.sini.dwh_s_maestro_d b on	(a.LLAVE_SIN = b.LLAVE_SIN)	
left join liberty.apoyo.dwh_sbu_ramo_prod c on a.ramo_prod = c.ramo_prod 
left join [Liberty].[AS400].[SNLCOAC1] as COA on	(													
													b.ramo_prod = coa.GDRACG 
													and b.poliza= coa.GDPZNU 
													and b.certificado = coa.GDCTNU 
													and b.documento = coa.GDDCNU
													and b.[SIS_ORIGEN] = 'O'
													)		
where A.PERIODO_CONTABLE >= 202512 and TIPO_NOVEDAD not in (5,6) 



---select  * from #sini_incurrido

--select  * FROM liberty.sini.DWH_S_NOV_CONT_D a
--where periodo_contable between 202601 and 202604  and 
--a.intermediario_lide IN (
--      SELECT b.CLAVE_INICIAL_ASOCIADA
--      FROM claves_asociadas_pu_corredores b)
--	  and TIPO_NOVEDAD not in (5,6)


--select * from #sini_incurrido
--where numero_siniestro = 1196710


select 
a.periodo_contable,
a.intermediario_inicial,
c.agente AS intermediario_final_asociado,
a.sbu,
a.RAMO_PROD,
a.poliza,
a.modalidad,
null as Agrupador,
null as tipo_riesgo,
a.sucursal_prod,
a.cod_sucursal,
a.documento,
a.documento_final,
a.certificado,
a.numero_siniestro,
'INCURRIDO' AS Macro_concepto,
'Siniestros_incurrido_CO-Corretaje' as Concepto,
--a.VR_NOVEDAD,
--c.PARTICIPACION,
(A.VALOR_CONCEPTO) * (c.PARTICIPACION / 100.0) AS valor_concepto
INTO #incurrido_corretaje
FROM #sini_incurrido  a
INNER join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis c on (A.RAMO_PROD =  c.RAMO_PROD AND A.POLIZA=c.POLIZA and A.certificado=c.certificado AND A.DOCUMENTO=c.DOCUMENTO_PRIMA)

--select *From #incurrido_corretaje
-- where ramo_prod = '900780' and poliza =559479 and certificado=496


--select * from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis 
--where ramo_prod = '900780' and poliza =559479 and certificado=496

SELECT * 
INTO #incurrido
FROM #sini_incurrido
UNION ALL
SELECT * FROM #incurrido_corretaje

/*
SELECT sum(valor_concepto) FROM #sini_incurrido a
  left join (select distinct clave_asociada_inicial from [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada where clave_lider = 1044) b on (a.intermediario_final_asociado =b.clave_asociada_inicial )
WHERE clave_asociada_inicial is not null  and PERIODO_CONTABLE = 202601*/

/******************************************
VARIACION BASE_H_REASEGURO
******************************************/
drop table #variacion

sElect * 
into #variacion
from liberty.[MIDDLEWARE].[DWH_REASEGURO_H] a
left join (select radicacion,poliza,certificado,documento,count(*) as conteo from liberty.sini.dwh_s_maestro_d
			group by radicacion,poliza,certificado,documento) d on a.NUMERO_SINIESTRO = d.RADICACION
where PERIODO >= 202512  and   cuenta_local in (411105
,511105,411110,511110
)
and subcuenta_local in (101
,102,103,104,105,106,199,201,202,502,602,
701,702,704,706,707,708
,709,301,302,405,18,724,723,101,1202,104
,1301,17,18,502,719,704,1201
)


DROP TABLE #sini_incurrido_v_r



select 
a.PERIODO as periodo_contable,
COALESCE([dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER),B.INTERMEDIARIO_LIDE) as intermediario_inicial,
COALESCE([dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER),B.INTERMEDIARIO_LIDE) as intermediario_final_asociado,
c.sbu,
a.CODIGO_RAMO_PRODUCTO as  RAMO_PROD,
b.POLIZA,
CONVERT(INT,a.MODALIDAD) as modalidad,
null as Agrupador,
null as tipo_riesgo,
a.SUCURSAL_PROD as sucursal_prod,
a.SUCURSAL_CONTABLE as cod_sucursal,
b.DOCUMENTO as documento,
b.DOCUMENTO as  documento_final,
b.CERTIFICADO as certificado,
a.numero_siniestro,
'INCURRIDO' AS Macro_concepto,
'Siniestros_liquidados_variacion_rea' as Concepto,
case when a.NATURALEZA_CONTABLE <> 'H'  THEN cast(a.VALOR_RUBRO as bigint) * -1 ELSE cast(a.VALOR_RUBRO as bigint) END AS VALOR_CONCEPTO
into  #sini_incurrido_v_r
from liberty.[MIDDLEWARE].[DWH_REASEGURO_H] a
--INNER JOIN #CLAVES_PU_CORRETAJE g ON g.CLAVE_INICIAL_ASOCIADA = [dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER)  AND g.cia = 'IAXIS'
left join (select radicacion,poliza,certificado,documento,INTERMEDIARIO_LIDE, count(*) as conteo from liberty.sini.dwh_s_maestro_d
			group by radicacion,poliza,certificado,documento,INTERMEDIARIO_LIDE) b on a.NUMERO_SINIESTRO = b.RADICACION
left join liberty.apoyo.dwh_sbu_ramo_prod c on a.CODIGO_RAMO_PRODUCTO = c.ramo_prod 
where PERIODO >= 202512 and   cuenta_local in (411105
,511105,411110,511110)
and subcuenta_local in (101
,102,103,104,105,106,199,201,202,502,602,
701,702,704,706,707,708
,709,301,302,405,18,724,723,101,1202,104
,1301,17,18,502,719,704,1201
)


union all 


select 
a.PERIODO as periodo_contable,
[dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) as intermediario_inicial,
b.AGENTE as intermediario_final_asociado,
c.sbu,
a.CODIGO_RAMO_PRODUCTO as  RAMO_PROD,
a.POLIZA,
CONVERT(INT,a.MODALIDAD) as modalidad,
null as Agrupador,
null as tipo_riesgo,
a.SUCURSAL_PROD as sucursal_prod,
a.SUCURSAL_CONTABLE as cod_sucursal,
a.DOCUMENTO as documento,
a.DOCUMENTO as  documento_final,
a.CERTIFICADO as certificado,
a.numero_siniestro,
'INCURRIDO' AS Macro_concepto,
'Siniestros_liquidados_variacion_rea_corretaje' as Concepto,
case when a.NATURALEZA_CONTABLE <> 'H'  THEN cast(a.VALOR_RUBRO as bigint) * -1 *  (B.PARTICIPACION / 100.0) ELSE cast(a.VALOR_RUBRO as bigint) * (B.PARTICIPACION / 100.0) END AS VALOR_CONCEPTO
from #variacion a
--INNER JOIN #CLAVES_PU_CORRETAJE g ON g.CLAVE_INICIAL_ASOCIADA = [dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) AND g.cia = 'IAXIS'
inner join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis B on (A.CODIGO_RAMO_PRODUCTO =  B.RAMO_PROD and b.certificado=a.certificado AND a.POLIZA=B.POLIZA AND a.DOCUMENTO=B.DOCUMENTO_PRIMA)
left join liberty.apoyo.dwh_sbu_ramo_prod c on a.CODIGO_RAMO_PRODUCTO = c.ramo_prod 
where PERIODO >= 202512  and   cuenta_local in (411105
,511105,411110,511110
)
and subcuenta_local in (101
,102,103,104,105,106,199,201,202,502,602,
701,702,704,706,707,708
,709,301,302,405,18,724,723,101,1202,104
,1301,17,18,502,719,704,1201
)




--select * from #sini_incurrido_v_r

/*********************
LIQUIDADOS REASEGURO
**********************/
drop table #reaseguro_siniestros_co

select 
a.mdpek as periodo_contable,
[dbo].[F_Conv_Cod_Agente](a.mdagl) as intermediario_inicial,
[dbo].[F_Conv_Cod_Agente](a.mdagl) as intermediario_final_asociado,
c.sbu,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdmod as modalidad,
null as Agrupador,
null as tipo_riesgo,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
'INCURRIDO_REASEGURO' AS Macro_concepto,
'Siniestros_liquidados_reaseguro' as Concepto,
cast(a.mdaag as bigint) *-1  AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
into #reaseguro_siniestros_co
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
--INNER JOIN #CLAVES_PU_CORRETAJE g ON g.CLAVE_INICIAL_ASOCIADA = [dbo].[F_Conv_Cod_Agente](a.mdagl) AND g.cia = 'IAXIS'
left join liberty.apoyo.dwh_sbu_ramo_prod c on a.mdprt = c.ramo_prod 
where mdpek >=  202512  and  mdobj in (411640,411645)  and mdsct in (0101,0102,0103,0109,0113,0106,0402,0403,405,0405,0407,0102,0105,0107,0402)


union all 



select 
a.mdpek as periodo_contable,
[dbo].[F_Conv_Cod_Agente](a.mdagl) as intermediario_inicial,
b.AGENTE as intermediario_final_asociado,
c.sbu,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdmod as modalidad,
null as Agrupador,
null as tipo_riesgo,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
'INCURRIDO_REASEGURO' AS Macro_concepto,
'Siniestros_liquidados_reaseguro_corretaje' as Concepto,
cast(a.mdaag as bigint) *-1 * (B.PARTICIPACION / 100.0)  AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
--into #reaseguro_siniestros_co
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
--INNER JOIN #CLAVES_PU_CORRETAJE g ON g.CLAVE_INICIAL_ASOCIADA = [dbo].[F_Conv_Cod_Agente](a.mdagl) AND g.cia = 'IAXIS'
inner join (select ramo_prod,poliza, participacion,agente, count(*) as conteo from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis
			 group by  ramo_prod,poliza, participacion,agente ) B on (A.mdprt =  B.RAMO_PROD /*and b.certificado=a.mdctd */AND a.mdpza=B.POLIZA /*AND a.mdrep=B.DOCUMENTO_PRIMA*/)
left join liberty.apoyo.dwh_sbu_ramo_prod c on a.mdprt = c.ramo_prod 
where mdpek >=  202512  and  mdobj in (411640,411645)  and mdsct in (0101,0102,0103,0109,0113,0106,0402,0403,405,0405,0407,0102,0105,0107,0402)

/*****************
UNION BASES
*****************/
---------------


DROP TABLE #incurrido_final
-- LIQUIDADOS
SELECT *
into #incurrido_final
FROM #incurrido

UNION ALL
-- VARIACION RESERVA REAEGUROS
SELECT *
FROM #sini_incurrido_v_r

UNION ALL
--- LIQUIDADOS REASEGUROS 
SELECT *
FROM #reaseguro_siniestros_co

---



insert into SINIESTROS_DETALLE_GENERAL
SELECT  * 
---into liberty_pruebas_actuaria.dbo.SINIESTROS_DETALLE_GENERAL
FROM #incurrido_final

/* ---  validador
select * from #incurrido_final a
DROP TABLE SINIESTROS_DETALLE_GENERAL
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final_asociado =b.clave_asociada_inicial ) where periodo_contable = 202601 and b.clave_lider = 1044
*/

--- drop table CORREDORES_SINIESTROS_DETALLE

/***************************
BASE FINAL
****************************/
---drop table SINIESTROS_GENERAL_IAXIS


INSERT INTO SINIESTROS_GENERAL_IAXIS

SELECT
'HDISC' AS COMPANIA
,periodo_contable
,intermediario_inicial
,intermediario_final_asociado
,RAMO_PROD	
,poliza	
,modalidad
,Agrupador
,tipo_riesgo
,B.TIPO_DOCUMENTO_TOMADOR AS TIPO_IDENTIFI_TOMADOR
,B.NRO_DOCUMENTO_TOMADOR AS NUMERO_IDENTIFICACION_TOMADOR
,Macro_concepto	
,Concepto	
,SUM(VALOR_CONCEPTO)  AS VALOR_CONCEPTO
,CASE WHEN CONCEPTO IN ('Siniestros_incurrido','Siniestros_incurrido_CO-Corretaje') THEN 'DWH_NOV_CONT_D'
	  WHEN CONCEPTO IN ('Siniestros_liquidados_variacion_rea','Siniestros_liquidados_variacion_rea_corretaje') THEN 'MIDDLEWARE.DWH_REASEGURO_H'
	  WHEN CONCEPTO IN ('Siniestros_liquidados_reaseguro','Siniestros_liquidados_reaseguro_corretaje') THEN 'MIDDLEWARE.BASE_REASEGUROS_H' 
	  END AS fuente_primaria
---INTO SINIESTROS_GENERAL_IAXIS
FROM SINIESTROS_DETALLE_GENERAL A
LEFT JOIN LIBERTY.[APOYO].[DWH_TOMADORES] B ON A.RAMO_PROD = B.COD_RAMO_PROD AND A.POLIZA = B.NRO_POLIZA 
GROUP BY 
periodo_contable
,intermediario_inicial
,intermediario_final_asociado
,RAMO_PROD	
,poliza	
,modalidad
,Agrupador
,tipo_riesgo
,TIPO_DOCUMENTO_TOMADOR
,NRO_DOCUMENTO_TOMADOR
,Macro_concepto	
,Concepto



----------------------

SELECT PERIODO_CONTABLE,CONCEPTO,SUM(VALOR_CONCEPTO) AS VALOR 
FROM SINIESTROS_GENERAL_IAXIS 
GROUP BY PERIODO_CONTABLE,CONCEPTO


SELECT PERIODO_CONTABLE,CONCEPTO,SUM(VALOR_CONCEPTO) AS VALOR 
FROM SINIESTROS_GENERAL_IAXIS_MAYO 




select PERIODO_CONTABLE,CONCEPTO,SUM(VALOR_CONCEPTO) AS VALOR from SINIESTROS_GENERAL_IAXIS
--WHERE PERIODO_CONTABLE = 202603
GROUP BY PERIODO_CONTABLE,CONCEPTO


select * from SINIESTROS_GENERAL_IAXIS
WHERE PERIODO_CONTABLE = 202601 and poliza=533179

GROUP BY PERIODO_CONTABLE,CONCEPTO



select * from liberty_pruebas_actuaria.dbo.Corretaje_HDI2

select * from PU_CORREDORES_SINIESTROS_BCK
where poliza = 120638
select * from PU_CORREDORES_SINIESTROS
where poliza = 120638



select * from PU_CORREDORES_SINIESTROS_DETALLE_bck[dbo].[PU_CORREDORES_SINIESTROS_BCK]