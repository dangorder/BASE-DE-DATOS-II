# Informe de Experimentos de Concurrencia — PostgreSQL

**Base de Datos II — UTN**

**Proyecto:** Food Store
**Base de datos de pruebas:** `mi_proyecto_copia`
**Cliente:** DBeaver (dos sesiones concurrentes)
**Motor:** PostgreSQL

---

## Escenario 1 — Lectura no repetible (Non-Repeatable Read)

**Tabla utilizada:** `producto`
**Registro utilizado:** `producto` con `id = 2`

### Objetivo

Verificar cómo el nivel de aislamiento de la transacción afecta la consistencia de las lecturas: demostrar que bajo `READ COMMITTED` se produce una lectura no repetible, y que bajo `REPEATABLE READ` PostgreSQL mantiene la misma versión visible de los datos durante toda la transacción.

### Prueba con `READ COMMITTED`

#### Comandos — Sesión A

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 2;
```

**Resultado inicial observado:** `precio_lista = 1000.00`

#### Comandos — Sesión B (con la transacción de A abierta)

```sql
BEGIN;

UPDATE producto
SET precio_lista = 1500.00
WHERE id = 2;

COMMIT;
```

#### Comandos — Sesión A (misma transacción)

```sql
SELECT id, nombre, precio_lista
FROM producto
WHERE id = 2;
```

**Resultado observado:** `precio_lista = 1500.00`

#### Resultado observado

La segunda consulta de la Sesión A devolvió un valor distinto al de la primera (`1500.00` en lugar de `1000.00`) dentro de la misma transacción. **Se verificó una lectura no repetible.** Luego se cerró la transacción.

#### Explicación técnica

Bajo `READ COMMITTED` (nivel por defecto de PostgreSQL), el *snapshot* de visibilidad se redefine al comienzo de **cada sentencia**, no al comienzo de la transacción. Por lo tanto, cuando la Sesión B confirma su `UPDATE` con `COMMIT` mientras la Sesión A sigue abierta, la nueva versión (`1500.00`) pasa a ser visible. La segunda consulta de A, al tomar un *snapshot* nuevo, ve esa versión actualizada. Una misma consulta dentro de una misma transacción devolvió resultados distintos: exactamente la anomalía de lectura no repetible.

### Prueba con `REPEATABLE READ`

#### Comandos — Sesión A

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 2;
```

**Resultado inicial observado:** `precio_lista = 1500.00`

#### Comandos — Sesión B (con la transacción de A abierta)

```sql
BEGIN;

UPDATE producto
SET precio_lista = 2000.00
WHERE id = 2;

COMMIT;
```

#### Comandos — Sesión A (misma transacción)

```sql
SELECT id, nombre, precio_lista
FROM producto
WHERE id = 2;
```

**Resultado observado:** `precio_lista = 1500.00`

#### Resultado observado

La segunda consulta de la Sesión A siguió devolviendo `1500.00`, a pesar de que la Sesión B ya había confirmado el cambio a `2000.00`. **PostgreSQL mantuvo la misma versión visible para la Sesión A bajo `REPEATABLE READ`.** Posteriormente se cerraron las transacciones correspondientes.

#### Explicación técnica

Bajo `REPEATABLE READ`, PostgreSQL fija un **único *snapshot*** al comienzo de la transacción (en la primera sentencia que accede a datos). Todas las consultas posteriores usan ese mismo *snapshot* y **ignoran** cualquier cambio confirmado por otras transacciones después. Por eso la Sesión A siguió viendo `1500.00` aunque `producto(id=2)` ya tenía físicamente una versión `2000.00`. MVCC soporta esto manteniendo múltiples versiones de la tupla; el nivel de aislamiento determina cuál de ellas es visible.

#### Contraste entre explicación de IA y comportamiento real

La explicación coincidió con el comportamiento observado: en `READ COMMITTED` el *snapshot* es por sentencia (por eso cambió el valor), y en `REPEATABLE READ` el *snapshot* es fijo por transacción (por eso el valor no cambió). Los resultados de ambas sesiones confirmaron esta interpretación sin desviaciones relevantes.

#### Conclusión

