/* LIMPIEZA DE TEMPORALES */
IF OBJECT_ID('tempdb..#CORRETAJES_BASE') IS NOT NULL
    DROP TABLE #CORRETAJES_BASE;

IF OBJECT_ID('tempdb..#POLIZAS_BASE') IS NOT NULL
    DROP TABLE #POLIZAS_BASE;

IF OBJECT_ID('tempdb..#DOCUMENTOS_UNIVERSO') IS NOT NULL
    DROP TABLE #DOCUMENTOS_UNIVERSO;

IF OBJECT_ID('tempdb..#DOCUMENTOS_RESUELTOS') IS NOT NULL
    DROP TABLE #DOCUMENTOS_RESUELTOS;

IF OBJECT_ID('tempdb..#POLIZAS_CORRETAJE') IS NOT NULL
    DROP TABLE #POLIZAS_CORRETAJE;

IF OBJECT_ID('tempdb..#lideres_faltantes') IS NOT NULL
DROP TABLE #lideres_faltantes;

IF OBJECT_ID('tempdb..#DWH_AGE_CORRETAJE') IS NOT NULL
DROP TABLE #DWH_AGE_CORRETAJE;


   SELECT f.SSEGURO,f.NMOVIMI, max(intermediario_lide) as cagente, 1 as lider 
   into #lideres_faltantes
   from 
   (select a.SSEGURO,
            NMOVIMI,
            sum(ISLIDER) as lider
			FROM Liberty.PROD.DWH_AGE_CORRETAJE a
			group by a.sSEGURO,
            NMOVIMI
		having sum(ISLIDER) <> 1
		) f
		left join liberty.prod.dwh_polizas_h b on (f.sseguro = b.sseguro and b.documento = f.nmovimi)
		where b.PERIODO_CONTABLE >= 202001
		group by f.SSEGURO,f.NMOVIMI

	


	        SELECT
            a.SSEGURO,
            a.CAGENTE,
            a.NMOVIMI,
            a.PPARTICI,
            coalesce (b.lider,a.ISLIDER) as ISLIDER
			into #DWH_AGE_CORRETAJE
        FROM Liberty.PROD.DWH_AGE_CORRETAJE a
		left join #lideres_faltantes b on (a.SSEGURO = b.SSEGURO and a.NMOVIMI = b.NMOVIMI and a.CAGENTE - 4000000 =b.CAGENTE)
		where PPARTICI <> 100 and PPARTICI <> 0




SELECT
    Z.SSEGURO,
    CASE 
        WHEN Z.CAGENTE >= 4000000 THEN Z.CAGENTE - 4000000
        ELSE Z.CAGENTE
    END AS AGENTE,
    Z.NMOVIMI,
    CASE
        WHEN Z.ISLIDER = 1 THEN Z.PPARTICI - 100
        ELSE Z.PPARTICI
    END AS PARTICIPACION,
    CASE
        WHEN Z.ISLIDER = 1 THEN 1
        ELSE 0
    END AS ES_LIDER
INTO #CORRETAJES_BASE
FROM (
        SELECT
            SSEGURO,
            CAGENTE,
            NMOVIMI,
            PPARTICI,
            ISLIDER
        FROM Liberty_Pruebas_Actuaria.dbo.corretajes_faltantes where sseguro = 123456789  ----- ojo dejo este filtro por que ya no deberia tenerse en cuenta los registros errados se aliminaron, pero lo dejo por si hay que incluir casos

        UNION ALL

        SELECT
            SSEGURO,
            CAGENTE,
            NMOVIMI,
            PPARTICI,
            ISLIDER
        FROM #DWH_AGE_CORRETAJE
     ) Z
WHERE Z.SSEGURO IS NOT NULL;

SELECT DISTINCT
    p.SSEGURO,
    p.RAMO_PROD,
    p.POLIZA,
    p.CERTIFICADO,
    p.DOCUMENTO,
	p.RECIBO
INTO #POLIZAS_BASE
FROM Liberty.PROD.DWH_POLIZAS_H p
WHERE p.SSEGURO IS NOT NULL;


SELECT DISTINCT
    c.SSEGURO,
    c.NMOVIMI AS DOCUMENTO_PRIMA
INTO #DOCUMENTOS_UNIVERSO
FROM #CORRETAJES_BASE c

UNION

SELECT DISTINCT
    p.SSEGURO,
    p.DOCUMENTO AS DOCUMENTO_PRIMA
FROM #POLIZAS_BASE p
WHERE NOT EXISTS (
    SELECT 1
    FROM #CORRETAJES_BASE c
    WHERE c.SSEGURO = p.SSEGURO
      AND c.NMOVIMI = p.DOCUMENTO
);


SELECT
    u.SSEGURO,
    u.DOCUMENTO_PRIMA,

    (
        SELECT MAX(c.NMOVIMI)
        FROM #CORRETAJES_BASE c
        WHERE c.SSEGURO = u.SSEGURO
          AND c.NMOVIMI <= u.DOCUMENTO_PRIMA
    ) AS NMOVIMI_RESUELTO,

    (
        SELECT MAX(p.DOCUMENTO)
        FROM #POLIZAS_BASE p
        WHERE p.SSEGURO = u.SSEGURO
          AND p.DOCUMENTO <= u.DOCUMENTO_PRIMA
    ) AS DOCUMENTO_POLIZA_RESUELTO
