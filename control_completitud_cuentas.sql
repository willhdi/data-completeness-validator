
/* ==========================================================================
   CONTROL DE COMPLETITUD DE CUENTAS CONTABLES — DWH
   Ejecutar: días 8-9 de cada mes, antes del proceso oficial de cierre (día 10)
   Propósito: detectar cuentas con VALOR_RESERVA_CONTABLE nulo por periodo/libro
              y alertar al dueño de la tabla antes de que sea tarde.

   Cuentas excluidas por diseño (usan tablas propias, no están aquí):
     - Incurrido    → Liberty_Pruebas_Actuaria.dbo.SINIESTROS_GENERAL_*
     - Salvamentos  → Liberty.AS400.REFIGVDT
     - Recobros     → Liberty_Pruebas_Actuaria.dbo.Recobros_IAXIS
     - IVA AG       → cubierto por el filtro Libro <> 'AG'
     - (2 cuentas adicionales pendientes de confirmar con Andrey)

   Semáforo de resultado:
     COMPLETO → sin_valor = 0  → OK para correr el proceso de cierre
     ALERTA   → sin_valor > 0  → avisar al dueño de la tabla
   ==========================================================================*/


-- Ajustar al periodo a verificar (YYYYMM)
DECLARE @PERIODO INT = 202708;


SELECT
    fuente,
    cuenta,
    libro,
    periodo_contable_analisis,
    total_registros,
    con_valor,
    sin_valor,
    CAST(ROUND(100.0 * con_valor / NULLIF(total_registros, 0), 2) AS DECIMAL(5,2)) AS pct_completitud,
    semaforo
FROM
(

    /* ------------------------------------------------------------------ */
    /* 1. DIRECTA — IAXIS                                                  */
    /* Fuente: Liberty.RESERVAS.DIRECTA_RESERVA_INTERFAZ                  */
    /* ------------------------------------------------------------------ */
    SELECT
        'DIRECTA_IAXIS'                                                     AS fuente,
        a.CUENTA                                                            AS cuenta,
        a.Libro                                                             AS libro,
        a.periodo_contable_analisis,
        COUNT(*)                                                            AS total_registros,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NOT NULL THEN 1 ELSE 0 END) AS con_valor,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL     THEN 1 ELSE 0 END) AS sin_valor,
        CASE
            WHEN SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END) = 0
            THEN 'COMPLETO'
            ELSE 'ALERTA'
        END                                                                 AS semaforo
    FROM Liberty.RESERVAS.DIRECTA_RESERVA_INTERFAZ a
    WHERE a.periodo_contable_analisis = @PERIODO
      AND a.CUENTA IN ('410305','410310','410315','510305','510310','510315')
      AND a.Libro <> 'AG'
    GROUP BY
        a.CUENTA,
        a.Libro,
        a.periodo_contable_analisis

    UNION ALL

    /* ------------------------------------------------------------------ */
    /* 2. CEDIDAS — AS400                                                  */
    /* Fuente: Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ                  */
    /* ------------------------------------------------------------------ */
    SELECT
        'CEDIDAS_AS400'                                                     AS fuente,
        a.CUENTA                                                            AS cuenta,
        a.LIBRO                                                             AS libro,
        a.periodo_contable_analisis,
        COUNT(*)                                                            AS total_registros,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NOT NULL THEN 1 ELSE 0 END) AS con_valor,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL     THEN 1 ELSE 0 END) AS sin_valor,
        CASE
            WHEN SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END) = 0
            THEN 'COMPLETO'
            ELSE 'ALERTA'
        END                                                                 AS semaforo
    FROM Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ a
    WHERE a.periodo_contable_analisis = @PERIODO
      AND a.CUENTA IN ('510305','410305')
      AND a.LIBRO <> 'AG'
      AND a.RAMO_PROD IS NOT NULL
    GROUP BY
        a.CUENTA,
        a.LIBRO,
        a.periodo_contable_analisis

    UNION ALL

    /* ------------------------------------------------------------------ */
    /* 3. CEDIDAS — IAXIS                                                  */
    /* Fuente: Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS            */
    /* ------------------------------------------------------------------ */
    SELECT
        'CEDIDAS_IAXIS'                                                     AS fuente,
        a.CUENTA                                                            AS cuenta,
        a.LIBRO                                                             AS libro,
        a.periodo_contable_analisis,
        COUNT(*)                                                            AS total_registros,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NOT NULL THEN 1 ELSE 0 END) AS con_valor,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL     THEN 1 ELSE 0 END) AS sin_valor,
        CASE
            WHEN SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END) = 0
            THEN 'COMPLETO'
            ELSE 'ALERTA'
        END                                                                 AS semaforo
    FROM Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS a
    WHERE a.periodo_contable_analisis = @PERIODO
      AND a.CUENTA IN ('510305','410305')
      AND a.LIBRO <> 'AG'
      AND a.RAMO_PROD IS NOT NULL
    GROUP BY
        a.CUENTA,
        a.LIBRO,
        a.periodo_contable_analisis

    UNION ALL

    /* ------------------------------------------------------------------ */
    /* 4. CEDIDAS TERREMOTO                                                */
    /* Fuente: Liberty.RESERVAS.CEDIDAS_TERREMOTO_RESERVA_INTERFAZ        */
    /* ------------------------------------------------------------------ */
    SELECT
        'CEDIDAS_TERREMOTO'                                                 AS fuente,
        a.CUENTA                                                            AS cuenta,
        CAST(a.LIBRO AS VARCHAR(20))                                        AS libro,
        a.periodo_contable_analisis,
        COUNT(*)                                                            AS total_registros,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NOT NULL THEN 1 ELSE 0 END) AS con_valor,
        SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL     THEN 1 ELSE 0 END) AS sin_valor,
        CASE
            WHEN SUM(CASE WHEN a.VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END) = 0
            THEN 'COMPLETO'
            ELSE 'ALERTA'
        END                                                                 AS semaforo
    FROM Liberty.RESERVAS.CEDIDAS_TERREMOTO_RESERVA_INTERFAZ a
    WHERE a.periodo_contable_analisis = @PERIODO
      AND UPPER(LTRIM(RTRIM(CAST(a.FUENTE_INTERFAZ AS VARCHAR(50))))) = 'TERR'
      AND ISNULL(LTRIM(RTRIM(CAST(a.LIBRO AS VARCHAR(20)))), '') <> 'AG'
    GROUP BY
        a.CUENTA,
        a.LIBRO,
        a.periodo_contable_analisis

) resumen

ORDER BY
    semaforo DESC,      -- ALERTAs primero
    fuente,
    periodo_contable_analisis,
    cuenta;
