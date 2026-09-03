# DUIA — Parte 2: Laboratorio de Concurrencia

**Trabajo Práctico:** Base de Datos II — UTN
**Proyecto:** Food Store
**Base de datos de pruebas:** `mi_proyecto_copia`
**Cliente:** DBeaver (dos sesiones concurrentes)
**Motor:** PostgreSQL

---

## Herramienta utilizada

**IA de asistencia** (utilizada para generar explicaciones teóricas de los
fenómenos de concurrencia y para contrastar con el comportamiento observado
en PostgreSQL).

---

## Spec o prompt utilizado

Los prompts originales utilizados con la IA no están registrados en el
repositorio. Lo que está verificado en el historial Git es el resultado
documentado:

- Commit `ef54678` (03/09/2026 18:27) — creación de
  `informe_concurrencia.md` con los escenarios 1 (lectura no repetible)
  y 2 (espera por bloqueo).
- Commit `e0eb583` (03/09/2026 18:39) — incorporación del escenario 3
  (lectura fantasma) al mismo archivo.

---

## Qué generó la IA

La IA generó explicaciones teóricas para cada uno de los tres escenarios
experimentales, describiendo los mecanismos de PostgreSQL (MVCC, niveles
de aislamiento, bloqueos de fila) que producen los fenómenos observados.

### Escenario 1 — Lectura no repetible

La IA explicó que bajo `READ COMMITTED` el snapshot de visibilidad se
redefine al comienzo de cada sentencia, por lo que una segunda lectura
dentro de la misma transacción puede ver cambios confirmados por otra
sesión. Bajo `REPEATABLE READ`, explicó que PostgreSQL fija un único
snapshot al inicio de la transacción, ignorando cambios confirmados
posteriormente.

### Escenario 2 — Espera por bloqueo

La IA explicó que `SELECT ... FOR UPDATE` adquiere un bloqueo sobre las
filas devueltas, retenido hasta el `COMMIT` o `ROLLBACK` de la
transacción, y que una segunda transacción que necesite un bloqueo
incompatible sobre la misma fila debe esperar hasta que la primera lo
libere.

### Escenario 3 — Lectura fantasma

La IA explicó que bajo `READ COMMITTED` el snapshot por sentencia permite
ver nuevas filas insertadas y confirmadas por otras sesiones, mientras que
bajo `REPEATABLE READ` el snapshot fijo por transacción las oculta.
También describió el comportamiento de `SERIALIZABLE`.

---

## Qué se aceptó

Se aceptaron las siguientes afirmaciones de la IA por resultar correctas
y consistentes con el comportamiento observado en PostgreSQL:

- Bajo `READ COMMITTED` el snapshot es por sentencia: validado por el
  cambio de `precio_lista` observado en el Escenario 1 y por el cambio
  de `COUNT(*)` en el Escenario 3.
- Bajo `REPEATABLE READ` el snapshot es fijo por transacción: validado
  por la estabilidad del valor leído en el Escenario 1 y del `COUNT(*)`
  en el Escenario 3.
- `SELECT ... FOR UPDATE` retiene el bloqueo de fila hasta el `COMMIT` o
  `ROLLBACK`, y una segunda sesión que requiere el mismo bloqueo debe
  esperar: validado por el comportamiento observado en el Escenario 2.
- PostgreSQL implementa MVCC manteniendo múltiples versiones de las
  tuplas; el nivel de aislamiento determina cuál versión es visible.

---

## Qué se modificó o descartó, y por qué

Durante la revisión crítica se detectaron imprecisiones en las
explicaciones generadas por la IA. Fueron corregidas antes de
incorporarse al informe. Las correcciones están documentadas en
`informe_concurrencia.md` bajo la sección "Contraste entre explicación
de IA y comportamiento real" de cada escenario.

### Corrección 1 — Bloqueo de fila vs. modo de bloqueo de tabla ROW EXCLUSIVE