INTO #DOCUMENTOS_RESUELTOS
FROM #DOCUMENTOS_UNIVERSO u;

SELECT DISTINCT
    r.SSEGURO,
    pfill.RAMO_PROD,
    pfill.POLIZA,
    pfill.CERTIFICADO,
    r.DOCUMENTO_PRIMA,
    c.PARTICIPACION,
    c.AGENTE,
    c.ES_LIDER
INTO #POLIZAS_CORRETAJE
FROM #DOCUMENTOS_RESUELTOS r
LEFT JOIN #POLIZAS_BASE pfill
    ON r.SSEGURO = pfill.SSEGURO
   AND r.DOCUMENTO_POLIZA_RESUELTO = pfill.DOCUMENTO
LEFT JOIN #CORRETAJES_BASE c
    ON r.SSEGURO = c.SSEGURO
   AND r.NMOVIMI_RESUELTO = c.NMOVIMI
WHERE r.NMOVIMI_RESUELTO IS NOT NULL;

drop table [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis_MAYO
/* RESULTADO FINAL */
SELECT 
    SSEGURO,
    RAMO_PROD,
    POLIZA,
    CERTIFICADO,
    DOCUMENTO_PRIMA,
    PARTICIPACION,
    AGENTE,
    ES_LIDER
	into [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis_MAYO
FROM #POLIZAS_CORRETAJE
ORDER BY SSEGURO, DOCUMENTO_PRIMA, AGENTE, ES_LIDER;




---- ARREGLO DE CO-RETAJE, LAS BASES DE REASEGURO TIENE RECIBO EN VEZ DE DOCUMENTO. SE AJUSTA para traer todos los recibos 



SELECT DISTINCT
    r.SSEGURO,
    pfill.RAMO_PROD,
    pfill.POLIZA,
    pfill.CERTIFICADO,
	pfill.RECIBO,
    r.DOCUMENTO_PRIMA,
    c.PARTICIPACION,
    c.AGENTE,
    c.ES_LIDER
INTO #POLIZAS_CORRETAJE_REASEGURO
FROM #DOCUMENTOS_RESUELTOS r
LEFT JOIN #POLIZAS_BASE pfill
    ON r.SSEGURO = pfill.SSEGURO
   AND r.DOCUMENTO_POLIZA_RESUELTO = pfill.DOCUMENTO
LEFT JOIN #CORRETAJES_BASE c
    ON r.SSEGURO = c.SSEGURO
   AND r.NMOVIMI_RESUELTO = c.NMOVIMI
WHERE r.NMOVIMI_RESUELTO IS NOT NULL;

drop table [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis_REASEGURO
/* RESULTADO FINAL */
SELECT 
    SSEGURO,
    RAMO_PROD,
    POLIZA,
    CERTIFICADO,
    DOCUMENTO_PRIMA,
	RECIBO,
    PARTICIPACION,
    AGENTE,
    ES_LIDER
	into [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis_REASEGURO
FROM #POLIZAS_CORRETAJE_REASEGURO
ORDER BY SSEGURO, DOCUMENTO_PRIMA, AGENTE, ES_LIDER;



---- fIN PROCESO ---- 


select * from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis_REASEGURO WHERE POLIZA = 579593 ORDER BY DOCUMENTO_PRIMA---AND CERTIFICADO = 11

select sseguro, ramo_prod,certificado,documento_prima,agente, count(*)
from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis_REASEGURO 
group by sseguro, ramo_prod,certificado,DOCUMENTO_PRIMA,agente
having count(*)>1



---WHERE POLIZA =579593 ORDER BY DOCUMENTO_PRIMA--- AND CERTIFICADO = 11
select count(*) from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis 

---WHERE POLIZA =579593 ORDER BY DOCUMENTO_PRIMA---AND CERTIFICADO = 11

select * from liberty.prod.dwh_polizas_h  where ramo_prod ='900742' and poliza=	579593	and certificado =0 	  and periodo_contable >= 202001




---- validaciones ---- ----


653916






select sseguro, ramo_prod, poliza, documento_prima, sum(participacion)

from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis 
group by sseguro, ramo_prod, poliza, documento_prima
having sum(participacion) >1



select * from [Liberty_Pruebas_Actuaria].[dbo].polizas_corretaje_iaxis_ where sseguro = 51788780 order by DOCUMENTO_PRIMA 

select * from  #lideres_faltantes where sseguro = 23834889 



	
 order by DOCUMENTO_PRIMA 


select * from Liberty.PROD.DWH_AGE_CORRETAJE  where sseguro = 15543707 order by nmovimi



select SUCURSAL_PROD, SUM(VR_PRIMA_PESOS_COA
) from Liberty.prod.dwh_polizas_h where periodo_contable >= 201601 



no escriba sobre la misma tabl o procedimiento 



select * from co_sandbox_datos.fact_prod_poliza_riesgo_corretaje