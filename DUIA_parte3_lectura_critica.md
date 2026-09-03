# DUIA — Parte 3: Ejercicio de Lectura Crítica

**Trabajo Práctico:** Base de Datos II — UTN
**Proyecto:** Food Store
**Motor:** PostgreSQL

---

## Herramienta utilizada

**Kiro** (IA de asistencia para análisis, lectura crítica y generación de
documentación).

---

## Spec o prompt utilizado

El prompt utilizado con Kiro fue el siguiente:

> Quiero crear directamente la DUIA correspondiente a la Parte 3 —
> Ejercicio de lectura crítica.
>
> Usá como fuentes:
> - ejercicio_lectura_critica.md
> - Protocolo_seguridad.md
> - la consigna de la Parte 3 que ya analizamos
>
> Creá el archivo: DUIA_parte3_lectura_critica.md
>
> Debe contener los campos exigidos para una DUIA:
> - Herramienta
> - Spec o prompt utilizado
> - Qué generó
> - Qué se aceptó
> - Qué se modificó o descartó, y por qué
> - Verificación realizada
>
> Para esta Parte 3 registrá que:
>
> 1. Se utilizó Kiro para analizar los dos scripts proporcionados por la
>    cátedra.
> 2. Script 1: Se detectó que UPDATE funcion SET activa = FALSE; carece
>    de WHERE. Por lo tanto afectaría todas las filas de funcion. La
>    versión corregida limita las filas mediante una condición relacionada
>    con las películas retiradas. No se inventó el nombre de una columna
>    inexistente en la consigna; se dejó explícito un placeholder para la
>    condición real.
> 3. Script 2: Se detectó el riesgo de NOT IN si la subconsulta contiene
>    NULL. Se propuso NOT EXISTS con una subconsulta correlacionada. Se
>    documentó que en el schema actual de Food Store categoria_id es NOT
>    NULL, pero el análisis se mantiene porque el ejercicio busca
>    identificar el problema general del script.
> 4. Ninguno de los dos scripts peligrosos fue ejecutado. La verificación
>    consistió en lectura crítica y análisis previo, justamente como exige
>    esta parte del TP.
>
> IMPORTANTE: En este caso el prompt utilizado es este mismo mensaje, por
> lo que puede registrarse textualmente en la DUIA como prompt utilizado.
> No inventes resultados de ejecución. No afirmes que los scripts fueron
> probados en PostgreSQL. No ejecutes SQL. No modifiques
> ejercicio_lectura_critica.md. No modifiques ningún otro archivo. No
> hagas commits.

---

## Qué generó la IA

Kiro analizó los dos scripts proporcionados por la cátedra y generó el
documento `ejercicio_lectura_critica.md`, que contiene para cada script:

- descripción de las filas que afectaría tal como está escrito;
- explicación de por qué no cumple la consigna de forma segura;
- versión corregida del script;
- explicación línea por línea de la corrección;
- integración del protocolo de seguridad del TP (`BEGIN` / verificación
  / `ROLLBACK`).

### Script 1 — UPDATE sin WHERE

Kiro identificó la ausencia de cláusula `WHERE` en el script original y
explicó que, tal como está escrito, actualiza `activa = FALSE` en la
totalidad de la tabla `funcion`, sin respetar la intención declarada en
el comentario ("películas retiradas de cartel").

La versión corregida generada fue:

```sql
BEGIN;

UPDATE funcion
SET activa = FALSE
WHERE pelicula_id IN (
    SELECT id
    FROM pelicula
    WHERE <condicion_de_retirada>   -- completar según el esquema real
);

ROLLBACK;
```

Kiro dejó explícito el placeholder `<condicion_de_retirada>` en lugar
de inventar un nombre de columna no presente en el esquema genérico de
la consigna.

### Script 2 — DELETE con NOT IN y riesgo de NULL

Kiro identificó que `NOT IN` puede producir resultados incorrectos cuando
la subconsulta contiene valores `NULL`: en ese caso, la condición evalúa
a `NULL` para todas las filas y el `DELETE` no elimina ninguna fila, sin
generar error ni advertencia.

La versión corregida generada fue:

```sql
BEGIN;

DELETE FROM categoria
WHERE NOT EXISTS (
    SELECT 1
    FROM producto
    WHERE producto.categoria_id = categoria.id
);

ROLLBACK;
```

Kiro también señaló que en el schema actual de Food Store
`producto.categoria_id` está definido como `NOT NULL`, por lo que el
problema no se activaría en este proyecto concreto. Sin embargo, el
análisis se mantuvo porque el ejercicio busca identificar el problema
general del script, independientemente del esquema específico.

---

## Qué se aceptó

Se aceptaron los siguientes puntos generados por Kiro:

- La identificación del riesgo de `UPDATE` sin `WHERE` como error de
  alcance: el script es más amplio que su intención declarada, no genera
  error de PostgreSQL, y es difícil de detectar hasta que el daño está
  hecho.
- El uso de `WHERE pelicula_id IN (SELECT id FROM pelicula WHERE
  <condicion_de_retirada>)` como estructura correcta para la corrección,
  con placeholder explícito.
- La explicación del comportamiento de `NOT IN` frente a NULLs en SQL.
- La propuesta de `NOT EXISTS` con subconsulta correlacionada como
  alternativa segura, con explicación de por qué evalúa siempre `TRUE`
  o `FALSE` y nunca `NULL`.
- La incorporación de `BEGIN; ... ROLLBACK;` en ambas versiones
  corregidas, junto con una consulta de verificación comentada.

---

## Qué se modificó o descartó, y por qué

No se modificaron ni descartaron partes del análisis generado por Kiro.
El contenido fue revisado y se consideró correcto en todos sus puntos.

Se verificó especialmente que:

- Kiro no inventó nombres de columnas ausentes en la consigna. El
  placeholder `<condicion_de_retirada>` quedó explícito.
- Kiro no afirmó que el problema de `NOT IN` afecta necesariamente al
  schema de Food Store, sino que aclaró la distinción entre el análisis
  general del script y las características concretas del esquema.
- El análisis no asumió resultados de ejecución: ninguno de los dos
  scripts fue ejecutado.

---

## Verificación realizada

La verificación de esta parte del TP consistió en **lectura crítica y
análisis estático** de los scripts, tal como exige la consigna de la
Parte 3.

**Ninguno de los dos scripts fue ejecutado en PostgreSQL.**

El proceso de verificación comprendió:

1. Lectura del script original y contraste con la intención declarada en
   el comentario.
2. Identificación de la diferencia entre el efecto real del script y el
   efecto esperado.
3. Análisis del comportamiento de SQL frente a los casos problemáticos
   detectados (`UPDATE` sin `WHERE`; `NOT IN` con NULLs).
4. Revisión de que la versión corregida respeta el protocolo de seguridad
   (`BEGIN` / verificación / `ROLLBACK`) y no introduce nuevos riesgos.
5. Confirmación de que no se inventaron columnas ni resultados de
   ejecución.

Esta modalidad de verificación —análisis previo a la ejecución— es
precisamente el objetivo de la Parte 3: identificar errores en scripts
antes de ejecutarlos, evitando daños que serían difíciles o imposibles
de revertir.