**Afirmación original de la IA:** vinculó el bloqueo adquirido por
`SELECT ... FOR UPDATE` con el modo de bloqueo de tabla `ROW EXCLUSIVE`.

**Corrección aplicada:** `SELECT ... FOR UPDATE` adquiere un bloqueo
**a nivel de fila** (row-level lock). `ROW EXCLUSIVE` es un modo de
bloqueo **a nivel de tabla**, distinto, que adquieren por ejemplo los
`UPDATE`. Ambos conceptos no deben confundirse ni mezclarse.

### Corrección 2 — Afirmación absoluta sobre SELECT normal y bloqueos

**Afirmación original de la IA:** afirmó de manera absoluta que un
`SELECT` normal "nunca se bloquea".

**Corrección aplicada:** en el experimento realizado, un `SELECT` normal
no entró en conflicto con el bloqueo de fila adquirido por
`FOR UPDATE` gracias a MVCC. Sin embargo, la afirmación no debe
presentarse como una verdad universal sin matices, ya que existen
situaciones en las que un `SELECT` puede verse afectado por bloqueos.

### Corrección 3 — REPEATABLE READ y lecturas fantasma según el estándar SQL

**Afirmación original de la IA:** presentó `REPEATABLE READ` como un
nivel que en general evita las lecturas fantasma, sin distinguir entre
el estándar SQL y la implementación de PostgreSQL.

**Corrección aplicada:** según la clasificación tradicional del estándar
SQL, `REPEATABLE READ` **puede permitir** lecturas fantasma. No obstante,
PostgreSQL implementa `REPEATABLE READ` mediante **snapshot isolation**,
por lo que en PostgreSQL las lecturas fantasma **no aparecen** en este
nivel. La distinción entre el comportamiento del estándar y el de
PostgreSQL debe quedar explícita.

### Corrección 4 — Descripción de SERIALIZABLE en PostgreSQL

**Afirmación original de la IA:** describió `SERIALIZABLE` de PostgreSQL
como un nivel basado en bloqueos de rango (range locks) tradicionales.

**Corrección aplicada:** PostgreSQL implementa `SERIALIZABLE` mediante
**Serializable Snapshot Isolation (SSI)**, que combina snapshot isolation
con mecanismos de detección de ciclos de dependencia entre transacciones
(predicate locking). No debe describirse como uso tradicional de range
locks.

---

## Verificación realizada

Los tres escenarios fueron ejecutados manualmente en DBeaver sobre
`mi_proyecto_copia` utilizando dos sesiones concurrentes, siguiendo el
protocolo de seguridad del TP.

### Escenario 1 — Lectura no repetible

**Tabla/registro utilizado:** `producto(id = 2)`

**Prueba con `READ COMMITTED`:**

| Paso | Sesión | Acción | Resultado observado |
|------|--------|--------|---------------------|
| 1 | A | `BEGIN; SET TRANSACTION ISOLATION LEVEL READ COMMITTED;` `SELECT precio_lista FROM producto WHERE id = 2;` | `precio_lista = 1000.00` |
| 2 | B | `BEGIN; UPDATE producto SET precio_lista = 1500.00 WHERE id = 2; COMMIT;` | Cambio confirmado |
| 3 | A | `SELECT precio_lista FROM producto WHERE id = 2;` (misma transacción) | `precio_lista = 1500.00` |

Resultado: la segunda lectura de A devolvió un valor distinto al de la
primera dentro de la misma transacción. **Se verificó la lectura no
repetible.**

**Prueba con `REPEATABLE READ`:**

| Paso | Sesión | Acción | Resultado observado |
|------|--------|--------|---------------------|
| 1 | A | `BEGIN; SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;` `SELECT precio_lista FROM producto WHERE id = 2;` | `precio_lista = 1500.00` |
| 2 | B | `BEGIN; UPDATE producto SET precio_lista = 2000.00 WHERE id = 2; COMMIT;` | Cambio confirmado |
| 3 | A | `SELECT precio_lista FROM producto WHERE id = 2;` (misma transacción) | `precio_lista = 1500.00` |

