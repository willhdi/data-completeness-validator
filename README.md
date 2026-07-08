# Notas del proyecto — explicado en simple

## 0. ¿De qué trata esto, en una frase?

Hay dos sistemas donde HDI guarda información de seguros: **DWH** (Data Warehouse, "bodega de datos", es donde vive la información ya procesada y lista para reportes) y **CDP** (otro sistema con esa misma información, pero cargada por otra vía). Se dieron cuenta de que esos dos sistemas **no cuadran en plata** para ciertos meses, aunque sí cuadran en cantidad de pólizas. Mi tarea es construir un "chequeo" que avise, ANTES de que se cierre el mes, si a alguna cuenta le está faltando información en el DWH.

---

## 1. Cómo se llegó a esto (contexto de las reuniones)

### Reunión 1: se descubrió el problema
- Juan Sebastián (compañero) encontró que la **prima** (esta es la palabra técnica para "el dinero que paga el cliente por su póliza de seguro") no coincide entre DWH y CDP en algunos meses.
- La diferencia es grande: como **3 millones de pesos de más en CDP** comparado con DWH.
- Lo raro es que si cuentas cuántas pólizas (contratos de seguro) hay, el número sí coincide en ambos sistemas. El problema es solo en el valor de la plata, no en la cantidad de contratos.
- Se sospecha que puede ser por una "ayuda especial" (un beneficio o descuento puntual que quizás se registró distinto en cada sistema), pero **todavía no está confirmado**.
- Andrey (mi jefe/líder en este tema) propuso una solución: para el próximo módulo que se va a migrar, llamado **"canal no tradicional"** (es solo el nombre de un grupo de pólizas que se venden por canales distintos a los tradicionales, como agencias digitales), se le van a aplicar los mismos chequeos de calidad que ya se usan para **siniestros** (siniestro = cuando el cliente reclama porque le pasó algo cubierto por el seguro, un choque por ejemplo).

### Reunión 2: me asignan mi tarea concreta
Andrey me pide construir la primera pieza de esa solución: un **control de completitud** en el DWH.

**¿Qué es un "control de completitud"?** En palabras simples: una revisión automática que dice "¿esta cuenta contable tiene todos los valores que debería tener, o le falta algo?". No revisa si el número es correcto, solo revisa si el dato *existe* (no está vacío o nulo).

**¿Qué es una "cuenta contable"?** Es como una categoría o casilla donde se registra la plata según su tipo (por ejemplo, una cuenta para primas, otra para reservas, otra para comisiones). Cada cuenta contable, además, vive dentro de un **"libro"** — el libro es básicamente el conjunto/grupo contable al que pertenece esa cuenta (como si fueran distintas carpetas donde se archiva la información contable).

### ¿Por qué hacer esto?
Cada mes, hay procesos automáticos que "cierran" la contabilidad, y corren aproximadamente el **día 10**. Si un dato falta y nadie se da cuenta antes de ese día, ya es tarde: el reporte oficial sale con el error. Por eso la idea es correr mi control unos días antes (día 8 o 9) para poder avisar a tiempo: "oye, a la cuenta X del libro Y le está faltando información este mes, revisa antes de que cierre".

---

## 2. Mi tarea exacta

Tengo que verificar, para cada cuenta contable y cada libro, que el campo llamado **`valor de la reserva contable`** (esta es la plata que la aseguradora aparta/reserva para cubrir algo, como un respaldo financiero) **tenga un valor** (no esté vacío) en **todos los meses** que se están revisando.

No estoy validando si el número es correcto o razonable — solo si existe o no. Eso de validar si el número "tiene sentido" es una tarea futura (ver Fase 2 más abajo).

### Cuentas que NO se revisan en este control
Estas cuentas ya tienen sus propios chequeos por separado, así que las dejamos afuera para no duplicar trabajo:
- **IVA AG** (impuesto)
- **Incurrido** (el costo total que le representa a la aseguradora un siniestro)
- **Recobro** (plata que la aseguradora logra recuperar después de pagar un siniestro, por ejemplo cobrándole al responsable)
- **Salvamentos** (cuando algo se dañó pero queda una parte con valor que se puede vender, por ejemplo el chasis de un carro chocado)
- Hay **2 cuentas adicionales** que también se excluyen, pero todavía no sé cuáles son — **tengo que preguntarle a Andrey**.

Todas las demás cuentas sí entran al control.