El nivel `READ COMMITTED` permite la lectura no repetible, mientras que `REPEATABLE READ` la evita congelando la vista de los datos por toda la transacción. Este comportamiento está soportado por el mecanismo MVCC de PostgreSQL.

---

## Escenario 2 — Espera por bloqueo (SELECT ... FOR UPDATE)

**Registro utilizado:** `producto(id = 2)`, cuyo precio actual era `2000.00`.

### Objetivo

Comprobar que `SELECT ... FOR UPDATE` adquiere un bloqueo sobre la fila devuelta y que una segunda transacción que necesita un bloqueo incompatible debe esperar hasta que la primera libere el bloqueo (mediante `COMMIT` o `ROLLBACK`).

#### Comandos — Sesión A

```sql
BEGIN;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 2
FOR UPDATE;
```

**Resultado observado:** la consulta devolvió el producto y la transacción quedó abierta (con el bloqueo de fila retenido).

#### Comandos — Sesión B

```sql
BEGIN;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 2
FOR UPDATE;
```

**Resultado observado:** la consulta de la Sesión B **quedó esperando** y no devolvió inmediatamente el resultado.

#### Liberación del bloqueo (en la Sesión A, mientras B esperaba)

```sql
COMMIT;
```

**Resultado observado:** inmediatamente después del `COMMIT` de A, la consulta de la Sesión B pudo continuar y devolvió `producto(id = 2)`.

#### Cierre de la sesión B

```sql
ROLLBACK;
```

#### Resultado observado

La Sesión A adquirió un bloqueo exclusivo de fila sobre `producto(id=2)`. La Sesión B intentó adquirir el mismo bloqueo y quedó en espera hasta que A confirmó (`COMMIT`) y liberó el bloqueo; recién entonces B pudo continuar y devolver la fila.

#### Explicación técnica

`SELECT ... FOR UPDATE` bloquea explícitamente las filas que devuelve mediante un **bloqueo exclusivo de nivel de fila** (row-level lock), retenido hasta el `COMMIT` o `ROLLBACK` de la transacción. Como los bloqueos de fila para escritura son mutuamente excluyentes, la Sesión B no pudo obtener el bloqueo sobre la misma tupla mientras A lo retenía, quedando en el estado de espera del gestor de bloqueos. Al confirmar, A liberó todos sus bloqueos; el gestor de bloqueos despertó a B, que obtuvo el bloqueo y completó su consulta.

#### Contraste entre explicación de IA y comportamiento real

La explicación generada por IA fue contrastada con el comportamiento real y resultó **correcta en términos generales**: `FOR UPDATE` genera un bloqueo sobre la fila y una segunda transacción que necesita un bloqueo incompatible debe esperar. No obstante, en la **revisión crítica** se detectaron dos precisiones terminológicas importantes:

1. **No debe confundirse el bloqueo de fila adquirido por `SELECT ... FOR UPDATE` con el modo de bloqueo de tabla `ROW EXCLUSIVE`.** El `FOR UPDATE` adquiere un bloqueo a nivel de fila; `ROW EXCLUSIVE` es un modo de bloqueo de tabla distinto (el que adquieren, por ejemplo, los `UPDATE`), y son conceptos que no deben mezclarse.
2. **Debe evitarse afirmar de manera absoluta que un `SELECT` normal "nunca se bloquea".** En este experimento concreto, un `SELECT` normal no entra en conflicto con el bloqueo de fila de `FOR UPDATE` y, gracias a MVCC, puede realizar la lectura sin esperar; pero la afirmación no debe presentarse como una verdad universal sin matices.

#### Conclusión

`SELECT ... FOR UPDATE` sobre `producto(id=2)` demostró que PostgreSQL combina **MVCC** (que permite lecturas concurrentes sin bloqueos) con **bloqueos exclusivos de fila** (que serializan el acceso de escritura). La Sesión A retuvo el bloqueo, la Sesión B esperó, y la liberación del bloqueo por el `COMMIT` de A permitió que B continuara. El experimento valida el control de concurrencia de PostgreSQL y deja registradas las precisiones terminológicas necesarias para una documentación correcta.
