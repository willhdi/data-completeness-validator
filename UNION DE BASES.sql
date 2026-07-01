	 


DROP TABLE LIBERTY_PRUEBAS_ACTUARIA.DBO.SINIESTRALIDAD_2026
SELECT * 
INTO LIBERTY_PRUEBAS_ACTUARIA.DBO.SINIESTRALIDAD_2026


FROM (

select  COMPANIA, PERIODO_CONTABLE,sbu,intermediario_final,clave_lider,ramo_prod,modalidad,AGRUPADOR,CONCAT('',TIPO_RIESGO) AS TIPO_RIESGO ,'devengada' as macro_concepto, concepto,poliza, SUM(valor_concepto) as valor_concepto,b.sucursal, b.zona,b.canal,b.subcanal
from liberty_pruebas_actuaria.dbo.DEVENGADA_general  a
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final =b.clave_asociada_inicial ) 
-- where periodo_contable = 202605
group by COMPANIA,PERIODO_CONTABLE,sbu,intermediario_final,concepto,ramo_prod,modalidad,poliza,clave_lider,COMPANIA,AGRUPADOR,TIPO_RIESGO,b.sucursal, b.zona,b.canal,b.subcanal

union all

sELECT  COMPANIA,periodo_contable,sbu,intermediario_final_asociado as intermediario_final,clave_lider,a.ramo_prod,modalidad,AGRUPADOR,CONCAT('',TIPO_RIESGO) AS TIPO_RIESGO,'devengada' as macro_concepto, concepto,poliza,SUM(VALOR_CONCEPTO)  as VALOR_CONCEPTO ,b.sucursal, b.zona,b.canal,b.subcanal
FROM [Liberty_Pruebas_Actuaria].[dbo].Emitida_general a 
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final_asociado =b.clave_asociada_inicial ) 
left join  [Liberty_Pruebas_Actuaria].[dbo].ramos_producto c on (a.compania = c.cia and a.ramo_prod = c.ramo_prod)
--where periodo_contable = 202605 
group by COMPANIA,periodo_contable,sbu,intermediario_final_asociado ,a.ramo_prod,modalidad, concepto,poliza,clave_lider,AGRUPADOR,TIPO_RIESGO,b.sucursal, b.zona,b.canal,b.subcanal

union all

select  COMPANIA,PERIODO_CONTABLE,COALESCE (c.sbu,d.sbu) AS sbu,intermediario_final_ASOCIADO as intermediario_final,clave_lider,a.ramo_prod,modalidad,AGRUPADOR,CONCAT('',TIPO_RIESGO) AS TIPO_RIESGO,'incurrido' as macro_concepto,concepto,poliza, SUM(valor_concepto) as valor_concepto,b.sucursal, b.zona,b.canal,b.subcanal
from liberty_pruebas_actuaria.dbo.SINIESTROS_GENERAL_IAXIS  a 
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final_ASOCIADO =b.clave_asociada_inicial ) 
left join  [Liberty_Pruebas_Actuaria].[dbo].ramos_producto c on (a.compania = c.cia and a.ramo_prod = c.ramo_prod)
left join  Liberty.APOYO.DWH_SBU_RAMO_PROD d  on (a.ramo_prod = d.ramo_prod)
where  MACRO_CONCEPTO NOT IN ('SALVAMENTOS','RECOBROS')--- and periodo_contable = 202605 
group by COMPANIA,PERIODO_CONTABLE,d.sbu,c.sbu,intermediario_final_ASOCIADO,modalidad,concepto,a.ramo_prod,poliza,clave_lider,AGRUPADOR,TIPO_RIESGO,b.sucursal, b.zona,b.canal,b.subcanal

union all

select  COMPANIA,PERIODO_CONTABLE,COALESCE (c.sbu,d.sbu) AS sbu,intermediario_final_ASOCIADO  as intermediario_final,clave_lider,a.ramo_prod,modalidad,AGRUPADOR,CONCAT('',TIPO_RIESGO) AS TIPO_RIESGO,'incurrido' as macro_concepto,concepto,poliza, SUM(valor_concepto)*-1 as valor_concepto,b.sucursal, b.zona,b.canal,b.subcanal
from liberty_pruebas_actuaria.dbo.SINIESTROS_GENERAL_IAXIS  a
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final_ASOCIADO =b.clave_asociada_inicial ) 
left join  [Liberty_Pruebas_Actuaria].[dbo].ramos_producto c on (a.compania = c.cia and a.ramo_prod = c.ramo_prod)
left join  Liberty.APOYO.DWH_SBU_RAMO_PROD d  on (a.ramo_prod = d.ramo_prod)
where MACRO_CONCEPTO IN ('SALVAMENTOS','RECOBROS') ---and periodo_contable = 202605 
group by COMPANIA,PERIODO_CONTABLE,d.sbu,c.sbu,intermediario_final_ASOCIADO,modalidad,concepto,a.ramo_prod,poliza,clave_lider,AGRUPADOR,TIPO_RIESGO,b.sucursal, b.zona,b.canal,b.subcanal


union all

