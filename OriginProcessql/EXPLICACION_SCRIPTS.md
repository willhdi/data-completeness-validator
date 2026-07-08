# Guía de la carpeta `OriginProcessql/` — explicada para alguien nuevo

Este documento existe porque los 11 scripts de esta carpeta **no se crearon para enseñar** — son procesos
de producción que alguien más escribió para calcular primas y siniestros. Aquí te explico qué hace cada uno,
pero también las palabras de negocio que necesitas para entenderlos, porque asumo que no las conoces todavía.

No necesitas memorizar todo esto de una sentada. Úsalo como diccionario: cuando abras un script y veas una
palabra rara (`IAXIS`, `cedida`, `corretaje`...), vuelve aquí y búscala.

---

## 1. Lo primero: el panorama completo

HDI vende seguros. Cada póliza (contrato de seguro) genera dos tipos de movimientos que a esta carpeta le
interesan:

1. **Plata que entra**: lo que el cliente paga por su póliza (la "prima"), y lo que la aseguradora reserva
   como respaldo financiero mientras la póliza esté vigente (la "reserva técnica"/"reserva contable").
2. **Plata que sale**: lo que la aseguradora paga cuando el cliente reclama (un "siniestro"), y todo lo
   relacionado con eso (recobros, salvamentos).

Estos scripts leen esa información desde **varios sistemas de origen distintos** (porque HDI ha usado
distintas plataformas a lo largo del tiempo, y algunas pólizas viejas siguen en sistemas viejos), la
limpian, la normalizan a un formato común, y la juntan en un puñado de tablas finales que el resto de la
compañía usa para reportar. El control de completitud que tú estás construyendo (`control_completitud_cuentas.sql`,
en la raíz del repo) parte de esas mismas fuentes, pero simplificando: solo revisa si el dato existe, sin
repetir toda esta lógica de negocio.

---

## 2. Glosario de negocio

### Los sistemas de origen (esto es lo que preguntabas: IAXIS, SISE, AS400)

Son plataformas informáticas distintas donde vive la información de pólizas, según cuándo se vendió la
póliza o por qué canal. No son bases de datos que tú vayas a tocar directamente casi nunca — llegan ya
copiadas al DWH en tablas con ese nombre en el sufijo (`_IAXIS`, `_AS400`) o se consultan en vivo con
`OPENQUERY` (ver sección de SQL más abajo).

- **AS400**: el sistema más viejo. El nombre viene de un tipo de computador de IBM (AS/400) que muchas
  aseguradoras usaron desde los 80s-90s para administrar pólizas. Aquí viven las pólizas más antiguas o las
  que nunca se migraron a un sistema más moderno. Vas a ver campos con nombres crípticos de 6 letras
  (`DTPEKN`, `DTITCG`, `IVCLVI`...) — es típico de AS400, que tenía límites de longitud de nombre de campo.
- **IAXIS**: el sistema de administración de pólizas más moderno/actual de HDI. La mayoría del negocio nuevo
  vive aquí. Cuando un script dice "iaxis" en el nombre, está leyendo pólizas de este sistema.
- **SISE**: otro sistema, usado sobre todo para el negocio que viene por el canal de **Generali** (una
  aseguradora aliada/fusionada). Los scripts de SISE casi siempre usan `OPENQUERY(CODMHDI, '...')` — es decir,
  no leen una tabla ya copiada al DWH, sino que se conectan en vivo a un servidor externo (linked server)
  para traer los datos en el momento. Fíjate que dentro de ese `OPENQUERY` las comillas simples se escriben
  dobladas (`''`) porque es una cadena de texto dentro de otra cadena de texto — es fácil romper el script
  si editas esa parte sin cuidado.
- **DWH** (Data Warehouse): la "bodega de datos" central de HDI, donde toda esta información ya migrada,
  limpia y unificada, vive lista para reportes. Es el sistema que tu control de completitud está revisando.
- **CDP**: otro sistema que también tiene esta información (cargada por una vía distinta al DWH). El problema
  raíz de todo este proyecto es que DWH y CDP no cuadran en plata para ciertos meses — ver
  `Hallazgos y Estado del Proyecto.md` en la raíz del repo para el contexto completo de esa discrepancia.

### Identificadores de una póliza

Vas a ver estas columnas repetidas en casi todos los scripts — son la "llave" con la que se identifica de
qué póliza/movimiento se habla:

- **`ramo` / `ramo_prod`**: el tipo de seguro (autos, hogar, vida, etc.), identificado con un código.
- **`poliza`**: el número de contrato de seguro.
- **`certificado`**: dentro de una póliza (sobre todo las colectivas, con muchos asegurados), identifica a
  un asegurado/riesgo específico.
- **`documento` / `recibo`**: el número del recibo de pago o del movimiento contable puntual dentro de esa
  póliza/certificado (una póliza puede tener varios recibos a lo largo del año).
- **`periodo_contable`**: el mes contable en formato `AAAAMM` (ej. `202708` = agosto de 2027).
- **`tomador`**: la persona o empresa que contrató el seguro (el cliente).

### Directa, Cedida, Facultativo, Terremoto — los "tipos de negocio"

Esto confunde mucho al principio porque no es tan intuitivo:

- **Negocio DIRECTA**: HDI asume el 100% del riesgo de la póliza. No comparte el riesgo con nadie.
- **Negocio CEDIDA (reaseguro)**: HDI le "cede" (traspasa) una parte del riesgo a una **reaseguradora** —
  una aseguradora de aseguradoras, que ayuda a HDI a no quebrar si pasa algo muy grande y caro. A cambio,
  HDI le cede también una parte de la prima que cobró. Los scripts `CEDIDAS_*` calculan cuánta plata se le
  cedió a la reaseguradora.
- **CEDIDA TERREMOTO**: un tipo especial de cedida — específicamente el reaseguro que cubre el riesgo de
  terremoto (es un riesgo tan grande que casi siempre se maneja aparte del reaseguro normal, con sus propias
  reglas y su propia tabla de origen, `CEDIDAS_TERREMOTO_RESERVA_INTERFAZ`).
- **FACULTATIVO**: un tipo de reaseguro que se negocia caso por caso (póliza por póliza), a diferencia del
  reaseguro "automático" que aplica en bloque a todo un ramo. Se usa para riesgos grandes o poco comunes que
  no encajan en el esquema general. `facultativos.sql` calcula la prima cedida en estos contratos especiales.

### Devengada, prima, reserva

- **Prima**: lo que el cliente paga por el seguro.
- **Devengada**: la parte de la prima que la aseguradora ya "se ganó" contablemente porque ya pasó ese tiempo
  de cobertura (una póliza anual no se gana toda la prima el día 1, se la va ganando mes a mes). Los conceptos
  `Devengada_Directa`, `Devengada_Cedida`, etc. representan ese valor calculado para cada fuente.
  ⚠️ Cuidado: esta palabra ("devengada") es distinta al **valor de la reserva contable** que tú estás
  validando en tu control de completitud — son conceptos relacionados pero no el mismo campo.
- **Reserva técnica / reserva contable**: la plata que la aseguradora aparta como respaldo mientras la
  póliza esté vigente, por si toca pagar un siniestro. Es el campo `VALOR_RESERVA_CONTABLE` que tu control
  valida que no esté vacío.

### Incurrido, recobro, salvamento — el lado de los siniestros

- **Siniestro**: el evento por el cual el cliente reclama (un choque, un robo, etc.).
- **Incurrido**: el costo total que le representa a la aseguradora ese siniestro (lo que ya pagó + lo que
  estima que va a pagar).
- **Recobro**: plata que la aseguradora logra recuperar después de pagar el siniestro — por ejemplo,
  cobrándole al tercero responsable del choque, o a su aseguradora.
- **Salvamento**: cuando algo se dañó en el siniestro pero queda una parte con valor que se puede vender
  (el ejemplo típico es el chasis/latonería de un carro chocado que ya no se puede reparar, pero cuyas
  piezas o chatarra sí valen algo).

### Corretaje / Cocorretaje — cómo se reparte la comisión

- **Intermediario / corredor**: la persona o empresa que vendió la póliza (un agente, una agencia, un
  broker).
- **Intermediario líder (`ES_LIDER = 1`)**: cuando varios intermediarios participan en la venta de una
  misma póliza, uno de ellos es el "líder" — el que queda registrado como principal responsable/contacto.
- **Cocorretaje / co-corredores**: los demás intermediarios que también participan y se reparten parte de
  la comisión (un porcentaje de la venta) junto al líder.
