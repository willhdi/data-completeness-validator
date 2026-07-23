# Notas de reunión — Vigentes OTH

> **Reunión:** vigentes OTH — Grabación de Teams
> **Fecha:** 22 de julio de 2026, 8:40 p. m.
> **Duración:** ~50 min
> **Participantes:** Andrey Mayorga García (expone), Wilson Eduardo Jerez Hernández (yo), Maria Paula Amaya Velásquez (se une al final, ~min 48).
> **Objetivo:** Andrey explica cómo consultar y estructurar las **pólizas vigentes** de los ramos **OTH** (otros ramos / no-autos) para llevarlas al Data Warehouse (DWH) y alimentar el **control de completitud**, con el fin de **dejar de depender de la tabla "manual"** y que el periodo contable se genere de forma automática a partir de los datos extraídos.

> ⚠️ **Nota sobre estas notas:** se reconstruyeron a partir de una transcripción automática de Teams que quedó **muy degradada** (mezcló español/inglés y metió mucho ruido). El sentido se recuperó cruzando el audio con el contexto del proyecto (IAXIS/AS400, co-corretaje, ramos, periodo contable, control de completitud) y con el resumen automático de Copilot (ver Anexo). Los puntos que **no** se pudieron confirmar del audio están marcados con **(inferido)** o listados en "Pendientes por confirmar". **Conviene validarlas con Andrey.**

---

## Contexto rápido (por qué importa esta reunión)

Hoy el **control de completitud** se apoya en una tabla **"manual"** que alguien tiene que mantener a mano. Eso es frágil: si el manual no se actualiza o tiene errores, el control falla. La meta de este frente de trabajo ("Vigentes OTH") es **construir la extracción de las pólizas vigentes directamente desde los sistemas fuente** (IAXIS y AS400), de modo que:

1. El **periodo contable** se calcule **automáticamente** con los datos reales, no a mano.
2. Las pólizas vigentes de los ramos **OTH** (otros ramos / no-autos) queden bien representadas en el DWH.
3. El resultado se pueda **cruzar y validar** contra lo que ya existe, para ir jubilando el manual.

Esta reunión fue Andrey explicándome (Wilson) **cómo está estructurada esa información** y **qué tengo que replicar/extraer** para lograrlo.

---

## Resumen ejecutivo

Andrey hizo un recorrido por la estructura de datos de las **pólizas vigentes** en IAXIS (sistema Affinity), que es la fuente principal de la mayoría de las pólizas, complementada por aplicativos de AS400. Explicó:

- **Cómo se consultan** las pólizas vigentes y **qué campos** son relevantes (sucursal, ramo/producto, número de póliza, número de documento, fechas de vigencia y renovación, primas del último recibo).
- **Cómo se maneja el co-corretaje:** la comisión se reparte por participación entre el líder y los demás intermediarios, y en el DWH eso genera **una fila por intermediario** (ejemplo Aon/Aion: 40 % / 60 %).
- **Cómo se agrupa por certificado** (vista anual, "certificado cero").
- La diferencia entre pólizas **colectivas** y **colectivas individualizadas**.
- La necesidad de **homologar los ramos** contra el DWH.

El **punto de fondo**: que el **periodo contable se genere a partir de los datos extraídos, no de la tabla "manual"** — es decir, independizarse del manual. Se acordó que **Andrey agendará una sesión de seguimiento/prueba con Paola y conmigo (Wilson)** y **pasará otra tabla (de Autos)** para revisarla juntos.

---

## Resumen detallado por temas

### 1. Fuentes de datos: de dónde salen las pólizas
- **IAXIS (sistema Affinity)** es la **fuente principal**: ahí está la mayoría de las pólizas de la compañía.
- Existen además **aplicativos sobre AS400** (mencionados como "aplicativo de 400" y "aplicativo AIS") que aportan pólizas adicionales. **(inferido:** funcionan como fuentes secundarias/complementarias de IAXIS**)**.
- El objetivo es **consolidar todo en el Data Warehouse (DWH)**, que es donde vive el control de completitud.
- **Acceso por módulos:** dentro del DWH se accede a **distintos módulos** y se usa una **capa de permisos** para diferenciar quién puede ver qué; la configuración original ya contempla permisos por usuario. **(inferido:** relevante para que yo tenga los accesos correctos a cada módulo**)**.

