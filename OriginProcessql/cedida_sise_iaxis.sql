
/***********************
CEDIDA SISE
***********************/


drop table #cedida;


SELECT * 
INTO #cedida
FROM OPENQUERY(CODMHDI, '
    SELECT 
        concat(left(cast(a.fecha_proceso as CHAR(8)),4),substring(cast(a.fecha_proceso as CHAR(10)),6,2)) AS PERIODO_CONTABLE,
		a.cod_ramo_cial  as ramo_prod,
		a.nro_pol as poliza,
		case when a.cod_ramo_cial = 82 and a.CIA = 1 THEN ''OTH''	
			 when a.cod_ramo_cial = 82 and a.CIA = 2 THEN ''LIF''
			 WHEN a.COD_RAMO_CIAL = 14 THEN ''HEL'' 
			 WHEN a.COD_RAMO_CIAL = 10 THEN ''OTH'' 
			 when macro_ramo = ''AUTOS'' then ''AUT'' WHEN macro_ramo = ''GENERALES'' THEN ''OTH'' when macro_ramo = ''VIDA'' THEN ''LIF''
		END AS SBU,
        a.cod_agente AS INTERMEDIARIO_LIDE,
		a.cod_ramo_tecnico AS cod_ramo_tecnico,
        a.nom_tecnico AS nom_tecnico,
        a.cod_ramo_cial AS cod_ramo_cial,
        a.nom_comercial AS nom_comercial,
		case when a.PJE_PARTIC_AGENTE <> 100 then 1 else 0 end as Marca_corretaje,
		a.cod_agente as COD_INTERMEDIARIO,
		a.PJE_PARTIC_AGENTE as PARTICIPACION,
		case when a.cod_suc = 10 and  NUM_DOCUMENTO = ''890901176'' and a.cod_agente in (4001203,759) AND a.COD_RAMO_CIAL = 13  then 600 else a.cod_suc end as COD_SUCURSAL,
		case when a.cod_suc = 10 and  NUM_DOCUMENTO = ''890901176'' and a.cod_agente in (4001203,759) AND a.COD_RAMO_CIAL = 13  then 600 else a.cod_suc end as Suc_cont,
		a.cod_suc as Business_Area,
		a.suc_nombre as Business_Area_Des,
		'''' as Channel,	
		CASE WHEN NUM_DOCUMENTO=''890904646'' and COD_SUC =39  THEN ''LICITACIONES'' ELSE CANAL_COMERCIAL END as canal_comercial,
		SUM(prima_cedida) AS VALOR_CONCEPTO,
		a.cod_producto as MODALIDAD,
		a.cod_grupo as AGRUPADOR,
		a.SEGMENTO_AUTOS AS TIPO_RIESGO,
		a.TIPO_DOCUMENTO AS TIPO_DOC_TOMADOR,
		a.NUM_DOCUMENTO AS DOCUMENTO_TOMADOR,
		a.NOM_TOMADOR AS TOMADOR
    FROM PLANEACION_RPT.dbo.PRODUCCION_COMPLETA a
    WHERE a.fecha_proceso >= ''2026-01-01''  AND a.prima_cedida <> 0
    GROUP BY a.fecha_proceso, a.cod_suc, a.cod_ramo_cial, a.cod_agente, a.cod_ramo_tecnico, a.nom_tecnico, a.cod_ramo_cial, a.nom_comercial, a.suc_nombre,
	NUM_DOCUMENTO, CANAL_COMERCIAL, a.CIA, macro_ramo,SEGMENTO_AUTOS,TIPO_DOCUMENTO,NUM_DOCUMENTO,NOM_TOMADOR,a.nro_pol, a.PJE_PARTIC_AGENTE,a.cod_producto,a.cod_grupo
');

/**********************
TABLA DETALLE SISE

select * from #cedida 

select distinct PERIODO_CONTABLE, compania, concepto, sum(valor_concepto) 
from liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA 
group by PERIODO_CONTABLE, compania, concepto order by  PERIODO_CONTABLE, compania

**********************/



insert into liberty_pruebas_actuaria.dbo.DEVENGADA_GENERAL

SELECT 
'HDI' AS COMPANIA,
a.PERIODO_CONTABLE,
a.INTERMEDIARIO_LIDE as intermediario_inicial,
CONVERT(BIGINT,b.cod_clave_lider)  as intermediario_final,
CAST(a.ramo_prod as varchar) as ramo_prod ,
a.poliza,
a.SBU,
CAST(a.MODALIDAD AS numeric) as MODALIDAD ,
a.AGRUPADOR,
a.TIPO_RIESGO,
a.TIPO_DOC_TOMADOR,
a.DOCUMENTO_TOMADOR,
a.TOMADOR,
'Devengada' as Macroconcepto,
'Prima_cedida' as Concepto,
(a.VALOR_CONCEPTO) * -1 as  VALOR_CONCEPTO ,
'Produccion_completa' as Fuente_primaria,
1 as flag_inter

from #cedida a
--- INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = A.INTERMEDIARIO_LIDE AND g.cia = 'SISE'
left join [Liberty_pruebas_actuaria].[dbo].MAESTRO_INTERMEDIARIOS_HDISC b on  B.COD_INTERMEDIARIO_HDI  = a.INTERMEDIARIO_LIDE and b.CANAL_HDI  = a.canal_comercial  and
																					A.COD_SUCURSAL = b.COD_SUCURSAL_SUSCRIPCION_HDI 




/********************
CEDIDA IAXIS
*********************/


DROP TABLE #DOCUMENTO

SELECT * 
INTO #DOCUMENTO
FROM
(
	SELECT RAMO_PROD,POLIZA,CERTIFICADO,RECIBO,DOCUMENTO,COUNT(*) AS CONTEO,
	ROW_NUMBER() OVER (
	PARTITION BY RAMO_PROD, POLIZA, CERTIFICADO, RECIBO
	ORDER BY DOCUMENTO DESC) AS ID

	
	FROM liberty.PROD.DWH_POLIZAS_H

	--WHERE RAMO_PROD = '900747' AND POLIZA = 579300 AND RECIBO = 80690130  --80690126
	GROUP BY  RAMO_PROD,POLIZA,CERTIFICADO,RECIBO,DOCUMENTO
	--ORDER BY  RAMO_PROD,POLIZA,CERTIFICADO,RECIBO,DOCUMENTO
) A
WHERE ID = 1

-------


drop table #primas_ced

select a.* 
into #primas_ced
from 
(
	select 
	'HDISC' AS COMPANIA,
	ced.periodo_contable,
	inter.INTERMEDIARIO_LIDE as intermediario_inicial,
	inter.INTERMEDIARIO_LIDE as intermediario_final,
	ced.ramo as ramo_prod,
	ced.poliza,
	sbu.SBU,
	t3.modalidad as cod_modalidad,
	'' AS TIPO_RIESGO,
	ced.certificado,
	ced.documento,
	d.documento as documento_final,
	sum(ced.valor_cedido)*-1 as VALOR_CEDIDO,
	b.TIPO_DOCUMENTO_TOMADOR,
	b.NRO_DOCUMENTO_TOMADOR,
	b.NOMBRE_TOMADOR,
	'Devengada' as Macroconcepto,
	'Prima_cedida' as Concepto,
	'liberty.reservas.CEDIDAS_IAXIS' as Fuente
	
	from liberty.reservas.CEDIDAS_IAXIS ced
	left join liberty.apoyo.dwh_sbu_ramo_prod sbu on ced.ramo = sbu.ramo_prod 
	left join  liberty.[RESERVAS].[POLIZA_MODALIDAD] t3 on ced.ramo = t3.ramo_prod and ced.poliza = t3.poliza and ced.certificado = t3.certificado
	left join  LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO  inter on inter.ramo_prod = ced.ramo and inter.poliza = ced.poliza and inter.certificado = ced.certificado --and ced.documento = inter.documento
	LEFT JOIN LIBERTY.[APOYO].[DWH_TOMADORES] B ON ced.RAMO = B.COD_RAMO_PROD AND ced.POLIZA = B.NRO_POLIZA 
	LEFT JOIN #DOCUMENTO d on ced.ramo = d.ramo_prod and ced.poliza = d.poliza and ced.certificado = d.certificado and ced.DOCUMENTO = d.RECIBO
	where ced.periodo_contable >= 202601 

	group by
	ced.periodo_contable,
	ced.sucursal,
	sbu.SBU,
	ced.ramo,
	ced.poliza,
	ced.certificado,
	ced.documento,
	t3.modalidad,
	inter.INTERMEDIARIO_LIDE,
	b.TIPO_DOCUMENTO_TOMADOR,
	B.NRO_DOCUMENTO_TOMADOR,
	b.NOMBRE_TOMADOR,
	d.documento
) a
----INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = a.intermediario_inicial AND g.cia = 'IAXIS'



drop table #primas_ced_co

select 
'HDISC' AS COMPANIA,
ced.periodo_contable,
ced.intermediario_inicial,
c.agente AS intermediario_final_asociado,
ced.ramo_prod,
ced.poliza,
ced.SBU,
ced.cod_modalidad,
ced.TIPO_RIESGO,
ced.certificado,
ced.documento,
ced.documento_final,
ced.VALOR_CEDIDO * (c.PARTICIPACION /100) as VALOR_CONCEPTO,
ced.TIPO_DOCUMENTO_TOMADOR,
ced.NRO_DOCUMENTO_TOMADOR,
ced.NOMBRE_TOMADOR AS TOMADOR,
'Devengada' as Macroconcepto,
'Prima_cedida_corretaje' as Concepto,
'liberty.reservas.CEDIDAS_IAXIS' as Fuente
into #primas_ced_co
from #primas_ced ced
INNER join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis c on (ced.RAMO_PROD =  c.RAMO_PROD AND ced.POLIZA=c.POLIZA and ced.certificado=c.certificado AND ced.documento_final=c.DOCUMENTO_PRIMA)


drop table #cedida_iaxis_completo
select  * 
into #cedida_iaxis_completo
from #primas_ced
union all
select   * from #primas_ced_co 


/*
	select PERIODO_CONTABLE, compania,Concepto, SUM(valor_cedido)
	from #cedida_iaxis_completo
	group by  PERIODO_CONTABLE, Concepto,compania order by PERIODO_CONTABLE

	select * from #cedida_iaxis_completo where poliza = 530496
	select * from PU_CORREDORES_DETALLE_DEVENGADA_N where poliza = 530496 and periodo_contable = 202502
	4095871
	select * from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis where poliza = 4095871

select  PERIODO_CONTABLE, compania,Concepto, SUM(valor_concepto)
from liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA
group by  PERIODO_CONTABLE, Concepto,compania order by PERIODO_CONTABLE
drop table U_CORREDORES_DETALLE_DEVENGADA_N
*/

-------INSERT TABLA DETALLE

insert into  liberty_pruebas_actuaria.dbo.DEVENGADA_GENERAL

select 
COMPANIA
,PERIODO_CONTABLE	
,intermediario_inicial
,intermediario_final
,ramo_prod
,poliza	
,SBU
,CAST(cod_modalidad AS numeric) as MODALIDAD 
,null as AGRUPADOR
,TIPO_RIESGO	
,TIPO_DOCUMENTO_TOMADOR	AS TIPO_DOC_TOMADOR
,NRO_DOCUMENTO_TOMADOR AS DOCUMENTO_TOMADOR
,NOMBRE_TOMADOR	AS TOMADOR
,Macroconcepto
,Concepto	
,SUM(VALOR_CEDIDO) AS VALOR_CONCEPTO
,Fuente AS Fuente_primaria
, 1 as flag_inter

from  #cedida_iaxis_completo
GROUP BY 
COMPANIA
,periodo_contable	
,intermediario_inicial
,intermediario_final
,ramo_prod
,poliza	
,TIPO_RIESGO	
,TIPO_DOCUMENTO_TOMADOR	
,NRO_DOCUMENTO_TOMADOR
,NOMBRE_TOMADOR	
,Macroconcepto
,Concepto
,cod_modalidad
,Fuente
,sbu



--- VALIDACION
----select concepto,periodo_contable,compania,sum(valor_concepto) from  PU_CORREDORES_DETALLE_DEVENGADA
----group by concepto,compania,periodo_contable
/*
select top 5 * from PU_CORREDORES_DETALLE_DEVENGADA_N
select top 5 * from  #cedida_iaxis_completo
drop table PU_CORREDORES_DETALLE_DEVENGADA_N

*/
----ORDER BY periodo_contable,concepto



/********************
CEDIDA AS400
*********************/

drop table #primas_ced_as400

select a.* 
into #primas_ced_as400
from 
(
select 
'HDISC' AS COMPANIA,
ced.peco as periodo_contable,
inter.INTERMEDIARIO_LIDE as intermediario_inicial,
inter.INTERMEDIARIO_LIDE as intermediario_final,
ced.ramo as ramo_prod,
ced.poli as poliza,
sbu.SBU,
'' as cod_modalidad,
NULL AS TIPO_RIESGO,
ced.cert as certificado,
ced.anex as documento,
ced.anex as documento_final,
sum(vces)*-1 as VALOR_CEDIDO,
b.TIPO_DOCUMENTO_TOMADOR AS TIPO_DOC_TOMADOR,
b.NRO_DOCUMENTO_TOMADOR AS DOCUMENTO_TOMADOR,
b.NOMBRE_TOMADOR,
'Devengada' as Macroconcepto,
'Prima_cedida' as Concepto,
'liberty.reservas.cedidas' as Fuente
from liberty.reservas.cedidaS  ced
left join liberty.apoyo.dwh_sbu_ramo_prod sbu on ced.ramo = sbu.ramo_prod 
left join  LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO  inter on inter.ramo_prod = ced.ramo and inter.poliza = ced.poli and inter.certificado = ced.cert --and ced.documento = inter.documento
LEFT JOIN LIBERTY.[APOYO].[DWH_TOMADORES] B ON ced.RAMO = B.COD_RAMO_PROD AND ced.poli = B.NRO_POLIZA
WHERE ced.peco >= 202601
group by 
ced.peco,
inter.INTERMEDIARIO_LIDE,
inter.INTERMEDIARIO_LIDE,
ced.ramo,
ced.poli,
sbu.SBU,
ced.cert,
ced.anex,
ced.anex,
b.TIPO_DOCUMENTO_TOMADOR,
b.NRO_DOCUMENTO_TOMADOR,
b.NOMBRE_TOMADOR
) a
---INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = a.intermediario_inicial AND g.cia = 'IAXIS'

--- corretaje 

drop table #primas_ced_as_400_co

select 
'HDISC' AS COMPANIA,
ced.periodo_contable,
ced.intermediario_inicial,
c.agente AS intermediario_final_asociado,
ced.ramo_prod,
ced.poliza,
ced.SBU,
ced.cod_modalidad,
ced.TIPO_RIESGO,
ced.certificado,
ced.documento,
ced.documento_final,
ced.VALOR_CEDIDO * (c.PARTICIPACION /100) AS VALOR_CONCEPTO,
ced.TIPO_DOC_TOMADOR,
ced.DOCUMENTO_TOMADOR,
ced.NOMBRE_TOMADOR,
'Devengada' as Macroconcepto,
'Prima_cedida_corretaje' as Concepto,
'liberty.reservas.cedidas' as Fuente
into #primas_ced_as_400_co
from #primas_ced_as400 ced
INNER join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis c on (ced.RAMO_PROD =  c.RAMO_PROD AND ced.POLIZA=c.POLIZA and ced.certificado=c.certificado AND ced.documento_final=c.DOCUMENTO_PRIMA)


select  * 
into #cedida_AS400_completo
from #primas_ced_as400
union all
select   * from #primas_ced_as_400_co


/*
SELECT * from #primas_ced_as400

	select PERIODO_CONTABLE, compania,Concepto, SUM(valor_cedido)
	from #cedida_AS400_completo
	group by  PERIODO_CONTABLE, Concepto,compania order by PERIODO_CONTABLE
	*/
-------INSERT TABLA DETALLE

insert into  liberty_pruebas_actuaria.dbo.DEVENGADA_GENERAL

select 
COMPANIA
,periodo_contable	
,intermediario_inicial
,CONVERT(BIGINT,intermediario_final) AS intermediario_final
,ramo_prod
,CAST(poliza AS numeric) AS poliza
,SBU
,NULL  AS MODALIDAD
,null as AGRUPADOR
,NULL AS TIPO_RIESGO	
,TIPO_DOC_TOMADOR
,DOCUMENTO_TOMADOR
,NOMBRE_TOMADOR	
,Macroconcepto
,Concepto	
,SUM(CAST(VALOR_CEDIDO AS NUMERIC(38,2))) AS VALOR_CONCEPTO
,Fuente
, 1 as flag_inter
--INTO PU_CORREDORES_DETALLE_DEVENGADA_2
from  #cedida_AS400_completo
GROUP BY 
COMPANIA
,periodo_contable	
,intermediario_inicial
,intermediario_final
,ramo_prod
,poliza	
,TIPO_DOC_TOMADOR	
,DOCUMENTO_TOMADOR
,NOMBRE_TOMADOR	
,Macroconcepto
,Concepto
,cod_modalidad
,Fuente
,sbu


------ INSERTAR TODAS LAS BASES ---- 



insert into liberty_pruebas_actuaria.dbo.DEVENGADA_GENERAL

select * 
---into  liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA
from 
(

SELECT COMPANIA,periodo_contable	,intermediario_inicial,CONVERT(BIGINT,intermediario_final_ASOCIADO) AS intermediario_final,A.ramo_prod,CAST(poliza AS numeric) AS poliza,B.SBU,CAST(NULLIF(MODALIDAD, 'null') AS INT) as MODALIDAD,CAST(NULLIF(AGRUPADOR, 'null') AS INT) as AGRUPADOR ,  cast (TIPO_RIESGO as varchar)  as  TIPO_RIESGO 
,TIPO_IDENTIFI_TOMADOR AS TIPO_DOC_TOMADOR, Numero_identificacion_tomador AS DOCUMENTO_TOMADOR , '' AS TOMADOR	,macro_concepto AS Macroconcepto ,Concepto	,VALOR_CONCEPTO,fuente_primaria, 1 as flag_inter
FROM liberty_pruebas_actuaria.dbo.directa_reserva_general A
LEFT JOIN liberty.apoyo.DWH_SBU_RAMO_PROD B ON (A.RAMO_PROD = B.RAMO_PROD)
union all
SELECT COMPANIA,periodo_contable	,intermediario_inicial,CONVERT(BIGINT,intermediario_final_ASOCIADO) AS intermediario_final,A.ramo_prod,CAST(poliza AS numeric) AS poliza,B.SBU,CAST(NULLIF(MODALIDAD, 'null') AS INT) as MODALIDAD,CAST(NULLIF(AGRUPADOR, 'null') AS INT) as AGRUPADOR ,  cast (TIPO_RIESGO as varchar)  as  TIPO_RIESGO 
,TIPO_IDENTIFI_TOMADOR AS TIPO_DOC_TOMADOR, Numero_identificacion_tomador AS DOCUMENTO_TOMADOR , '' AS TOMADOR	,macro_concepto AS Macroconcepto ,Concepto	,VALOR_CONCEPTO,fuente_primaria, 1 as flag_inter
FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_general A
LEFT JOIN liberty.apoyo.DWH_SBU_RAMO_PROD B ON (A.RAMO_PROD = B.RAMO_PROD)
union all


SELECT COMPANIA,periodo_contable	,intermediario_inicial,CONVERT(BIGINT,intermediario_final_ASOCIADO) AS intermediario_final,A.ramo_prod,CAST(poliza AS numeric) AS poliza,B.SBU,CAST(NULLIF(MODALIDAD, 'null') AS INT) as MODALIDAD,CAST(NULLIF(AGRUPADOR, 'null') AS INT) as AGRUPADOR , cast (TIPO_RIESGO as varchar)  as  TIPO_RIESGO 
,TIPO_IDENTIFI_TOMADOR AS TIPO_DOC_TOMADOR, Numero_identificacion_tomador AS DOCUMENTO_TOMADOR , '' AS TOMADOR	,macro_concepto AS Macroconcepto ,Concepto	,VALOR_CONCEPTO,fuente_primaria, 1 as flag_inter
FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_general_iaxis A
LEFT JOIN liberty.apoyo.DWH_SBU_RAMO_PROD B ON (A.RAMO_PROD = B.RAMO_PROD)

union all

SELECT COMPANIA,periodo_contable	,intermediario_inicial,CONVERT(BIGINT,intermediario_final_ASOCIADO) AS intermediario_final,A.ramo_prod,CAST(poliza AS numeric) AS poliza,B.SBU,CAST(NULLIF(MODALIDAD, 'null') AS INT) as MODALIDAD,CAST(NULLIF(AGRUPADOR, 'null') AS INT) as AGRUPADOR , cast (TIPO_RIESGO as varchar)  as  TIPO_RIESGO 	
,TIPO_IDENTIFI_TOMADOR AS TIPO_DOC_TOMADOR, Numero_identificacion_tomador AS DOCUMENTO_TOMADOR , '' AS TOMADOR	,macro_concepto AS Macroconcepto ,Concepto	,VALOR_CONCEPTO,fuente_primaria, 1 as flag_inter
FROM liberty_pruebas_actuaria.dbo.cedidas_terremoto_general A
LEFT JOIN liberty.apoyo.DWH_SBU_RAMO_PROD B ON (A.RAMO_PROD = B.RAMO_PROD)
 

/*
select COMPANIA,periodo_contable	,intermediario_inicial,intermediario_final,ramo_prod,poliza,SBU,MODALIDAD,AGRUPADOR--, TIPO_RIESGO
,TIPO_DOC_TOMADOR, DOCUMENTO_TOMADOR , TOMADOR	,macroconcepto ,Concepto	,VALOR_CONCEPTO,fuente_primaria, 1 as flag_inter
FROM liberty_pruebas_actuaria.dbo. PU_CORREDORES_DETALLE_DEVENGADA_n

*/

) Z



----- VALIDACIONES ------ 

/*
insert into liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA

SELECT COMPANIA,periodo_contable	,intermediario_inicial,CONVERT(BIGINT,intermediario_final_ASOCIADO) AS intermediario_final,A.ramo_prod,CAST(poliza AS numeric) AS poliza,B.SBU,CAST(NULLIF(MODALIDAD, 'null') AS INT) as MODALIDAD,CAST(NULLIF(AGRUPADOR, 'null') AS INT) as AGRUPADOR , cast (TIPO_RIESGO as varchar)  as  TIPO_RIESGO 
,TIPO_IDENTIFI_TOMADOR AS TIPO_DOC_TOMADOR, Numero_identificacion_tomador AS DOCUMENTO_TOMADOR , '' AS TOMADOR	,macro_concepto AS Macroconcepto ,Concepto	,VALOR_CONCEPTO,fuente_primaria, 1 as flag_inter
FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp_N A
LEFT JOIN liberty.apoyo.DWH_SBU_RAMO_PROD B ON (A.RAMO_PROD = B.RAMO_PROD)



DELETE FROM  liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA
WHERE Concepto ='Prima_cedida' and Fuente_primaria = 'liberty.reservas.cedidas' and COMPANIA ='HDISC'
 
DELETE FROM  liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA
WHERE Concepto ='Prima_cedida' and Fuente_primaria = 'liberty.reservas.cedidas' and COMPANIA ='HDISC' AND  ramo_prod IN ('01') 
 



SELECT TOP 5 * FROM liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp_n
SELECT distinct concepto, macro_concepto FROM liberty_pruebas_actuaria.dbo.cedidas_terremoto_reserva_final_devengada_tmp_n


SELECT TOP 5 * FROM liberty_pruebas_actuaria.dbo.directa_reserva_final_devengada_tmp
SELECT distinct compania  FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp_N
SELECT distinct concepto,fuente_primaria  FROM liberty_pruebas_actuaria.dbo.cedidas_reserva_iaxis_final_devengada_tmp_N

SELECT top 10 *  FROM liberty_pruebas_actuaria.dbo. PU_CORREDORES_DETALLE_DEVENGADA order by TIPO_RIESGO desc 
---SELECT *  FROM liberty_pruebas_actuaria.dbo. PU_CORREDORES_DETALLE_DEVENGADA_n order by TIPO_RIESGO desc 


select distinct Concepto from liberty_pruebas_actuaria.dbo.directa_reserva_final_devengada_tmp_N


select *  
from liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA a
where ramo_prod IN ('01') AND Concepto ='Prima_cedida' and Fuente_primaria = 'liberty.reservas.cedidas' and COMPANIA ='HDISC'


SELECT * FROM #cedida_AS400_completo


select  DISTINCT RAMO_PROD from Liberty.RESERVAS.DIRECTA_RESERVA_INTERFAZ where CUENTA IN ('510310')
  AND Libro <> 'AG' AND periodo_contable_analisis >= 202604;


  select distinct macroconcepto, concepto from liberty_pruebas_actuaria.dbo.DEVENGADA_GENERAL