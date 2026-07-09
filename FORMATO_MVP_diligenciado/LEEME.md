# FORMATO_MVP diligenciado — qué se llenó y de dónde salió

Esta carpeta contiene el formato corporativo `FORMATO_MVP (2).xlsx` diligenciado con la información
**real** del proyecto de este repositorio (el control de completitud de cuentas contables en el DWH).
Solo se llenó lo que está documentado en el repo — **nada fue inventado**; lo que no se pudo verificar
quedó vacío o marcado como `(pendiente)`.

## Archivos

| Archivo | Hoja del formato | Contenido |
|---|---|---|
| `HU.csv` | `HU` | Historia de usuario y alcance del control de completitud |
| `Diccionario_Datos.csv` | `Diccionario_Datos` | 19 filas: los campos que el control consume de las 4 tablas fuente |
| `Formato_KPI.csv` | `Formato KPI` | 3 indicadores que el control calcula (pct_completitud, semaforo, sin_valor) |
| `Formato_reglas_calidad.csv` | `Formato_reglas_calidad` | 14 reglas: las condiciones reales del script, una por tabla + columna |
| `Carta_Certificacion.csv` | `Carta_Certificación` | Campos de la carta; solo se llenó lo derivable (proceso, alcance, script) |
| `FORMATO_MVP_diligenciado.xlsx` | (todas) | Copia del Excel original con las hojas anteriores ya llenas |

Los CSVs están en **UTF-8 con BOM y separador `;`** para que Excel (configuración regional de
Colombia) los abra directamente en columnas.

Las hojas `Instrucciones` y `Tipos De Gráficos` no se llenan: son guías del formato, no campos.
Las 4 filas de ejemplo que traía `Diccionario_Datos` se descartaron (eran ejemplos del formato, no
datos del proyecto).

## De dónde salió cada dato (trazabilidad)

- **Contexto, historia de usuario, exclusiones, restricciones, responsables (Andrey)** →
  `README.md` y `Hallazgos y Estado del Proyecto.md`.
- **Tablas fuente, campos, filtros, fórmulas de `pct_completitud` y `semaforo`, listas de cuentas,
  exclusión `Libro <> 'AG'`, `RAMO_PROD IS NOT NULL`, `FUENTE_INTERFAZ = 'TERR'`** →
  `control_completitud_cuentas.sql` (las fórmulas se copiaron literales del script).
- **Sistema maestro de origen de cada tabla (IAXIS / AS400), descripciones de negocio (cuenta,
  libro, reserva contable, ramo)** → `OriginProcessql/EXPLICACION_SCRIPTS.md`.
- **Tablero HTML como entregable** → `notebooks/dashboard_completitud.html` y
  `notebooks/tablero_completitud.ipynb`.

## Qué quedó vacío o pendiente, y por qué

| Campo | Razón |
|---|---|
| Data Owner, QA Responsable, Aprobó, fecha de aprobación (KPIs) | No están definidos en el repositorio; el control aún no se ha validado formalmente |
| Meta de los KPIs | No existe una meta definida todavía |
| Responsable dato origen/destino, Política de calidad, Data Decay, Longitud (diccionario) | No hay evidencia en el repo; requeriría consultar el diccionario corporativo o al dueño de cada tabla |
| Tipo de tabla origen (Hechos/Dimensional) | No está documentado para las tablas `*_RESERVA_INTERFAZ` |
| Sistema maestro de `CEDIDAS_TERREMOTO_RESERVA_INTERFAZ` | La documentación no indica si viene de IAXIS o AS400 |
| propietario_de_la_regla, owner técnico, owner de negocio (reglas) | No definidos en el repo |
| Dimensiones unicidad / exactitud (reglas) | El control actual solo cubre completitud y validez de alcance; la exactitud/razonabilidad es la Fase 2 (no iniciada) |
| Nombres, cargos, correos y firmas de la carta de certificación | No se conocen; además el script aún no se ha corrido contra un mes cerrado, así que no hay cifras que certificar |
| 2 cuentas adicionales excluidas del control | Pendiente confirmarlas con Andrey (ver `README.md`, sección 4) |

## Notas

- Los códigos de KPI (`CC-001` a `CC-003`) son **propuestos** — no existe codificación oficial aún.
- Algunos tipos de dato del diccionario están **inferidos del uso en el SQL** (ej. `CUENTA` se compara
  contra literales de texto → Texto; `periodo_contable_analisis` se compara contra un `INT` → Numérico);
  están marcados así en la columna correspondiente y conviene confirmarlos contra el esquema real del DWH.
- El estado de los 3 KPIs es "En validación" porque, según `Hallazgos y Estado del Proyecto.md`, el
  script está construido pero no se ha probado contra un mes cerrado con datos completos.
