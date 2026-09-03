# Ejercicio de Lectura Crítica — Parte 3

**Trabajo Práctico:** Base de Datos II — UTN
**Proyecto:** Food Store
**Motor:** PostgreSQL

---

## Script 1

### Enunciado original

```sql
-- Generado para: dar de baja las funciones de películas retiradas de cartel

UPDATE funcion
SET activa = FALSE;
```

### 1. Qué filas afectaría tal como está escrito

El script no tiene cláusula `WHERE`. PostgreSQL ejecutará el `UPDATE`
sobre **todas las filas** de la tabla `funcion`, sin distinción alguna.
Todas las funciones, incluyendo las activas, futuras, y aquellas que no
corresponden a películas retiradas de cartel, quedarán con `activa = FALSE`.

### 2. Por qué no cumple la consigna de forma segura

La consigna dice "dar de baja las funciones de películas retiradas de
cartel". Eso implica una condición de filtro: solamente deben afectarse
las funciones vinculadas a películas que hayan sido retiradas.

Sin `WHERE`, el script cumple literalmente su efecto técnico (actualizar
`activa = FALSE`) pero lo hace sobre la totalidad de la tabla, no sobre
el subconjunto correcto. Es un error de alcance: el script es más amplio
que la intención declarada en el comentario.

Este tipo de error es especialmente peligroso porque:

- No genera ningún error de PostgreSQL — se ejecuta sin advertencias.
- Es difícil de detectar hasta que el daño ya está hecho.
- Puede afectar funciones vigentes o futuras que no debían tocarse.

### 3. Versión corregida

```sql
BEGIN;

UPDATE funcion
SET activa = FALSE
WHERE pelicula_id IN (
    SELECT id
    FROM pelicula
    WHERE <condicion_de_retirada>   -- completar según el esquema real
);

-- Verificar filas afectadas antes de confirmar:
-- SELECT * FROM funcion WHERE activa = FALSE;

ROLLBACK;
-- Reemplazar ROLLBACK por COMMIT solo cuando el resultado sea el esperado.
```

### 4. Explicación línea por línea

```sql
BEGIN;
```
Abre una transacción explícita. Ningún cambio será visible para otras
sesiones ni persistirá hasta que se ejecute `COMMIT`. Permite verificar
el resultado y revertir con `ROLLBACK` si no es el esperado.

```sql
UPDATE funcion
SET activa = FALSE
```
Actualiza la columna `activa` a `FALSE` en la tabla `funcion`. Hasta
aquí es igual al script original.

```sql
WHERE pelicula_id IN (
    SELECT id
    FROM pelicula
    WHERE <condicion_de_retirada>
);
```
Restringe el `UPDATE` únicamente a las filas de `funcion` cuya
`pelicula_id` corresponda a una película que cumpla la condición de
retirada. El placeholder `<condicion_de_retirada>` debe completarse con
la columna real del esquema que indica que la película fue retirada de
cartel (por ejemplo, `retirada = TRUE`, `estado = 'RETIRADA'`, o la
expresión que corresponda según la definición real de la tabla
`pelicula`).

**Nota importante:** el esquema genérico proporcionado por la consigna
no especifica el nombre exacto de esa columna. No se inventa una columna;
se deja el placeholder para que sea completado con el dato real del
esquema utilizado.

```sql
ROLLBACK;
```
Revierte todos los cambios de la transacción. Debe reemplazarse por
`COMMIT` únicamente después de verificar que las filas afectadas son
exactamente las esperadas y que ninguna función vigente fue incluida por
error.

---

## Script 2

### Enunciado original

```sql
-- Generado para: limpiar las categorías sin productos asociados

DELETE FROM categoria
WHERE id NOT IN (SELECT categoria_id FROM producto);
```

### 1. Qué filas afectaría tal como está escrito

La intención declarada es eliminar las categorías que no tengan ningún
producto asociado. Sin embargo, el script tiene un problema grave
relacionado con el comportamiento de `NOT IN` cuando la subconsulta
contiene valores `NULL`.

### 2. Por qué puede no cumplir la consigna de forma segura

**El problema de NOT IN con NULLs**

