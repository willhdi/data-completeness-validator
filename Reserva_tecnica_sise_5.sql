
/***********************
Reserva Tecnica
***********************/


drop table #reserva;


SELECT * 
INTO #reserva
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
		SUM(reserva_tecnica) AS VALOR_CONCEPTO,
		a.cod_producto as MODALIDAD,
		a.cod_grupo as AGRUPADOR,
		a.SEGMENTO_AUTOS AS TIPO_RIESGO,
		a.TIPO_DOCUMENTO AS TIPO_DOC_TOMADOR,
		a.NUM_DOCUMENTO AS DOCUMENTO_TOMADOR,
		a.NOM_TOMADOR AS TOMADOR
    FROM PLANEACION_RPT.dbo.PRODUCCION_COMPLETA a
    WHERE a.fecha_proceso >= ''2026-01-01''  AND a.reserva_tecnica <> 0
    GROUP BY a.fecha_proceso, a.cod_suc, a.cod_ramo_cial, a.cod_agente, a.cod_ramo_tecnico, a.nom_tecnico, a.cod_ramo_cial, a.nom_comercial, a.suc_nombre,
	NUM_DOCUMENTO, CANAL_COMERCIAL, a.CIA, macro_ramo,SEGMENTO_AUTOS,TIPO_DOCUMENTO,NUM_DOCUMENTO,NOM_TOMADOR,a.nro_pol, a.PJE_PARTIC_AGENTE,a.cod_producto,a.cod_grupo
');

/**********************
TABLA DETALLE
select * from #reserva
select distinct PERIODO_CONTABLE from liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA order by  PERIODO_CONTABLE
select distinct PERIODO_CONTABLE, compania, concepto, sum(valor_concepto) from liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA group by PERIODO_CONTABLE, compania, concepto order by  PERIODO_CONTABLE
**********************/



INSERT into liberty_pruebas_actuaria.dbo.DEVENGADA_GENERAL

SELECT 
'HDI' AS COMPANIA,
a.PERIODO_CONTABLE,
a.INTERMEDIARIO_LIDE as intermediario_inicial,
b.cod_clave_lider as intermediario_final,
a.ramo_prod,
a.poliza,
a.SBU,
a.MODALIDAD,
a.AGRUPADOR,
a.TIPO_RIESGO,
a.TIPO_DOC_TOMADOR,
a.DOCUMENTO_TOMADOR,
a.TOMADOR,
'Devengada' as Macroconcepto,
'Ajuste_reserva_tecnica' as Concepto ,
(a.VALOR_CONCEPTO) *-1 as VALOR_CONCEPTO,
'Produccion_completa' as Fuente_primaria,
1 as flag_inter

from #reserva a
---INNER JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores g ON g.CLAVE_INICIAL_ASOCIADA = A.INTERMEDIARIO_LIDE AND g.cia = 'SISE'
left join [Liberty_pruebas_actuaria].[dbo].MAESTRO_INTERMEDIARIOS_HDISC b on  B.COD_INTERMEDIARIO_HDI  = a.INTERMEDIARIO_LIDE and b.CANAL_HDI  = a.canal_comercial  and
																					A.COD_SUCURSAL = b.COD_SUCURSAL_SUSCRIPCION_HDI 


/*
DELETE FROM  liberty_pruebas_actuaria.dbo.PU_CORREDORES_DETALLE_DEVENGADA
WHERE Concepto ='Ajuste_reserva_tecnica' and macroconcepto = 'Devengada' and Fuente_primaria = 'Produccion_completa' and COMPANIA ='HDI'
 
*/