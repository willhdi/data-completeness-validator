
drop table #lideres_incurridos
select  distinct cdigo_sucursal,cdigo_agente_principal,cdigo_ramo_comercial,pliza, min(fecha_vig_desde_endo) as fecha_vig_desde_endo, max(fecha_vig_hasta_endo) as fecha_vig_hasta_endo
into #lideres_incurridos
from [Liberty_Pruebas_Actuaria].Attrition.[acc_sise_appgenerali_siniestros_incurridos_fusion]
group by cdigo_sucursal,cdigo_agente_principal,cdigo_ramo_comercial,pliza



drop table #lideres_produccion
select distinct 
A.cod_suc, A.COD_RAMO_CIAL ,A.cod_agente,A.nro_pol,pje_partic_agente, min(fec_vig_desde) as fec_vig_desde, max(fec_vig_hasta) as fec_vig_hasta
into #lideres_produccion
from CODMHDI.PLANEACION_RPT.dbo.PRODUCCION_COMPLETA A
WHERE fecha_proceso between '2020-01-01' and '2026-12-31' and SINIESTROS_BRUTOS <> 0 and pje_partic_agente <> 100 and pje_partic_agente <> 0
group by  
A.cod_suc, A.COD_RAMO_CIAL ,A.cod_agente,A.nro_pol,pje_partic_agente



drop table [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_Sise
select a.cod_suc, cod_ramo_cial, cod_agente, nro_pol,a.fec_vig_desde,fec_vig_hasta ,
case when b.cdigo_agente_principal=a.cod_agente then 1 end as ISLIDER,
case when b.cdigo_agente_principal = a.cod_agente then pje_partic_agente-100 else pje_partic_agente end as PARTICIPACION 
into [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_Sise
from #lideres_produccion a
left join  #lideres_incurridos b 
on (a.nro_pol = b.pliza  and a.cod_suc = b.cdigo_sucursal  and a.cod_ramo_cial = b.cdigo_ramo_comercial and a.fec_vig_desde >= b.fecha_vig_desde_endo    and a.fec_vig_hasta <= b.fecha_vig_hasta_endo )
order by cod_ramo_cial, nro_pol, fec_vig_desde



----- validaciones 



select a.*,(sum(A.VR_PRIMA_PESOS_COA) * (B.PARTICIPACION / 100.0)) AS valor_concepto, select top 5* from [Liberty_Pruebas_Actuaria].Attrition.[acc_sise_appgenerali_siniestros_incurridos_fusion] a

left join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_Sise b on (a.cdigo_sucursal = b.cod_suc and a.cdigo_ramo_comercial =b.cod_ramo_cial and a.pliza = b.nro_pol and a.fecha_vig_desde_endo >= b.fec_vig_desde and a.fecha_vig_hasta_endo <=fec_vig_hasta )
where cdigo_sucursal = 1 and cdigo_ramo_comercial = 24
 and	pliza = 4001011



SELECT
'HDI' AS Compañia,
CONVERT(char(6), a.process_dt, 112) AS periodo_contable,
cdigo_agente_principal AS intermediario_inicial,
B.cod_agente AS intermediario_final_asociadao,
A.cdigo_ramo_comercial as ramo_prod,
A.pliza as poliza, 
0 AS modalidad, 
'traer cod_grupo'  AS agrupador, 
'traer tipo_riesgo' AS tipo_riesgo,
A.TIPO_DOC_tomador AS tipo_identifi_tomador,
A.nro_doc_tomador AS Numero_identificacion_tomador,  
'Incurrido' AS macro_concepto,  
'Incurrido-Corretaje_Sise' AS concepto, 
(sum(A.valor_incurrido) * (B.PARTICIPACION / 100.0)) AS valor_concepto,
'[Liberty_Pruebas_Actuaria].Attrition.[acc_sise_appgenerali_siniestros_incurridos_fusion]' as fuente_primaria

from [Liberty_Pruebas_Actuaria].Attrition.[acc_sise_appgenerali_siniestros_incurridos_fusion] A 
left join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_Sise b on (a.cdigo_sucursal = b.cod_suc and a.cdigo_ramo_comercial =b.cod_ramo_cial and a.pliza = b.nro_pol and a.fecha_vig_desde_endo >= b.fec_vig_desde and a.fecha_vig_hasta_endo <=fec_vig_hasta )
left join (SELECT DISTINCT CLAVE_INICIAL_ASOCIADA FROM [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores where cia = 'SISE') g on (B.cod_agente = g.CLAVE_INICIAL_ASOCIADA) 
 where CONVERT(char(6), a.process_dt, 112) BETWEEN 202601 AND 202612 and g.CLAVE_INICIAL_ASOCIADA is not null AND B.nro_pol IS NOT NULL 
 GROUP BY CONVERT(char(6), a.process_dt, 112),
cdigo_agente_principal,
B.cod_agente,
A.cdigo_ramo_comercial ,
A.pliza,
A.TIPO_DOC_tomador,
A.nro_doc_tomador,
B.PARTICIPACION







select cod_suc, cod_ramo_cial, nro_pol,fec_vig_desde,fec_vig_hasta , sum(ppartici)
from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_Sise
group by cod_suc, cod_ramo_cial, nro_pol,fec_vig_desde,fec_vig_hasta
having sum(ppartici) <> 0





select * from  #lideres_produccion where cod_suc = 1 and COD_RAMO_CIAL = 24
 and	nro_pol = 4001011 order by fec_vig_desde

select * from  #lideres_incurridos where cdigo_sucursal = 1 and cdigo_ramo_comercial = 24
 and	pliza = 4001011 order by fecha_vig_desde_endo



1_13_4002708



------- validaciones 




select * from #lideres_produccion where nro_pol= 4000018 and cod_suc = 53 and cod_suc = 50 

select * FROM  #lideres_incurridos
where cod_suc = 42 and nro_pol = 4008873 and cod_suc = 50 



select * from [Liberty_Pruebas_Actuaria].Attrition.[acc_sise_appgenerali_siniestros_incurridos_fusion]
where pliza= 4000379 and cdigo_sucursal = 6 and cdigo_ramo_comercial = 93


select cod_suc, cod_ramo_cial,nro_pol, sum(pje_partic_agente) 
from #lideres_produccion 
group by cod_suc, cod_ramo_cial,nro_pol
having sum(pje_partic_agente)  > 100


select * from #lideres_produccion where cod_suc = 6 and	cod_ramo_cial = 93 and	nro_pol = 4000379

select * from CODMHDI.PLANEACION_RPT.dbo.PRODUCCION_COMPLETA where cod_suc = 6 and	cod_ramo_cial = 93 and	nro_pol = 4000379

select * from #lideres_incurridos where cdigo_sucursal = 6 and	cdigo_ramo_comercial = 93 and	pliza = 4000379
select * from #lideres_produccion where cod_suc = 6 and	cod_ramo_cial = 93 and	nro_pol = 4000379 





