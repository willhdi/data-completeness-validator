# Notas — Migración DWH → CDP: diferencias de prima y controles de calidad

## 0. Cómo se conectan las dos reuniones

- **Reunión 1** (Juan Sebastián + Andrey + tú de oyente): Juan encontró que la **prima** no cuadra entre Data Warehouse (DWH) y CDP para ciertos periodos contables, aunque el conteo de pólizas únicas sí cuadra. Andrey, en esa misma reunión, propone la solución general: replicar en el tablero de **"canal no tradicional"** el mismo tipo de controles de calidad que ya se hicieron para **siniestros** (comparar que DWH y CDP cuadren).
- **Reunión 2** (Andrey + tú, tarea directa): Andrey te asigna **la primera pieza concreta** de ese plan de controles: validar que las cuentas contables tengan valores completos en DWH, cuenta por cuenta y periodo por periodo, ANTES de que corran los procesos oficiales de cierre.

En otras palabras: la Reunión 1 es el "por qué" (encontraron un problema real de datos faltantes/desfasados), y la Reunión 2 es el "qué hacer tú ya mismo" (construir el control de completitud que ayuda a detectar este tipo de problemas antes de que lleguen al negocio).

---

## 1. Reunión 1 — Resumen: diferencia DWH vs CDP

- Diferencia total encontrada: **~3.000.000+ de más en CDP** frente a DWH (en valores, no en cantidad de pólizas).
- Los **conteos de pólizas únicas** (con las reglas y todo del cruce DWH–CDP) sí cuadran perfecto.
- El problema está en el **valor de la prima**: para ciertos periodos contables, el valor en DWH no coincide con el valor en CDP.
- Se sospecha que puede estar relacionado con una "ayuda especial" (beneficio o ajuste puntual que quizá no está replicado igual en ambas fuentes), pero **no está confirmado** — Andrey iba a hablar con Javier para definirlo.
- **DWH tendrá la data completa hasta el viernes.** Mientras tanto, se pueden ir montando las queries sin data completa.
- Prioridad a definir por Javier: ¿seguir con la migración en curso o priorizar este tema de conciliación de CDP?
- Próximo tablero a migrar: **canal no tradicional** — hay que rehacer las queries desde CDP y aplicarle los mismos controles de calidad que a siniestros.
- Pendiente aparte (no es tuyo, es de Mario/Juan): una "foto"/snapshot para comparar el cierre, usado en automatización.

## 2. Reunión 2 — Tu tarea concreta: control de completitud en DWH

### Motivo (el "para qué")
Los procesos de negocio (los que generan las tablas/reportes finales) corren **~el día 10 de cada mes**. Si algo falta ese día, ya es tarde para reaccionar. La idea es tener un **control preventivo**: correr tus queries el día 8 o 9, antes del proceso oficial, para saber:
- ¿La tabla está completa y lista? o
- ¿Falta algo, y a quién aviso (dueño de la tabla) para decirle "no tengo valores para la cuenta X en el libro Y"?

Es una alarma temprana, no el proceso de negocio en sí — y es exactamente el tipo de control que Andrey mencionó en la Reunión 1 que quiere replicar para canal no tradicional (como se hizo con siniestros).

### Qué hay que verificar exactamente
No basta con que la cuenta **aparezca** — tiene que **tener valores** (no nulo/vacío) en **todos los periodos contables**, sobre el campo **valor de la reserva contable**.

Condición: solo se revisan las cuentas cuando existen en los distintos libros contables (libros con "tabs"), aplicando las reglas que Andrey está dejando documentadas.

### Cuentas EXCLUIDAS del control:
- IVA AG
- Incurrido
- Recobro
- Salvamentos
- (+2 cuentas adicionales mencionadas, sin confirmar cuáles — **preguntar a Andrey**)

Todas las demás cuentas sí llevan el control.

### Paso a paso
1. **Leer los SQL actuales** de los procesos que ya corren en producción.
2. Extraer de ahí las **reglas de calidad** implícitas (Andrey está armando una tabla con esto — pedir acceso).
3. **Crear nuevos scripts**, más simples que los originales:
   - Sin número de póliza.
   - Sin número de intermediario.
   - Solo validando si el valor de la reserva contable está presente en todos los periodos contables.
4. De cada query, quedarte solo con la **tablita resumen de lógica/resultado**.
5. **Unir (UNION)** los resultados de cada regla en **una sola tabla consolidada**.
6. Ejecutar en **Data Warehouse**.

### Fase 2 (después de completitud resuelta)
- Validar **estabilidad del dato**: detectar valores atípicos aunque el campo sí tenga valor.
- Andrey está abierto a que propongas reglas adicionales de tendencias/desviaciones — él mismo dice que no es experto en calidad.

### Compromisos de Andrey
- Te comparte la tabla de reglas de calidad que está armando.
- Disponible para dudas.
- Ofrece hacer las primeras reglas juntos una vez tengas permisos en DWH.

---

## 3. Cómo puedes apoyar (Gobierno de Datos) — visión conjunta de ambas reuniones

- **Corto plazo (Reunión 2):** construir y documentar el catálogo de reglas de calidad de completitud, dejarlo reutilizable y con un criterio claro (semáforo verde/amarillo/rojo) para que Andrey sepa si puede correr su proceso.
- **Mediano plazo (conexión con Reunión 1):** este mismo esquema de control (completitud + estabilidad) es el que hay que replicar en **canal no tradicional**, tal como se hizo con siniestros. Si dejas bien documentado el proceso ahora, te ahorras rehacer el trabajo cuando toque ese tablero.
- Documentar el **linaje de datos**: de dónde sale cada cuenta/campo en DWH vs CDP, para acelerar el diagnóstico cuando aparezcan diferencias como la de la prima.
- Ayudar a definir un criterio de **valor atípico** (rangos esperados, variación mes a mes) para la fase 2.
- Llevar trazabilidad de qué se ha migrado/conciliado y qué diferencias se han encontrado — útil para que Javier priorice.

---

## 4. Pendientes / dudas para aclarar

- [ ] Confirmar cuáles son las 2 cuentas adicionales excluidas del control (además de IVA AG, Incurrido, Recobro, Salvamentos).
- [ ] Aclarar qué son exactamente los "libros con tabs".
- [ ] Definir el umbral/criterio para dato atípico (fase 2).
- [ ] Solicitar permisos de acceso a Data Warehouse.
- [ ] Pedir la tabla de reglas de calidad que Andrey está armando.
- [ ] Confirmar con Andrey/Javier si se confirmó la causa de la diferencia de ~3M en prima (¿es por la "ayuda especial"?).
- [ ] Preguntar si tu control de completitud debe extenderse ya mismo a canal no tradicional o si es un paso posterior.

## 5. Resumen en una frase

Estás construyendo el primer control de calidad (completitud de cuentas contables en DWH) de un plan más grande de conciliación DWH–CDP que nació porque se detectó una diferencia de ~3M en prima; este mismo control es el prototipo que luego se replicará en el tablero de canal no tradicional.