sELECT  Compania, periodo_contable,sbu,intermediario_final_asociadao as intermediario_final,clave_lider,concat('',a.ramo_prod) as ramo_prod,modalidad,AGRUPADOR,CONCAT('',TIPO_RIESGO) AS TIPO_RIESGO,'incurrido' as macro_concepto, concepto,poliza,SUM(VALOR_CONCEPTO)  as valor_concepto ,b.sucursal, b.zona,b.canal,b.subcanal
FROM [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISE a 
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final_asociadao =b.clave_asociada_inicial ) 
left join  [Liberty_Pruebas_Actuaria].[dbo].ramos_producto c on (a.compania = c.cia and concat('',a.ramo_prod) = concat('',c.ramo_prod))
---where periodo_contable = 202605 
group by periodo_contable,sbu,intermediario_final_asociadao ,a.ramo_prod,modalidad, concepto,poliza,clave_lider,Compania,AGRUPADOR,TIPO_RIESGO,b.sucursal, b.zona,b.canal,b.subcanal

) A





select periodo_contable, Concepto,macro_concepto,SUM(valor_concepto)
from LIBERTY_PRUEBAS_ACTUARIA.DBO.SINIESTRALIDAD_2026
group by periodo_contable, Concepto,macro_concepto

select periodo_contable, Concepto,SUM(valor_concepto)
from LIBERTY_PRUEBAS_ACTUARIA.DBO.NUEVA_BASE_SINIESTRALIDAD
group by periodo_contable, Concepto


SELECT SUM(VALOR_CONCEPTO) FROM  LIBERTY_PRUEBAS_ACTUARIA.DBO.NUEVA_BASE_SINIESTRALIDAD where concepto IN ('Recobros_IAXIS','Recobros_As400','Salvamentos_As400','Salvamentos_IAXIS')

SELECT COUNT(*) FROM  LIBERTY_PRUEBAS_ACTUARIA.DBO.NUEVA_BASE_SINIESTRALIDAD A
LEFT JOIN  liberty_pruebas_actuaria.dbo.exclusiones_coco B ON (A.ramo_prod = B.ramo_prod AND A.poliza = B.poliza)
WHERE B.ramo_prod IS NULL


select *
from liberty_pruebas_actuaria.dbo.SINIESTROS_GENERAL_IAXIS a
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final_ASOCIADO =b.clave_asociada_inicial ) 
where periodo_contable = 202605 AND MACRO_CONCEPTO IN ('RECOBROS') 
ORDER BY periodo_contable, concepto,macro_concepto, ramo_prod

SELECT *  FROM  LIBERTY_PRUEBAS_ACTUARIA.DBO.NUEVA_BASE_SINIESTRALIDAD where clave_lider = 3725

  and macro_concepto = 'incurrido'


  select * from [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada where clave_lider = 596


select distinct macro_concepto, concepto  from liberty_pruebas_actuaria.dbo.SINIESTROS_GENERAL_IAXIS a order by macro_concepto
left join [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada b on (a.intermediario_final_ASOCIADO =b.clave_asociada_inicial ) 
where 



select * from  LIBERTY_PRUEBAS_ACTUARIA.DBO.DATOS_DHI_SOBRECOMISIONES_2025_validaciones
union all
select * from	where periodo_contable BETWEEN 202603 AND 202605

select sum(incurrido_no_auto), sum(incurrido_auto) from LIBERTY_PRUEBAS_ACTUARIA.DBO.DATOS_DHI_SOBRECOMISIONES_2025_detalle_VALIDACION where cod_clave_lider = 30234



select * from liberty.[MIDDLEWARE].[DWH_REASEGURO_H] where PERIODO = 202605 and  cuenta_local in (411105
,511105,411110,511110)
and subcuenta_local in (101
,102,103,104,105,106,199,201,202,502,602,
701,702,704,706,707,708
,709,301,302,405,18,724,723,101,1202,104
,1301,17,18,502,719,704,1201
)



select periodo_contable, macroconcepto, concepto, fuente_primaria, sum(valor_concepto) 
from liberty_pruebas_actuaria.dbo.DEVENGADA_general
group by periodo_contable, macroconcepto, concepto, fuente_primaria




select * from  [Liberty_Pruebas_Actuaria].[dbo].red_comercial_integrada 


select * from [Liberty].[APOYO].[DWH_REDCOMERCIAL_BASE_CLAVES_ACTIVAS] 

select * 
from [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISE_mayo
where periodo_contable = 202512 and intermediario_inicial =56 and ramo_prod = 50 and poliza = 
133 order by Concepto 


select periodo_contable,concepto,SUM(valor_concepto) 
from [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISe
--where periodo_contable = 202602 ---and ramo_prod = 34
group by periodo_contable,concepto,ramo_prod


select periodo_contable,concepto,SUM(valor_concepto) 
from [Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISe_mayo
--where periodo_contable = 202602 ---and ramo_prod = 34 
group by periodo_contable,concepto,ramo_prod




select distinct ramo_prod  from [Liberty_Pruebas_Actuaria].[dbo].Emitida_general order by ramo_prod




----- validacion convencion




select * from LIBERTY_PRUEBAS_ACTUARIA.DBO.SINIESTRALIDAD_2026 
where clave_lider = 10014 and periodo_contable > 202601 order by Concepto 



select * 
from LIBERTY_PRUEBAS_ACTUARIA.DBO.SINIESTRALIDAD_2026 