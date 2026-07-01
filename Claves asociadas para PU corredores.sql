
drop table #iaxis
select distinct f.* 
into #iaxis
from

(
select distinct a.CLAVE_inicial as clave_inicial_asociada , 'HDISC' AS CIA
from [Liberty_Pruebas_Actuaria].[dbo].[TRASLADOS_UNICO_REG] A
LEFT JOIN (select B.LLAVE from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores') A
LEFT JOIN liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS B ON (A.CLAVE_LIDER = B.CLAVE_LIDER) ) B ON (B.LLAVE = A.CLAVE_FINAL)
WHERE  B.LLAVE IS NOT NULL AND A.TIPO NOT IN ('Traslado HDI','Cesión HDI') 

union all

select distinct a.CLAVE_inicial as clave_inicial_asociada , 'HDI' AS CIA
from [Liberty_Pruebas_Actuaria].[dbo].[TRASLADOS_UNICO_REG] A
LEFT JOIN (select B.LLAVE from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores') A
LEFT JOIN liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS B ON (A.CLAVE_LIDER = B.CLAVE_LIDER) ) B ON (B.LLAVE = A.CLAVE_FINAL)
WHERE  B.LLAVE IS NOT NULL AND A.TIPO  IN ('Traslado HDI','Cesión HDI') 

union all
select distinct B.LLAVE as clave_inicial_asociada , 'HDISC' AS CIA
from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores') A
LEFT JOIN liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS B ON (A.CLAVE_LIDER = B.CLAVE_LIDER)

union all
select distinct B.clave as clave_inicial_asociada , 'HDISC' AS CIA
from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores') A
LEFT JOIN [Liberty].[APOYO].[DWH_REDCOMERCIAL_BASE_CLAVES_ACTIVAS] B ON (A.CLAVE_LIDER = B.LIDER_NAL)) f


--  se incluye claves activas en la logica por que red comercial tienen diferencias con activas en lideres . se mantiene la red por que tienen toda la historia. 

--- OJO , INCLUIR LAS CLAVES QUE TIENEN PRIMAS POR CO-CORRETAJE CON CLAVES DE PU CORREDORES ESTO ESTA PENDIENTE VER POR QUE EN PRIMAS YA SE HIZO. 30-06-2026


DROP TABLE [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores

select distinct clave_inicial_asociada, cia
into [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores
from 
(
select * from #iaxis
union all 
select cast(cod_intermediario_hdi as int) AS clave_inicial_asociada, 'HDI' AS CIA from  openquery(CODWHHDI,'SELECT * FROM stg.excel_com_Maestro_intermediarios_Homologados') a
left join #iaxis b on a.cod_intermediario_homologado = b.clave_inicial_asociada
where cod_intermediario_hdi is not null and b.clave_inicial_asociada is not null) z




------- VALIDACIONES 






SELECT * FROM  [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores WHERE clave_inicial_asociada IN (94589)



select * from  openquery(CODWHHDI,'SELECT * FROM stg.excel_com_Maestro_intermediarios_Homologados') where cod_intermediario_hdi in (18,11)

select * from [Liberty_Pruebas_Actuaria].[dbo].[TRASLADOS_UNICO_REG] where clave_final in (96279)

select * from liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS where llave = 16166

into [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores
from 
(
select distinct clave_inicial as clave_inicial_asociada , 'IAXIS' AS CIA
from [Liberty_Pruebas_Actuaria].[dbo].[TRASLADOS_UNICO_REG] A
LEFT JOIN (select B.LLAVE from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores') A
LEFT JOIN liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS B ON (A.CLAVE_LIDER = B.CLAVE_LIDER) ) B ON (B.LLAVE = A.CLAVE_FINAL)
WHERE  A.CLAVE_FINAL IS NOT NULL
 
 
union all
select B.LLAVE as clave_inicial_asociada , 'IAXIS' AS CIA 
from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores') A
LEFT JOIN liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS B ON (A.CLAVE_LIDER = B.CLAVE_LIDER)
 
--- unir estas dos bases _ 
union all 
select cast(cod_intermediario_hdi as int) AS clave_inicial_asociada, 'SISE' AS CIA from  openquery(CODWHHDI,'SELECT * FROM stg.excel_com_Maestro_intermediarios_Homologados') a
left join (select CLAVE_LIDER from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores')) b 
on a.cod_CLAVE_LIDER = b.clave_lider
where cod_intermediario_hdi is not null and b.clave_lider is not null) z



SELECT DISTINCT f.cod_intermediario_hdi AS clave_faltante
select * FROM openquery(CODWHHDI,'SELECT * FROM stg.excel_com_Maestro_intermediarios_Homologados') f
LEFT JOIN Liberty_Pruebas_Actuaria.dbo.claves_asociadas_pu_corredores t
    ON f.cod_intermediario_hdi = t.clave_inicial_asociada
    AND t.cia = 'HDI'
WHERE t.clave_inicial_asociada IS NULL;


select * FROM openquery(CODWHHDI,'SELECT * FROM stg.excel_com_Maestro_intermediarios_Homologados') where cod_intermediario_hdi = 741

SELECT * FROM  [Liberty_Pruebas_Actuaria].[dbo].[TRASLADOS_UNICO_REG] where clave_inicial = 16166

select distinct clave_lider from liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS where llave in (92679)


select distinct * from liberty.APOYO.DWH_REDCOMERCIAL_INTERMEDIARIOS where llave  in (741) order by llave

select * from  openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores') where clave_lider = 3068


select * from [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores where clave_inicial_asociada = 3068
select * from #iaxis where clave_inicial_asociada = 3068

select * from [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores_ a
left join  [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores b on (a.clave_inicial_asociada=b.clave_inicial_asociada and a.cia=b.cia)
where b.clave_inicial_asociada is null

 select * from openquery(CODWHHDI,'SELECT * FROM stg.excel_com_lideres_pu_corredores')


 SELECT* FROM [Liberty_Pruebas_Actuaria].[dbo].polizas_Excluidas_PU