### 2. Vistas generales de la póliza
Andrey mostró varias "**vistas generales**" que consolidan la información de una póliza y que son la base de la consulta:
- Generales **de la póliza** (datos maestros de la póliza).
- Generales **de los asegurados / tomadores** (incluye personas **morales**, es decir empresas).
- **Reservas** asociadas.
- La misma consulta general de pólizas de IAXIS **se puede replicar en "la base"** **(inferido:** otra base/entorno equivalente donde también se puede consultar**)**.

### 3. Ramos y amparos: una póliza puede cubrir varias cosas
- Una **póliza puede amparar varios ramos** al mismo tiempo.
- **Ejemplo:** un producto de **hogar** ampara **incendio, terremoto, responsabilidad civil**, entre otros amparos, todo bajo la misma póliza.
- Cada amparo/producto puede traer **códigos distintos** dentro de la misma póliza, así que al consultar hay que tener en cuenta que **una póliza = varias filas de coberturas**.

### 4. Fechas de vigencia y renovación: cómo saber qué está "vigente"
- Son clave la **fecha de renovación** y la **fecha de vigencia** (el momento en que "**pisa**" la vigencia) para identificar cuáles son los **riesgos vigentes** en un periodo dado.
- Lo más relevante en el momento del corte son las **primas del último recibo de renovación** (es el valor que refleja la situación vigente de la póliza).
- **(inferido:** la lógica de "vigente" se resuelve comparando estas fechas contra el periodo que se está evaluando**)**.

### 5. Co-corretaje: cómo se reparte la comisión entre intermediarios
- Cuando en una póliza hay un **líder** y otros **intermediarios**, la **comisión se divide por participación**.
- **Ejemplo mencionado — negocio de Aon/Aion:** **40 %** de la comisión para uno (Aion) y **60 %** para la casa matriz / el otro participante. **(nota:** el resumen de Copilot dice "Aion" y en el audio suena a "Aon" — **confirmar** si es la correduría Aon u otra cosa**)**.
- En el **Data Warehouse** esto se refleja como **una fila por intermediario**, cada una con su **porcentaje de participación** (p. ej. una fila con 40 % y otra con 60 %), además de un **registro consolidado** de la participación total.
- Esto es **consistente con el patrón de co-corretaje** que ya existe en los scripts del repo (fila original + filas de co-corretaje divididas por participación).

### 6. Campos a extraer de cada póliza
De cada póliza interesan, como mínimo:
- **Sucursal** (la sucursal a la que pertenece la póliza).
- **Ramo / producto**.
- **Número de póliza**.
- **Número de documento**.
- Además de las **fechas** y **primas** del punto 4, y los datos de **intermediario/participación** del punto 5.

### 7. Certificado: la vista anual que agrupa todo
- Existe una **vista anual de Certificado**: toda la información de la póliza **se agrupa en el certificado**.
- Ese certificado incluye la información clave: **números de póliza, números de documento y sucursales/productos asociados**.
- Se mencionó el **"certificado cero"** de la póliza como el nivel de agrupación de referencia. **(inferido:** el "certificado cero" sería el certificado raíz/base de la póliza**)**.

### 8. Colectivas vs. colectivas individualizadas
- **Colectiva:** un solo **tomador** y **varios asegurados** bajo la misma póliza.
- **Colectiva individualizada:** mismo **ramo** y **número de póliza**, pero con **varios tomadores / certificados** (cada certificado se maneja de forma individual dentro de la colectiva).
- Las **individuales** se gestionan por separado.
- Se nombró un producto tipo **"Blanco / Casa"** (hogar) en este contexto. **(inferido:** nombre exacto del producto por confirmar**)**.