- **`participacion` / `factor_corretaje`**: el porcentaje que le corresponde a cada co-corredor sobre el
  valor total. Vas a ver un patrón que se repite en casi todos los scripts de reservas: se calcula el valor
  base de la póliza → se busca si tiene intermediario líder → si hay co-corredores, se divide ese valor
  según su `participacion` → y al final se juntan (con `UNION ALL`) las filas "originales" con las filas
  de "co-corretaje" en una sola tabla.

---

## 3. Glosario técnico de SQL (lo mínimo para no perderte)

- **`#tabla`** (una almohadilla): una "tabla temporal" que solo existe durante esa sesión/conexión de SQL.
  Sirve para guardar resultados intermedios sin tener que crear una tabla real en la base de datos.
- **`##tabla`** (dos almohadillas): una "tabla temporal global" — visible desde otras sesiones/conexiones
  mientras exista. Se usa aquí para poder consultarla después desde otra pestaña/ventana de la misma
  ejecución.
- **`IF OBJECT_ID('tempdb..#X') IS NOT NULL DROP TABLE #X;`**: un bloque de limpieza al inicio del script.
  Borra la tabla temporal si ya existía (de una corrida anterior) para poder re-ejecutar el script sin que
  falle por "la tabla ya existe". No se debe quitar (ver `CLAUDE.md`).
- **`DECLARE @PERIODO INT = 202601;`**: define una variable — en este caso, el mes contable a partir del
  cual el script va a traer datos. Casi siempre hay que revisar y ajustar estas variables antes de correr un
  script, porque quedaron con el último periodo que usó la persona que lo corrió por última vez.
