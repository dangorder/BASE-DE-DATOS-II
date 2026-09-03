# Protocolo de Seguridad — Base de Datos II

## Entorno

Motor de base de datos: PostgreSQL.

Cliente utilizado: DBeaver.

La base de datos de trabajo será una copia local destinada exclusivamente
a las prácticas del Trabajo Práctico. No se trabajará sobre bases de datos
reales ni sobre datos de terceros.

## 1. Copia

Antes de realizar modificaciones sobre la base de datos, se trabajará
sobre una copia de desarrollo. En este Trabajo Práctico la base de
desarrollo utilizada es `mi_proyecto_copia`.

La copia se utilizará exclusivamente para las pruebas y ejercicios del
Trabajo Práctico, evitando realizar cambios directamente sobre una base
que contenga datos importantes.

La copia se podrá crear mediante PostgreSQL utilizando `createdb` y una
base plantilla o mediante las herramientas de administración disponibles
en el entorno local.

## 2. Transacción

Todo script que realice modificaciones sobre los datos será probado
primero dentro de una transacción.

El procedimiento será:

```sql
BEGIN;

-- operaciones a probar

ROLLBACK;
```

Una vez verificado el resultado, si el cambio debe conservarse:

```sql
BEGIN;

-- operaciones verificadas

COMMIT;
```

`COMMIT` solo se utiliza cuando el cambio ha sido revisado y se decide
conservarlo de forma definitiva.

## 3. Backup

Antes de realizar cambios estructurales o potencialmente destructivos
debe existir un backup de la base de desarrollo.

Actualmente existe el archivo `backup_mi_proyecto_copia.sql`, generado
mediante `pg_dump`. Este archivo constituye una copia de respaldo de
`mi_proyecto_copia` generada mediante `pg_dump`.

El backup debe permitir restaurar el estado anterior en caso de error.
Ante cualquier cambio estructural importante, se debe generar un nuevo
backup antes de proceder.

## 4. Autorización y revisión

La IA no debe modificar datos ni estructura de la base de datos sin
autorización explícita del alumno.

La IA debe proponer los comandos SQL; el alumno los revisa y los ejecuta
manualmente en DBeaver.

Los resultados reales observados en PostgreSQL no deben ser inventados
ni reemplazados por resultados teóricos generados por la IA. Todo
resultado documentado debe provenir de una ejecución real.

## 5. Control de versiones

Los cambios realizados en los archivos del proyecto deben revisarse
antes de cada commit.

Se utiliza Git para registrar el avance del Trabajo Práctico. Cada
commit debe representar un cambio claro, verificado y con propósito
definido.

La IA no debe realizar commits sin autorización explícita del alumno.

## 6. Uso de IA

Las explicaciones y respuestas generadas por la IA deben contrastarse
con el comportamiento real observado en PostgreSQL.

Si se detectan errores o imprecisiones en una explicación de IA, deben
registrarse y corregirse antes de incorporarse a cualquier documento
del TP.

La IA funciona como herramienta de apoyo y análisis. Los resultados
experimentales deben provenir siempre de las pruebas reales realizadas
sobre la base de desarrollo.