### 9. Homologación de ramos, clasificación y otros sistemas
- Hay que **homologar los ramos** contra el Data Warehouse: los ramos vienen **agrupados/estandarizados** y hay que mapearlos a la codificación del DWH.
- **Agrupación de ramos:** algunos son **ramos generalistas comerciales** y otros son **especializados**; la forma de agruparlos **afecta cómo se gestionan y se reportan** las pólizas.
- **Clasificación de pólizas anuales por negocio:** se clasifican por **cuentas de negocio**, **grandes cuentas** y **compañías de financiamiento**. Es práctica estándar en las revisiones anuales de pólizas. **(inferido:** las grandes cuentas se asocian a esquemas de financiamiento**)**.
- **Aliada** es uno de los expedidores/programas; tiene **tres ramos que están en runoff** (en extinción/sin producción nueva); el resto son ramos **generalistas / comerciales**. **(inferido)**.
- Se mencionó la **integración con el sistema de Autos** como un frente en curso.

### 10. Punto clave — desligarse del "manual" y automatizar el periodo contable
- **Principio más importante de la reunión:** el procesamiento del **periodo contable debe ser independiente** y **generarse automáticamente a partir de los datos extraídos**, **no** de una carga **manual**.
- Hoy el resultado final sale de la **unión de la tabla "manual" de control** con lo que ya se procesa y **los cubos**.
- La **meta**: que el **periodo contable lo cree el proceso a partir de los datos que se están extrayendo del DWH**, para **evitar el proceso manual** y solo omitir/mantener pasos manuales cuando sea estrictamente necesario.
- **Retos de integración:** hay que **correlacionar los procesos** (los "orders"/órdenes deben quedar correlacionados) e **integrar el sistema de Autos**; es un trabajo en curso para agilizar la operación.

---

## Acciones de Wilson (To-Do)

- [ ] Construir / consumir la **consulta de pólizas vigentes en IAXIS** para los ramos **OTH**.
- [ ] Incluir las **fuentes de AS400** (aplicativos de 400 / AIS) donde aplique. **(confirmar alcance con Andrey)**
- [ ] Verificar que tengo los **accesos correctos a los módulos del DWH** (capa de permisos).
- [ ] Extraer los campos base: **sucursal, ramo/producto, nº póliza, nº documento**, más **fechas de vigencia/renovación** y **primas del último recibo**.
- [ ] Implementar el **co-corretaje**: generar **una fila por intermediario** con su **participación** (ej. 40/60) + registro consolidado.
- [ ] Manejar la **agrupación por certificado** (vista anual / "certificado cero").
- [ ] Contemplar **colectivas vs. colectivas individualizadas** (mismo ramo/nº póliza, varios tomadores/certificados).
- [ ] **Homologar los ramos** extraídos contra la codificación del Data Warehouse.
- [ ] Lograr que el **periodo contable se derive automáticamente de los datos extraídos**, no del "manual".
- [ ] Asistir a la **sesión de seguimiento/prueba** que **Andrey agendará con Paola y conmigo**; Andrey **pasará otra tabla (de Autos)** para revisarla en conjunto.

---

## Pendientes por confirmar (con Andrey)

- Reparto exacto de **co-corretaje** y quién actúa como **líder** en el ejemplo de Aon/Aion (¿40/60 fijo o variable por negocio?; ¿es "Aon" la correduría o "Aion"?).
- Nombre exacto y alcance del producto **"Blanco / Casa"** y cómo entra en las colectivas individualizadas.
- Qué **aplicativos de AS400** entran realmente y con qué prioridad frente a IAXIS.
- Definición precisa del **"certificado cero"** y su regla de agrupación anual.
- Los **tres ramos de Aliada en runoff** y cómo tratarlos en la extracción.
- Cómo se conecta esto con la **integración de Autos** y con la otra tabla que Andrey enviará.
- Regla concreta para **derivar el periodo contable** desde los datos (¿qué fecha manda: vigencia, renovación o emisión?).

---

## Anexo — Resumen automático de la reunión (Copilot / Teams)

> _Generado por IA. Asegúrate de comprobar la precisión._
>
> _Traducido al español. El resumen original de Copilot venía en inglés._

