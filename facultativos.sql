	 

	 
		--- facultativos iaxis 
		drop table [Liberty_Pruebas_Actuaria].[dbo].Facultativas

		select y.* 

		into [Liberty_Pruebas_Actuaria].[dbo].Facultativas
		from(

select 'HDISC' as Compania, 
a.periodo_contable, 
COALESCE (MAX(B.intermediario_lide),MAX(C.intermediario_lide)) as intermediario_inicial , 
COALESCE (MAX(B.intermediario_lide),max(C.intermediario_lide)) as intermediario_final_asociado,
a.ramo as ramo_prod,
a.poliza,
COALESCE (max(B.cod_modalidad),max(C.cod_modalidad)) as modalidad,
case when COALESCE (max(B.tipo_poliza),max(C.tipo_poliza)) ='C' then 100 else null end AS agrupador, 
CONCAT('', COALESCE (max(B.COD_PRODUCTO),max(C.COD_PRODUCTO))) AS tipo_riesgo,
COALESCE (max(b.TIPO_identifi_tom),max(C.TIPO_identifi_tom)) AS tipo_identifi_tomador,
COALESCE (max(b.nro_identifi_tom),max(C.nro_identifi_tom)) AS Numero_identificacion_tomador,  
'Primas_Facultativas' AS macro_concepto,  
'Primas_Facultativas_Iaxis' AS concepto, 
sum(A.VALOR_CEDIDO) AS valor_concepto,
'liberty.reservas.cedidas_iaxis' as fuente_primaria

from liberty.reservas.cedidas_iaxis a
left join (
select distinct ramo_prod,poliza,certificado ,RECIBO, intermediario_lide, max(cod_modalidad) as cod_modalidad, max(tipo_poliza) as tipo_poliza, max(COD_PRODUCTO) as COD_PRODUCTO, max( TIPO_identifi_tom) as TIPO_identifi_tom, max(nro_identifi_tom) as nro_identifi_tom
from liberty.prod.dwh_polizas_h where PERIODO_CONTABLE >= 202501 and SIS_ORIGEN = 'N' group by ramo_prod,poliza,certificado ,RECIBO,intermediario_lide) b on (a.ramo=b.ramo_prod and a.poliza=b.poliza and a.certificado=b.certificado and a.documento=b.RECIBO )
left join (
select distinct ramo_prod,poliza,certificado, max(intermediario_lide) as intermediario_lide, max(cod_modalidad) as cod_modalidad, max(tipo_poliza) as tipo_poliza, max(COD_PRODUCTO) as COD_PRODUCTO, max( TIPO_identifi_tom) as TIPO_identifi_tom, max(nro_identifi_tom) as nro_identifi_tom
from liberty.prod.dwh_polizas_h where PERIODO_CONTABLE >= 202501 and SIS_ORIGEN = 'N'  group by ramo_prod,poliza,certificado ) C on (a.ramo=C.ramo_prod and a.poliza=C.poliza and a.certificado=C.certificado )
WHERE TIPO_CONTRATO = 'F' AND a.PERIODO_CONTABLE between 202601 and 202612
group by a.periodo_contable, a.ramo,a.poliza

union all 


select 'HDISC' as Compania, 
z.periodo_contable, 
z.intermediario_inicial , 
d.agente as intermediario_final_asociado,
z.ramo_prod ,
z.poliza,
z.modalidad,
z.agrupador, 
z.tipo_riesgo,
z.tipo_identifi_tomador,
z. Numero_identificacion_tomador,  
'Primas_Facultativas' AS macro_concepto,  
'Primas_Facultativas_Iaxis_CO-Corretaje' AS concepto, 
(sum(z.VALOR_CEDIDO) * (d.PARTICIPACION / 100.0)) AS valor_concepto,
'liberty.reservas.cedidas_iaxis' as fuente_primaria


from  (
select 
COALESCE (MAX(B.sseguro),MAX(C.sseguro)) as sseguro,
a.periodo_contable, 
COALESCE (MAX(B.intermediario_lide),MAX(C.intermediario_lide)) as intermediario_inicial , 
a.ramo as ramo_prod,
a.poliza,
a.certificado,
COALESCE (max(b.documento),max(c.documento)) as documento,
COALESCE (max(b.cod_modalidad),max(C.cod_modalidad)) as modalidad,
case when COALESCE (max(B.tipo_poliza),max(C.tipo_poliza)) ='C' then 100 else null end AS agrupador, 
CONCAT('', COALESCE (max(B.COD_PRODUCTO),max(C.COD_PRODUCTO))) AS tipo_riesgo,
COALESCE (max(b.TIPO_identifi_tom),max(C.TIPO_identifi_tom)) AS tipo_identifi_tomador,
COALESCE (max(b.nro_identifi_tom),max(C.nro_identifi_tom)) AS Numero_identificacion_tomador,  
sum(A.VALOR_CEDIDO) as VALOR_CEDIDO

from liberty.reservas.cedidas_iaxis a
left join (
select distinct sseguro,ramo_prod,poliza,certificado ,RECIBO, intermediario_lide, max(documento) as documento ,max(cod_modalidad) as cod_modalidad, max(tipo_poliza) as tipo_poliza, max(COD_PRODUCTO) as COD_PRODUCTO, max( TIPO_identifi_tom) as TIPO_identifi_tom, max(nro_identifi_tom) as nro_identifi_tom
from liberty.prod.dwh_polizas_h where PERIODO_CONTABLE >= 202501  and SIS_ORIGEN = 'N' group by sseguro,ramo_prod,poliza,certificado,RECIBO,intermediario_lide) b on (a.ramo=b.ramo_prod and a.poliza=b.poliza and a.certificado=b.certificado and a.documento=b.RECIBO )
left join (
select distinct sseguro,ramo_prod,poliza,certificado, max(intermediario_lide) as intermediario_lide, max(documento) as documento , max(cod_modalidad) as cod_modalidad, max(tipo_poliza) as tipo_poliza, max(COD_PRODUCTO) as COD_PRODUCTO, max( TIPO_identifi_tom) as TIPO_identifi_tom, max(nro_identifi_tom) as nro_identifi_tom
from liberty.prod.dwh_polizas_h where PERIODO_CONTABLE >= 202501  and SIS_ORIGEN = 'N'  group by sseguro,ramo_prod,poliza,certificado ) C on (a.ramo=C.ramo_prod and a.poliza=C.poliza and a.certificado=C.certificado )
WHERE TIPO_CONTRATO = 'F' AND a.PERIODO_CONTABLE between 202601 and 202612
group by a.periodo_contable, a.ramo,a.poliza,a.CERTIFICADO) z
left join [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis d on (z.ramo_prod =  d.RAMO_PROD AND z.POLIZA=d.POLIZA AND  z.documento=d.DOCUMENTO_PRIMA and z.sseguro  = d.SSEGURO)
WHERE d.SSEGURO is not null 
group by 
z.periodo_contable, 
z.intermediario_inicial, 
d.agente,
d.PARTICIPACION,
z.ramo_prod,
z.poliza,
z.modalidad,
z.agrupador, 
z.tipo_riesgo,
z.tipo_identifi_tomador,
z. Numero_identificacion_tomador 

UNION ALL



select 'HDISC' as Compania, 
a.peco AS periodo_contable, 
COALESCE (MAX(B.intermediario_lide),MAX(C.intermediario_lide)) as intermediario_inicial , 
COALESCE (MAX(B.intermediario_lide),max(C.intermediario_lide)) as intermediario_final_asociado,
a.ramo as ramo_prod,
a.poli AS poliza,
COALESCE (max(B.cod_modalidad),max(C.cod_modalidad)) as modalidad,
case when COALESCE (max(B.tipo_poliza),max(C.tipo_poliza)) ='C' then 100 else null end AS agrupador, 
CONCAT('', COALESCE (max(B.COD_PRODUCTO),max(C.COD_PRODUCTO))) AS tipo_riesgo,
COALESCE (max(b.TIPO_identifi_tom),max(C.TIPO_identifi_tom)) AS tipo_identifi_tomador,
COALESCE (max(b.nro_identifi_tom),max(C.nro_identifi_tom)) AS Numero_identificacion_tomador,  
'Primas_Facultativas' AS macro_concepto,  
'Primas_Facultativas_AS400' AS concepto, 
sum(A.vces) AS valor_concepto,
'liberty.reservas.cedidas' as fuente_primaria
from liberty.reservas.cedidas a 
left join (
select distinct ramo_prod,poliza,certificado ,ANEXO, intermediario_lide, max(cod_modalidad) as cod_modalidad, max(tipo_poliza) as tipo_poliza, max(COD_PRODUCTO) as COD_PRODUCTO, max( TIPO_identifi_tom) as TIPO_identifi_tom, max(nro_identifi_tom) as nro_identifi_tom
from liberty.prod.dwh_polizas_h where PERIODO_CONTABLE >= 202501 and SIS_ORIGEN = 'O' group by ramo_prod,poliza,certificado ,ANEXO,intermediario_lide) b on (a.ramo=b.ramo_prod and a.poli=b.poliza and a.CERT=b.certificado and a.ANEX=b.ANEXO )
left join (
select distinct ramo_prod,poliza,certificado, max(intermediario_lide) as intermediario_lide, max(cod_modalidad) as cod_modalidad, max(tipo_poliza) as tipo_poliza, max(COD_PRODUCTO) as COD_PRODUCTO, max( TIPO_identifi_tom) as TIPO_identifi_tom, max(nro_identifi_tom) as nro_identifi_tom
from liberty.prod.dwh_polizas_h where PERIODO_CONTABLE >= 202501 and SIS_ORIGEN = 'O'  group by ramo_prod,poliza,certificado ) C on (a.ramo=C.ramo_prod and a.poli=C.poliza and a.CERT=C.certificado )
WHERE DCON = 'F' AND a.peco between 202601 and 202612
group by a.peco, a.ramo,a.poli

) y
left join (SELECT DISTINCT CLAVE_INICIAL_ASOCIADA FROM [Liberty_Pruebas_Actuaria].[dbo].claves_asociadas_pu_corredores where cia = 'IAXIS') g on (y.intermediario_final_asociado = g.CLAVE_INICIAL_ASOCIADA) 
where g.CLAVE_INICIAL_ASOCIADA is not null



---- VALIDAR TOTALES ANTES DEL CRUCE CON claves_asociadas_pu_corredores , SE VALIDAN CON NUBIA



--- validaciones
select sum(valor_concepto)  from [Liberty_Pruebas_Actuaria].[dbo].Facultativas where concepto ='Primas_Facultativas_Iaxis_CO-Corretaje'