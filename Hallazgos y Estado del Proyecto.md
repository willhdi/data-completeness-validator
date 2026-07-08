# Hallazgos y Estado del Proyecto — Resumen simple

_Última actualización: 2026-07-03_

## ¿Por qué existe este documento?
Se encontró que hay una diferencia de **más de 3 millones de pesos** entre dos sistemas, DWH y CDP, en la **prima** (el dinero que paga el cliente por su seguro), para ciertos meses. Ojo: la cantidad de pólizas (contratos de seguro) sí coincide entre los dos sistemas — el problema es solo con el valor de la plata.

Como respuesta, mi jefe Andrey me pidió construir un **control de completitud**: una revisión automática que dice si a una cuenta contable (una categoría donde se registra la plata, por ejemplo "primas" o "reservas") le está faltando información, ANTES de que se cierre el mes contable (eso pasa como el día 10 de cada mes).

## Qué he hecho hasta ahora
- **Organicé el repositorio**: separé los scripts (archivos de código SQL, que es el lenguaje para consultar bases de datos) que ya existían en producción (carpeta `OriginProcessql/`) de los controles nuevos que estoy construyendo. También limpié archivos que no tenían que ver con este proyecto.
- **Construí el script `control_completitud_cuentas.sql`**: es el control central. Recibe como entrada un periodo (mes, en formato `AAAAMM`, por ejemplo `202708` significa agosto de 2027) y revisa si el campo `VALOR_RESERVA_CONTABLE` (la plata que la aseguradora aparta como respaldo) tiene un valor o está vacío, para cada combinación de cuenta + libro (el libro es el grupo contable al que pertenece la cuenta) + mes.
  - Este control junta información de 4 fuentes distintas: DIRECTA (negocio directo, sin reaseguro), CEDIDAS (negocio que se comparte con una reaseguradora), tanto desde el sistema AS400 como desde IAXIS (dos sistemas de origen distintos), y CEDIDAS TERREMOTO (un tipo especial de reaseguro para riesgo de terremoto).
- **El resultado se muestra como un semáforo por fila**: 🟢 **COMPLETO** (todo tiene valor) o 🔴 **ALERTA** (algo está vacío), junto con un porcentaje de qué tan completo está. Esto sirve para saber a quién avisar antes de que cierre el mes.

## Cómo lo hice
- Leí los scripts SQL que ya corren en producción (carpeta `OriginProcessql/`) para entender qué reglas de negocio ya existen (qué cuentas, qué libros, qué filtros se usan) — pero **no copié toda la lógica compleja** de esos scripts (como número de póliza o el detalle de qué corredor/intermediario vendió el seguro), porque mi control nuevo es intencionalmente mucho más simple: solo revisa si el valor existe o no.
- Cada una de las 4 fuentes se resolvió como una consulta independiente, todas con la misma estructura (fuente → cuenta → libro → periodo → semáforo), y luego las junté todas en una sola tabla usando `UNION ALL` (en SQL, esto significa "pegar los resultados de varias consultas en una sola tabla"). Ordené el resultado para que las alertas (🔴) aparezcan primero.
- Excluí de todas las fuentes el libro llamado `'AG'` — esta es una regla que ya estaba confirmada de antes (ese libro se maneja aparte, con su propio proceso).

## Problemas y cosas pendientes
- **Todavía no confirmo todas las cuentas que se excluyen del control.** Las que sí sé que van excluidas son: Incurrido (costo de un siniestro), Salvamentos (lo que queda con valor después de un siniestro, por ejemplo el chasis de un carro), Recobros (plata recuperada tras pagar un siniestro) e IVA AG (impuesto). Pero **faltan 2 cuentas más por confirmar con Andrey**.
- **Todavía no he probado el script con datos completos.** El DWH va a tener la información completa hasta el viernes, así que el script ya está armado, pero no lo he corrido contra un mes ya cerrado para validar que funcione bien.
- Tengo pendiente preguntarle a Andrey qué son exactamente los "libros con tabs" que mencionó, y si mi control debe aplicarse ya mismo también al módulo de "canal no tradicional" (un grupo de pólizas vendidas por canales no tradicionales) o si eso es un paso posterior.
- Todavía no está confirmado si la diferencia de 3 millones en prima se debe a una "ayuda especial" (un beneficio o ajuste puntual) — Andrey iba a hablar con Javier (su jefe) sobre esto.
- La **Fase 2** (revisar si los valores tienen sentido, no solo si existen — por ejemplo detectar números raros o fuera de patrón) todavía no ha arrancado.

## Reunión del 2026-07-03: controles de cocorretaje en CDP (esto no es tarea mía, es contexto)
- Juan Sebastián (compañero) mostró 4 controles de calidad sobre el **cocorretaje** en CDP. Cocorretaje es cuando varios corredores (intermediarios que venden seguros) se reparten la comisión (un porcentaje de la venta) de una misma póliza: hay un corredor líder y co-corredores. El nombre de la tabla que usa se mencionó como "riesgo coco versión 2" (falta confirmar el nombre exacto).
  - Reglas usadas: solo registros que tengan prima, con el filtro `Current_Record_Flag = 1` (una bandera que marca cuál es la versión "vigente" de un registro, para no contar versiones viejas), comparado contra producción desde el periodo `202501` en adelante.
  - Falta que Juan Sebastián haga que el periodo sea un parámetro configurable (para poder auditar cualquier mes, no solo uno fijo).
  - Andrey dio este tema por cerrado (terminado).
- **Esto sí me afecta a mí**: Andrey dijo que todos los controles de calidad que están llegando de distintas personas (el mío incluido) se deben **organizar en un solo lugar** — todavía falta validar con Karen cómo se va a manejar eso.
- También confirmó que, de ahora en adelante, los controles nuevos (incluyendo el mío) solo se entregan hasta el semáforo/resultado (verde o rojo). Las alertas automáticas (notificaciones que avisan solas cuando algo falla) las construye el equipo de Andrey por separado — así se hizo con el control de primas, aunque eso tomó bastante tiempo. Todavía falta decidir si las alertas nuevas van en un tablero propio o si se repite el mismo esquema que se usó para primas.
