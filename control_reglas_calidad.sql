/* ==========================================================================
   CONTROL DE REGLAS DE CALIDAD — RESERVAS (MVP)
   Fuente de reglas: FORMATO_MVP_diligenciado\Formato_reglas_calidad.csv
   Ejecutar: días 8-9 del mes, antes del cierre (día 10). Cambiar @PERIODO.

   Por cada fuente se aplican las reglas del CSV:
     - validez   -> define el alcance (CUENTA IN ... / FUENTE_INTERFAZ = 'TERR')
     - exclusion -> se excluye el Libro 'AG' (se controla aparte)
     - ramo      -> solo CEDIDAS: RAMO_PROD IS NOT NULL (condición de entrada)
     - completitud -> VALOR_RESERVA_CONTABLE IS NOT NULL  (genera el semáforo)

   Semáforo:  sin_valor = 0 -> COMPLETO   |   sin_valor > 0 -> ALERTA
   ==========================================================================*/

DECLARE @PERIODO INT = 202606;   -- para el control del cierre siguiente: 202607

SELECT
    fuente,
    cuenta,
    libro,
    periodo_contable_analisis,
    total_registros,
    sin_valor,
    CAST(ROUND(100.0 * (total_registros - sin_valor) / NULLIF(total_registros, 0), 2) AS DECIMAL(5,2)) AS pct_completitud,
    CASE WHEN sin_valor = 0 THEN 'COMPLETO' ELSE 'ALERTA' END AS semaforo
FROM
(
    -- 1. DIRECTA (IAXIS)
    SELECT 'DIRECTA_IAXIS' AS fuente, CUENTA AS cuenta, Libro AS libro, periodo_contable_analisis,
           COUNT(*) AS total_registros,
           SUM(CASE WHEN VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END) AS sin_valor
    FROM Liberty.RESERVAS.DIRECTA_RESERVA_INTERFAZ
    WHERE periodo_contable_analisis = @PERIODO
      AND CUENTA IN ('410305','410310','410315','510305','510310','510315')  -- validez
      AND Libro <> 'AG'                                                       -- exclusion
    GROUP BY CUENTA, Libro, periodo_contable_analisis

    UNION ALL

    -- 2. CEDIDAS (AS400)
    SELECT 'CEDIDAS_AS400', CUENTA, LIBRO, periodo_contable_analisis,
           COUNT(*),
           SUM(CASE WHEN VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END)
    FROM Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ
    WHERE periodo_contable_analisis = @PERIODO
      AND CUENTA IN ('510305','410305')   -- validez
      AND LIBRO <> 'AG'                    -- exclusion
      AND RAMO_PROD IS NOT NULL            -- ramo
    GROUP BY CUENTA, LIBRO, periodo_contable_analisis

    UNION ALL

    -- 3. CEDIDAS (IAXIS)
    SELECT 'CEDIDAS_IAXIS', CUENTA, LIBRO, periodo_contable_analisis,
           COUNT(*),
           SUM(CASE WHEN VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END)
    FROM Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS
    WHERE periodo_contable_analisis = @PERIODO
      AND CUENTA IN ('510305','410305')   -- validez
      AND LIBRO <> 'AG'                    -- exclusion
      AND RAMO_PROD IS NOT NULL            -- ramo
    GROUP BY CUENTA, LIBRO, periodo_contable_analisis

    UNION ALL

    -- 4. CEDIDAS TERREMOTO
    SELECT 'CEDIDAS_TERREMOTO', CUENTA, CAST(LIBRO AS VARCHAR(20)), periodo_contable_analisis,
           COUNT(*),
           SUM(CASE WHEN VALOR_RESERVA_CONTABLE IS NULL THEN 1 ELSE 0 END)
    FROM Liberty.RESERVAS.CEDIDAS_TERREMOTO_RESERVA_INTERFAZ
    WHERE periodo_contable_analisis = @PERIODO
      AND UPPER(LTRIM(RTRIM(CAST(FUENTE_INTERFAZ AS VARCHAR(50))))) = 'TERR'          -- validez
      AND ISNULL(LTRIM(RTRIM(CAST(LIBRO AS VARCHAR(20)))), '') <> 'AG'                -- exclusion
    GROUP BY CUENTA, CAST(LIBRO AS VARCHAR(20)), periodo_contable_analisis
) resumen
ORDER BY semaforo DESC, fuente, cuenta;   -- ALERTAs primero