- **`OPENQUERY(CODMHDI, '...')`**: ejecuta una consulta SQL en vivo contra otro servidor (un "linked
  server", en este caso el que conecta con SISE). El texto dentro de las comillas es una cadena de texto
  literal — SQL Server no la valida como código hasta que llega al otro servidor, así que un error de sintaxis
  ahí adentro no se detecta hasta que se ejecuta.
- **`INTO #tabla`**: crea una tabla nueva (temporal o real) a partir de un `SELECT`.
- **`INSERT INTO tabla`**: agrega filas a una tabla que ya existe.
- **`UNION ALL`**: pega los resultados de varias consultas, una debajo de otra, en una sola tabla (sin
  eliminar duplicados, a diferencia de `UNION` a secas).
- **`ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`**: le pone un número de fila (1, 2, 3...) a cada
  grupo de registros que compartan ciertas columnas, ordenados como tú digas. Se usa mucho aquí para
  quedarse con "solo el registro más reciente" quedándose después con `WHERE rn = 1`.
- **`TRY_CONVERT(BIGINT, campo)`**: intenta convertir un valor a número; si no se puede (por ejemplo, el
  campo tiene texto no numérico), devuelve `NULL` en vez de hacer fallar todo el script.

---

## 4. El mapa: cómo se conectan estos 11 archivos

Casi todos los scripts terminan alimentando una de estas 4 tablas "consolidadas" en la base
`Liberty_Pruebas_Actuaria`:

- **`DEVENGADA_GENERAL`**: toda la prima devengada (directa + cedida, sin importar el sistema de origen).
- **`SINIESTROS_GENERAL_IAXIS`**: incurrido + recobros + salvamentos, para pólizas de IAXIS/AS400.
- **`SINIESTROS_GENERAL_SISE`** (o `PU_CORREDORES_SINIESTROS_SISE`): lo mismo pero para pólizas de SISE.
- **`Facultativas`**: prima cedida en contratos de reaseguro facultativo.

```
Fuentes crudas (DWH)                Scripts de esta carpeta          Tablas consolidadas
─────────────────────                ───────────────────────         ────────────────────
DIRECTA_RESERVA_INTERFAZ      ──►   [1]_iaxis.sql             ──►   directa_reserva_general
                                                                            │
CEDIDAS_RESERVA_INTERFAZ      ──►   GENERAL_2_AS400.sql        ──►   cedidas_reserva_general
CEDIDAS_RESERVA_INTERFAZ_IAXIS──►   GENERAL_3_IAXIS.sql        ──►   cedidas_reserva_general_iaxis
CEDIDAS_TERREMOTO_...         ──►   GENERAL_4.sql              ──►   cedidas_terremoto_general
                                                                            │
PLANEACION_RPT (SISE, via                                                  ▼
 OPENQUERY) + las 4 de arriba  ──►   cedida_sise_iaxis.sql      ──►   DEVENGADA_GENERAL
PLANEACION_RPT (SISE)          ──►   Reserva_tecnica_sise_5.sql ──►   DEVENGADA_GENERAL

cedidas_iaxis / cedidas (AS400)──►   facultativos.sql           ──►   Facultativas

DWH_S_NOV_CONT_D, REASEGURO_H ──►   INCURRIDO_GENERAL_IAXIS.sql──►   SINIESTROS_GENERAL_IAXIS
REFIGVDT, F590475 (recobros)  ──►   Recobros_IAXIS.sql         ──►   SINIESTROS_GENERAL_IAXIS
REFIGVDT, F590475 (salvamento)──►   Salvamentos_IAXIS.sql      ──►   SINIESTROS_GENERAL_IAXIS
acc_sise_appgenerali_...       ──►   INCURRIDO_GENERAL_SISE_.sql──►   SINIESTROS_GENERAL_SISE
```

Nota el orden numérico en los nombres (`_1_iaxis`, `_2_AS400`, `_3_IAXIS`, `_4`): indica el orden en que se
deben correr, porque `cedida_sise_iaxis.sql` (que hace el `UNION ALL` final) depende de que las tablas
`directa_reserva_general`, `cedidas_reserva_general`, `cedidas_reserva_general_iaxis` y
`cedidas_terremoto_general` ya existan.

---

## 5. Archivo por archivo

### `[DIRECTA_RESERVA_INTERFAZ_GENERAL]_1 _iaxis.sql`
**Qué hace**: Lee `Liberty.RESERVAS.DIRECTA_RESERVA_INTERFAZ` (negocio directo, sin reaseguro), filtra por
un rango de periodo contable y por las cuentas de prima directa (`410305`, `410310`, `410315`, `510305`,
`510310`, `510315`), excluye `Libro = 'AG'`, le busca el tomador (cliente) a cada póliza, y calcula el valor
devengado. Después resuelve el corretaje/cocorretaje (líder + asociados) y genera dos bloques: uno "original"
(el 100% asignado al intermediario líder) y otro de "co-corretaje" (repartido según `participacion`). Guarda
el resultado en la tabla real `liberty_pruebas_actuaria.dbo.directa_reserva_general`.
**Para qué sirve**: es el primer eslabón del cálculo de prima devengada para negocio directo — de aquí sale
el concepto `Devengada_Directa`.
**Dato a tener en cuenta**: las cuentas `510310`, `410315`, `510315`, `41310`, `510305`, `410305` invierten
el signo del valor (`*-1`) porque contablemente esas cuentas se registran al revés.

### `CEDIDAS_RESERVA_INTERFAZ_GENERAL_2_AS400.sql`
**Qué hace**: Lo mismo que el anterior, pero para negocio **cedido** (reaseguro) cuya fuente es
`Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ` (el origen AS400/histórico de cedidas). Filtra cuentas
`510305`, `410305`, excluye `Libro = 'AG'`, resuelve el intermediario (con una lógica más elaborada que el
script directa, porque aquí puede haber varios intermediarios candidatos por póliza y hay que decidir cuál
usar — de ahí las columnas `regla_intermediario` y `requiere_revision`), y arma el valor cedido +
co-corretaje. Guarda en `liberty_pruebas_actuaria.dbo.cedidas_reserva_general`.
**Para qué sirve**: calcula `Devengada_Cedida` para el negocio reasegurado que viene del sistema AS400.

### `CEDIDAS_RESERVA_INTERFAZ_GENERAL_3_IAXIS.sql`
**Qué hace**: Es el mismo cálculo que el anterior, pero la fuente es
`Liberty.RESERVAS.CEDIDAS_RESERVA_INTERFAZ_IAXIS` (cedidas del sistema IAXIS). Tiene un paso adicional:
como el "documento" de la fuente puede no coincidir exactamente con el de `dwh_polizas_h`, resuelve un
"documento real" antes de buscar el corretaje, marcando con `regla_documento`/`requiere_revision_documento`
los casos ambiguos (sin documento resuelto, o con más de uno). Guarda en
`liberty_pruebas_actuaria.dbo.cedidas_reserva_general_iaxis`.
**Para qué sirve**: calcula `Devengada_Cedida_IAXIS`. Al final del archivo hay un bloque largo de
**validación** (comparando el total de la tabla base contra el total de la tabla final) — es intencional,
no es código muerto (ver regla del `CLAUDE.md` sobre queries de validación al final de los scripts).

### `CEDIDAS_TERREMOTO_RESERVA_INTERFAZ_GENERAL_4.sql`
**Qué hace**: Calcula la prima cedida específicamente para el reaseguro de **terremoto**, desde
`Liberty.RESERVAS.CEDIDAS_TERREMOTO_RESERVA_INTERFAZ` (cuentas `410305`, `510305`, `419595`, y solo donde
`FUENTE_INTERFAZ = 'TERR'`). Resuelve el intermediario en varias capas (primero por póliza+certificado,
luego por sucursal especial `94`→`'9400'`, luego por póliza sola, luego por `DWH_POLIZAS_H`) porque esta
fuente es más incompleta que las otras en ese campo. Guarda en
`liberty_pruebas_actuaria.dbo.cedidas_terremoto_general`.
**Para qué sirve**: genera `Devengada_Cedida_Terremoto`, la cuarta y última pieza que `cedida_sise_iaxis.sql`
junta al final.

### `cedida_sise_iaxis.sql`
**Qué hace**: Es el más largo y el que "cierra" el proceso de prima devengada. Tiene tres bloques
independientes al inicio (cedida SISE vía `OPENQUERY`, cedida IAXIS, cedida AS400) que insertan directo en
`DEVENGADA_GENERAL`, y al final un cuarto bloque que hace un gran `UNION ALL` de las 4 tablas "general" que
generaron los 4 scripts anteriores (`directa_reserva_general`, `cedidas_reserva_general`,
`cedidas_reserva_general_iaxis`, `cedidas_terremoto_general`) e inserta todo en `DEVENGADA_GENERAL` también.
**Para qué sirve**: es el punto donde toda la prima devengada (directa + cedida, de todos los sistemas de
origen) queda consolidada en una sola tabla para reportar.
**Dato a tener en cuenta**: debe correrse *después* de los 4 scripts numerados (`_1` a `_4`), porque
depende de sus tablas de salida.

### `facultativos.sql`
**Qué hace**: Calcula la prima cedida en contratos de **reaseguro facultativo** (`TIPO_CONTRATO = 'F'` /
`DCON = 'F'`), combinando IAXIS (`liberty.reservas.cedidas_iaxis`) y AS400 (`liberty.reservas.cedidas`),
resolviendo el intermediario y el corretaje de forma parecida a los scripts anteriores. Al final filtra
solo los intermediarios que aparecen en `claves_asociadas_pu_corredores` con `cia = 'IAXIS'` — hay un
comentario explícito pidiendo validar esos totales con "Nubia" antes y después de ese filtro. Guarda en
`[Liberty_Pruebas_Actuaria].[dbo].Facultativas`.
**Para qué sirve**: separa del resto de cedidas la prima de estos contratos negociados caso por caso, que
por su naturaleza especial se reporta aparte.

### `INCURRIDO_GENERAL_IAXIS.sql`
**Qué hace**: Es el más grande en alcance de negocio. Junta tres cosas distintas bajo el macro-concepto
`INCURRIDO`: (1) el incurrido de siniestros propiamente dicho, desde `liberty.sini.DWH_S_NOV_CONT_D`
(excluyendo `TIPO_NOVEDAD` 5 y 6); (2) la variación de reserva de reaseguro, desde
`liberty.MIDDLEWARE.DWH_REASEGURO_H`; y (3) los siniestros liquidados de reaseguro, desde
`liberty.MIDDLEWARE.BASE_REASEGUROS_H`. Cada uno se calcula también para su versión de co-corretaje. Todo se
une (`UNION ALL`) e inserta en `SINIESTROS_DETALLE_GENERAL` y luego, agregado por tomador, en
`SINIESTROS_GENERAL_IAXIS`.
**Para qué sirve**: es la fuente del concepto **Incurrido** que tu control de completitud excluye
explícitamente (porque ya tiene este chequeo propio, mucho más elaborado).
**Dato a tener en cuenta**: hay lógica de coaseguro (`VR_P_COASEGURO`, `GDPJVR`) que ajusta el valor según
el porcentaje que HDI realmente asume cuando comparte el riesgo con otra aseguradora en la misma póliza —
no confundir coaseguro con reaseguro (cedida): son mecanismos distintos de compartir riesgo.

### `INCURRIDO_GENERAL_SISE_.sql`
**Qué hace**: Lo mismo que el anterior (incurrido, con su parte de co-corretaje y de reaseguro), pero para
pólizas del canal SISE/Generali, con datos que vienen de una tabla ya pre-calculada
(`acc_sise_appgenerali_siniestros_incurridos_fusion`) en vez de las tablas crudas de siniestros. Resuelve
canal comercial, homologa el código de intermediario contra un maestro (`Maestro_intermediarios_Homologados`,
vía `OPENQUERY`), y separa el resultado en incurrido bruto, incurrido de reaseguro y sus versiones de
corretaje. Guarda en `[Liberty_Pruebas_Actuaria].[dbo].SINIESTROS_GENERAL_SISE`.
**Para qué sirve**: es el equivalente del script anterior pero para el canal SISE — por eso hay dos
"INCURRIDO_GENERAL", uno por cada sistema de origen.

### `Recobros_IAXIS.sql`
**Qué hace**: Calcula la plata que HDI logró **recuperar** después de pagar un siniestro (recobros), tanto
del sistema AS400 (`liberty.AS400.REFIGVDT`, filtrando `DTTNNU IN (31)`) como de IAXIS
(`liberty.AS400.F590475`, filtrando `IVCTIV IN (531, 539, 532, 540)`), con su respectiva versión de
co-corretaje. Inserta en `SINIESTROS_GENERAL_IAXIS`. Al final ajusta la `MODALIDAD` y el `TIPO_RIESGO` de
esas filas recién insertadas usando reglas específicas por rama (`OTH`, `AUT`) — son parches de
homologación de datos, no parte del cálculo de valor.
**Para qué sirve**: es la fuente del concepto **Recobro** que tu control excluye del alcance.

### `Salvamentos_IAXIS.sql`
**Qué hace**: Estructuralmente casi idéntico a `Recobros_IAXIS.sql` (mismas tablas fuente,
`REFIGVDT`/`F590475`), pero filtrando los tipos de movimiento de **salvamento** (`DTTNNU IN (30)`,
`IVCTIV IN (530)`) en vez de recobro. También inserta en `SINIESTROS_GENERAL_IAXIS` y ajusta modalidad/tipo
de riesgo al final.
**Para qué sirve**: es la fuente del concepto **Salvamento** que tu control excluye del alcance.

### `Reserva_tecnica_sise_5.sql`
**Qué hace**: Trae desde SISE (vía `OPENQUERY`) el valor de `reserva_tecnica` por póliza, con la misma
lógica de homologación de canal/sucursal que los otros scripts de SISE, y lo inserta en `DEVENGADA_GENERAL`
como el concepto `Ajuste_reserva_tecnica` (con signo invertido).
**Para qué sirve**: es el ajuste de reserva técnica del canal SISE — el homólogo, para SISE, de lo que los
scripts `DIRECTA`/`CEDIDAS` calculan para IAXIS/AS400 a partir de `VALOR_RESERVA_CONTABLE`.

---

## 6. Cómo esto se conecta con tu control de completitud

Tu script `control_completitud_cuentas.sql` (en la raíz del repo) reutiliza las mismas 4 fuentes de reserva
contable que los scripts `[1]_iaxis`, `_2_AS400`, `_3_IAXIS` y `_4` de esta carpeta leen — **las mismas
tablas y los mismos filtros de cuenta/libro** — pero sin la parte de corretaje/tomador/intermediario. Solo
revisa: ¿`VALOR_RESERVA_CONTABLE` tiene un valor o está vacío?, para cada combinación de cuenta + libro +
periodo.

Las cuentas que tu control **excluye a propósito** (Incurrido, Recobros, Salvamentos, IVA AG) son
justamente las que calculan `INCURRIDO_GENERAL_IAXIS.sql`, `INCURRIDO_GENERAL_SISE_.sql`,
`Recobros_IAXIS.sql` y `Salvamentos_IAXIS.sql` — por eso este documento te sirve también para entender
*por qué* esas cuentas quedan fuera: ya tienen su propio proceso, mucho más complejo, con reglas de
corretaje y de reaseguro que tu control (intencionalmente) no repite.