### Pasos para construirlo
1. Leer los scripts SQL que ya existen y corren en producción, para entender qué reglas de negocio ya aplican (qué cuentas, qué libros, qué filtros).
2. Sacar de ahí solo las reglas de calidad, sin copiar toda la lógica compleja (Andrey está armando una tabla con estas reglas documentadas — voy a pedir acceso).
3. Crear scripts **nuevos y más simples**, que solo revisen si el valor está o no está (sin meterse con número de póliza, ni con el corredor/intermediario que vendió el seguro).
4. De cada revisión, quedarme solo con una tabla resumen chiquita (cuenta, libro, periodo, si está completo o no).
5. Juntar (con `UNION`, que en SQL significa "pegar varias tablas de resultados en una sola") todos esos resultados en una única tabla final.
6. Correr todo esto contra el Data Warehouse.

### Fase 2 (para más adelante, después de que esto quede resuelto)
Una vez que sepamos que el dato *existe*, el siguiente paso es revisar si el dato tiene sentido — por ejemplo, si un valor es sospechosamente distinto al de meses anteriores (esto se llama detectar **valores atípicos**, es decir, números raros que se salen del patrón normal). Todavía no se ha definido cómo se va a medir eso.

### Lo que Andrey se comprometió a hacer
- Compartirme la tabla de reglas de calidad que está armando.
- Estar disponible para resolver dudas.
- Ayudarme a hacer las primeras reglas juntos, una vez tenga permisos de acceso al DWH.

---

## 3. Cómo esto se conecta con el resto del plan (para tener el panorama completo)

- **Ahora mismo:** estoy construyendo el catálogo de reglas de completitud, con un resultado tipo semáforo (🟢 verde = completo, 🔴 rojo = falta algo) para que el equipo sepa si puede cerrar el mes tranquilo.
- **Más adelante:** este mismo esquema (completitud + revisión de valores raros) se va a repetir para el módulo de "canal no tradicional". Si dejo esto bien documentado ahora, ese trabajo futuro será mucho más rápido.
- También sería útil documentar el **linaje de datos**: o sea, de dónde sale exactamente cada cuenta/campo en DWH y en CDP, para que sea más fácil diagnosticar diferencias como la de los 3 millones.
- Ayudar a definir qué se considera "valor raro/atípico" para la Fase 2.
- Llevar un registro claro de qué se ha revisado y qué diferencias se han encontrado, para que Javier (jefe de Andrey, quien decide prioridades) pueda decidir qué es más urgente.

---

## 4. Preguntas pendientes por resolver (mi lista de tareas de seguimiento)

- [ ] ¿Cuáles son las 2 cuentas adicionales que se excluyen del control? (además de IVA AG, Incurrido, Recobro, Salvamentos)
- [ ] ¿Qué son exactamente los "libros con tabs" que mencionó Andrey?
- [ ] ¿Cómo se va a definir un "valor atípico" para la Fase 2?
- [ ] Pedir permisos de acceso al Data Warehouse.
- [ ] Pedir la tabla de reglas de calidad que Andrey está armando.
- [ ] Confirmar si la diferencia de 3 millones en prima es por la "ayuda especial" mencionada.
- [ ] Preguntar si mi control debe aplicarse ya mismo también a "canal no tradicional", o si eso viene después.
- [ ] Hablar con Karen sobre cómo se van a organizar todas las reglas de calidad que están llegando de distintas personas.

---

## 5. Otra reunión relacionada (2026-07-03): controles de cocorretaje

Juan Sebastián mostró unos controles de calidad para el **cocorretaje** en CDP.

**¿Qué es cocorretaje?** Cuando una póliza la vende un corredor (intermediario que vende seguros), a veces hay un **corredor líder** y otros **co-corredores** que también participan y se reparten una comisión (un porcentaje de la venta) entre todos. El control de Juan Sebastián revisa que esa repartición esté bien registrada en CDP.

Puntos clave de esa reunión:
- Este control ya quedó cerrado (terminado) por parte de Juan Sebastián — son 4 controles en total.
- Se usa como filtro `Current_Record_Flag = 1` (esto es una bandera en la base de datos que marca cuál es el registro "vigente/actual", para no contar versiones viejas del mismo dato dos veces).
- Se compara desde el periodo `202501` en adelante.
- Punto importante para mi trabajo: Andrey dijo que **todos los controles de calidad nuevos** (el mío incluido) de aquí en adelante solo se entregan hasta el "semáforo" (o sea, hasta decir verde o rojo). Las alertas automáticas (notificaciones que avisan solas cuando algo sale mal) las va a construir el equipo de Andrey por separado, no yo.
- También dijo que hay que organizar, junto con Karen, todas las reglas de calidad que están llegando de distintas personas, para no perderlas ni duplicar esfuerzos.

---

## 6. Resumen en una frase

Estoy construyendo el primer chequeo de calidad (que la información contable esté completa en el DWH) de un plan más grande para que DWH y CDP cuadren en plata; este chequeo es el prototipo que después se va a repetir para "canal no tradicional", y convive con otros controles que está construyendo el resto del equipo (como el de cocorretaje de Juan Sebastián).