**Integración del Data Warehouse y gestión de pólizas:**
Andrey y Wilson conversaron sobre la integración del Data Warehouse con los sistemas de gestión de pólizas, cubriendo aspectos técnicos, el acceso de usuarios y el tratamiento de los datos de pólizas para los distintos módulos e intermediarios.
- **Acceso a los módulos del Warehouse:** Andrey explicó el proceso para acceder a los diferentes módulos dentro del Data Warehouse, señalando que los programadores pueden usar una **capa de permisos** para diferenciar el acceso y que la configuración original permite permisos de usuario específicos.
- **Extracción de datos de pólizas:** Andrey describió la extracción de los datos de pólizas desde el warehouse, indicando que pueden surgir problemas al procesar ciertos registros ("letras") y que se usa un **script** para manejar esos problemas y garantizar una recuperación de datos precisa.
- **Participación de intermediarios:** Andrey detalló cómo los datos de pólizas se agrupan por **participación de intermediarios**, con registros separados para cada intermediario y un registro de participación consolidada, y explicó la **estructura de comisiones** para los intermediarios y la casa matriz.
- **Certificación anual de pólizas:** Andrey describió el proceso de **certificación anual**, indicando que todos los datos de la póliza se agrupan en el **certificado**, que incluye información clave como números de póliza, números de documento y las sucursales o productos asociados.

**Clasificación y agrupación de pólizas:**
Andrey dio una visión general de cómo se clasifican y agrupan las pólizas, incluyendo las diferencias entre pólizas colectivas e individuales, y los criterios de clasificación según cuentas de negocio y compañías de financiamiento.
- **Colectivas vs. individuales:** Andrey explicó que las **pólizas colectivas** se agrupan bajo el mismo ramo y número de póliza, con **múltiples tomadores y certificados**, mientras que las **pólizas individuales** se gestionan por separado.
- **Criterios de clasificación:** Andrey describió el proceso de clasificación, indicando que las pólizas se clasifican por **cuentas de negocio, grandes cuentas y compañías de financiamiento**, y que esta clasificación es práctica estándar en las revisiones anuales de pólizas.
- **Agrupación de ramos:** Andrey habló sobre cómo se agrupan los **ramos (RAMOS)**, señalando que algunos son ramos **generalistas comerciales** y otros **especializados**, y que la agrupación afecta cómo se gestionan y reportan las pólizas.

**Procesos técnicos e integración del manual:**
Andrey y Wilson discutieron los procesos técnicos relacionados con la integración del manual, enfatizando la necesidad de **periodos contables automáticos** basados en los datos extraídos y de **minimizar la intervención manual**.
- **Periodos contables automáticos:** Andrey afirmó que el principio más importante es tener un **procesamiento independiente** para los periodos contables, **generados automáticamente** a partir de los datos extraídos en lugar de una carga manual, para asegurar precisión y eficiencia.
- **Minimizar el proceso manual:** Andrey enfatizó que el objetivo es **evitar los procesos manuales**, prefiriendo que los periodos contables se creen directamente desde la extracción del Data Warehouse, omitiendo pasos manuales solo cuando sea necesario.
- **Retos de integración:** Andrey mencionó retos para **correlacionar los procesos** e integrar los sistemas de autos, señalando que las órdenes deben quedar correlacionadas y que la integración está en curso para agilizar las operaciones.

**Estructura de comisiones y roles de los intermediarios:**
Andrey explicó la estructura de comisiones para los intermediarios y la casa matriz, detallando los repartos porcentuales y los roles de los intermediarios en la emisión y gestión de pólizas.
- **Reparto porcentual de comisión:** Andrey describió que las comisiones se reparten, con un **40 % asignado a Aion** y un **60 % a la casa matriz**, y que esta estructura se aplica tanto a los intermediarios como a la participación consolidada.

**Consulta de pólizas y consultas al sistema:**
Andrey habló sobre el proceso de consultar pólizas y realizar consultas al sistema, incluyendo el uso de consultas generales y específicas para distintos tipos de pólizas y el manejo de preguntas relacionadas con la cobertura.
- **Consultas generales y específicas:** Andrey explicó que el sistema permite realizar tanto **consultas generales como específicas** sobre las pólizas, con diferentes preguntas y opciones de cobertura según el tipo de póliza, y que estas consultas se pueden ejecutar para cualquier eje ("axis").

**Tareas de seguimiento:**
_(El resumen automático no registró tareas de seguimiento explícitas; ver la sección "Acciones de Wilson (To-Do)" más arriba.)_

---

*Notas reconstruidas de una transcripción automática degradada y del resumen de Copilot — validar con Andrey Mayorga antes de tomarlas como definitivas.*