Resultado: la segunda lectura de A mantuvo el valor original del snapshot.
**PostgreSQL evitó la lectura no repetible bajo `REPEATABLE READ`.**

---

### Escenario 2 — Espera por bloqueo

**Registro utilizado:** `producto(id = 2)` con `precio_lista = 2000.00`

| Paso | Sesión | Acción | Resultado observado |
|------|--------|--------|---------------------|
| 1 | A | `BEGIN; SELECT ... FROM producto WHERE id = 2 FOR UPDATE;` | Consulta devuelta; bloqueo de fila retenido |
| 2 | B | `BEGIN; SELECT ... FROM producto WHERE id = 2 FOR UPDATE;` | Sesión B **quedó esperando** sin devolver resultado |
| 3 | A | `COMMIT;` | Bloqueo liberado |
| 4 | B | — | Sesión B continuó inmediatamente y devolvió `producto(id = 2)` |
| 5 | B | `ROLLBACK;` | Transacción de B cerrada |

Resultado: se verificó que `SELECT ... FOR UPDATE` adquiere un bloqueo
exclusivo de fila retenido hasta el `COMMIT`, y que una segunda sesión
que necesita el mismo bloqueo queda en espera hasta que la primera lo
libera.

---

### Escenario 3 — Lectura fantasma

**Tabla utilizada:** `producto`

**Prueba con `READ COMMITTED`:**

| Paso | Sesión | Acción | Resultado observado |
|------|--------|--------|---------------------|
| 1 | A | `BEGIN; SET TRANSACTION ISOLATION LEVEL READ COMMITTED;` `SELECT COUNT(*) FROM producto;` | `COUNT(*) = 1` |
| 2 | B | `BEGIN; INSERT INTO producto (...) VALUES (...); COMMIT;` | Inserción confirmada |
| 3 | A | `SELECT COUNT(*) FROM producto;` (misma transacción) | `COUNT(*) = 2` |
| 4 | A | `ROLLBACK;` | Transacción cerrada |

Resultado: el `COUNT(*)` cambió de 1 a 2 dentro de la misma transacción.
**Se verificó la lectura fantasma bajo `READ COMMITTED`.**

**Prueba con `REPEATABLE READ`:**

Estado inicial: 2 productos en la tabla tras el experimento anterior.

| Paso | Sesión | Acción | Resultado observado |
|------|--------|--------|---------------------|
| 1 | A | `BEGIN; SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;` `SELECT COUNT(*) FROM producto;` | `COUNT(*) = 2` |
| 2 | B | `BEGIN; INSERT INTO producto (...) VALUES (...); COMMIT;` | Inserción confirmada |
| 3 | A | `SELECT COUNT(*) FROM producto;` (misma transacción) | `COUNT(*) = 2` |
| 4 | A | `ROLLBACK;` | Transacción cerrada |

Resultado: el `COUNT(*)` se mantuvo en 2 a pesar del `INSERT` confirmado
por B. **PostgreSQL evitó la lectura fantasma bajo `REPEATABLE READ`
mediante snapshot isolation.**

---

### Resumen de verificación

| Escenario | Nivel probado | Fenómeno esperado | Observado en PostgreSQL |
|-----------|--------------|-------------------|------------------------|
| Lectura no repetible | `READ COMMITTED` | Lectura no repetible visible | ✅ Confirmado |
| Lectura no repetible | `REPEATABLE READ` | Lectura estable | ✅ Confirmado |
| Espera por bloqueo | — | Bloqueo y espera hasta COMMIT | ✅ Confirmado |
| Lectura fantasma | `READ COMMITTED` | Fantasma visible | ✅ Confirmado |
| Lectura fantasma | `REPEATABLE READ` | Fantasma invisible | ✅ Confirmado |
