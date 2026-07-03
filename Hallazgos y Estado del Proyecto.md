# Hallazgos y Estado del Proyecto — Resumen Daily

_Última actualización: 2026-07-03_

## Contexto (por qué existe esto)
Se detectó una diferencia de **~3.000.000+ en prima** entre DWH y CDP para ciertos periodos contables (el conteo de pólizas sí cuadra, el valor no). Andrey propuso replicar en "canal no tradicional" los mismos controles de calidad que ya existen para siniestros. Mi tarea asignada es la primera pieza: un **control de completitud de cuentas contables en DWH**, que corra antes del cierre oficial (día 10) para detectar a tiempo cuentas sin valor.

## Qué se hizo
- Se organizó el repo: se separaron los scripts fuente originales (carpeta `OriginProcessql/`) de los nuevos controles, y se limpiaron scripts/archivos que no correspondían a este proyecto.
- Se construyó `control_completitud_cuentas.sql`: un control único, parametrizado por periodo (`@PERIODO`), que revisa si `VALOR_RESERVA_CONTABLE` está completo (no nulo) por **cuenta + libro + periodo**, para 4 fuentes: DIRECTA (IAXIS), CEDIDAS (AS400), CEDIDAS (IAXIS) y CEDIDAS TERREMOTO.
- El resultado da un semáforo por fila: **COMPLETO** (sin_valor = 0) o **ALERTA** (sin_valor > 0), con `%` de completitud, para saber a quién avisar antes del cierre.

## Cómo se hizo
- Se leyeron los SQL originales de producción (carpeta `OriginProcessql/`) para extraer las reglas de negocio (cuentas, libros, filtros) sin copiar la lógica completa de póliza/intermediario/corretaje — el control nuevo es intencionalmente más simple.
- Cada fuente se resolvió como un `SELECT` independiente (misma forma: fuente → cuenta → libro → periodo → semáforo) y se unieron todas con `UNION ALL` en una sola tabla consolidada, ordenada con las ALERTAs primero.
- Se excluyó `Libro = 'AG'` en todas las fuentes (regla ya confirmada).

## Problemas / pendientes
- **Cuentas excluidas sin confirmar por completo**: van excluidas Incurrido, Salvamentos, Recobros e IVA AG (tienen sus propias tablas/controles), pero **faltan 2 cuentas adicionales por confirmar con Andrey**.
- **No se ha corrido contra data completa aún**: DWH tendría data completa hasta el viernes, así que el script está armado pero sin validar contra un periodo cerrado.
- Pendiente aclarar con Andrey qué son los "libros con tabs" y si el control debe extenderse ya a canal no tradicional o es un paso posterior.
- Sigue sin confirmarse si la diferencia de ~3M en prima es por la "ayuda especial" (Andrey lo iba a hablar con Javier).
- Fase 2 (detección de valores atípicos, no solo nulos) todavía no arranca.

## 2026-07-03 — Reunión de Juan Sebastián: controles de cocorretaje en CDP (contexto, no es tarea de Wilson)
- Juan Sebastián mostró 4 controles de calidad de **cocorretaje en CDP**, sobre la tabla de cocorretaje (nombre mencionado: "riesgo coco versión 2", confirmar exacto). Reglas: registros con prima, `Current_Record_Flag = 1`, comparado contra producción desde `202501`. Falta parametrizar el periodo — Andrey da el tema por cerrado.
- **Relevante para este proyecto**: Andrey planteó que todas las reglas/controles de calidad que están llegando de distintas personas (incluye el de completitud de Wilson) se deben **organizar centralmente** — pendiente validar con **Karen (Karencita)** cómo manejarlos.
- Confirmado: de aquí en adelante, los controles nuevos (incluyendo el de completitud de cuentas) se entregan solo hasta el semáforo/resultado; el equipo de Andrey construye las alertas por separado (como se hizo con el control de primas, aunque eso tomó mucho tiempo). Falta decidir si las alertas van en un tablero propio o replican el esquema de primas.