En SQL, `NOT IN` se evalúa usando comparaciones de igualdad. Si la
subconsulta `SELECT categoria_id FROM producto` devuelve al menos un
valor `NULL` (por ejemplo, si alguna fila de `producto` tiene
`categoria_id = NULL`), entonces toda la expresión `id NOT IN (...)`
evaluará a `NULL` —no a `TRUE` ni a `FALSE`— para **cada fila** de
`categoria`.

Cuando una condición `WHERE` evalúa a `NULL`, PostgreSQL la trata como
falsa: la fila no cumple el filtro y no es afectada. El resultado es que
el `DELETE` **no elimina ninguna fila**, aunque existan categorías
genuinamente sin productos.

En el esquema de Food Store, `producto.categoria_id` está definido como
`BIGINT NOT NULL`, por lo que en este proyecto concreto la subconsulta
no puede devolver `NULL` y el problema no se activaría. Sin embargo,
el script es estructuralmente inseguro: depende de una restricción de
integridad del esquema para funcionar correctamente, y no lo hace
evidente. En un esquema donde `categoria_id` admitiera `NULL`, el
`DELETE` fallaría silenciosamente sin afectar ninguna fila y sin
producir ningún error.

**Resumen del riesgo:**

| Situación | Resultado de NOT IN |
|-----------|---------------------|
| Subconsulta sin NULLs | Funciona como se espera |
| Subconsulta con al menos un NULL | No elimina ninguna fila (silencioso) |

### 3. Versión corregida

```sql
BEGIN;

DELETE FROM categoria
WHERE NOT EXISTS (
    SELECT 1
    FROM producto
    WHERE producto.categoria_id = categoria.id
);

-- Verificar filas afectadas antes de confirmar:
-- SELECT * FROM categoria WHERE NOT EXISTS (
--     SELECT 1 FROM producto WHERE producto.categoria_id = categoria.id
-- );

ROLLBACK;
-- Reemplazar ROLLBACK por COMMIT solo cuando el resultado sea el esperado.
```

### 4. Explicación línea por línea

```sql
BEGIN;
```
Abre una transacción explícita. Permite verificar el resultado antes de
confirmar el cambio.

```sql
DELETE FROM categoria
```
Elimina filas de la tabla `categoria`. Hasta aquí igual al script
original.

```sql
WHERE NOT EXISTS (
    SELECT 1
    FROM producto
    WHERE producto.categoria_id = categoria.id
);
```
Para cada fila de `categoria`, la subconsulta correlacionada busca si
existe al menos un producto cuya `categoria_id` coincida con el `id`
de esa categoría. `NOT EXISTS` devuelve `TRUE` cuando no existe ninguna
fila que cumpla esa condición, es decir, cuando la categoría no tiene
productos asociados.

**Por qué `NOT EXISTS` es seguro frente a NULLs:**
`EXISTS` y `NOT EXISTS` evalúan la *existencia* de filas, no igualdad
de valores. No realizan comparaciones directas que puedan producir
`NULL`. Si `categoria_id` es `NULL` en alguna fila de `producto`, esa
fila simplemente no satisface la condición `WHERE producto.categoria_id
= categoria.id` y no se cuenta como coincidencia. El resultado de `NOT
EXISTS` sigue siendo `TRUE` o `FALSE`, nunca `NULL`. El comportamiento
es predecible independientemente de si la columna admite nulos.

```sql
ROLLBACK;
```
Revierte todos los cambios. Debe reemplazarse por `COMMIT` únicamente
después de confirmar que las categorías a eliminar son exactamente las
esperadas y que ninguna categoría con productos quedó incluida.

---

## Aplicación del protocolo de seguridad

Ambas versiones corregidas incorporan el protocolo de seguridad exigido
por la cátedra (`Protocolo_seguridad.md`):

1. Los scripts se ejecutan sobre `mi_proyecto_copia`, nunca sobre la
   base original.
2. Cada script se envuelve en `BEGIN; ... ROLLBACK;` para prueba previa.
3. Se incluye una consulta de verificación comentada para revisar las
   filas que serían afectadas antes de confirmar.
4. `COMMIT` se usa únicamente cuando el resultado observado es el
   esperado y fue revisado por el alumno.
5. Ninguno de estos scripts debe ejecutarse automáticamente; el alumno
   los revisa y los ejecuta manualmente en DBeaver.
