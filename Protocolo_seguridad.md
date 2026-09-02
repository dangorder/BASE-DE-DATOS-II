\# Protocolo de Seguridad — Base de Datos II



\## Entorno



Motor de base de datos: PostgreSQL.



Cliente utilizado: DBeaver.



La base de datos de trabajo será una copia local destinada exclusivamente

a las prácticas del Trabajo Práctico. No se trabajará sobre bases de datos

reales ni sobre datos de terceros.



\## 1. Copia



Antes de realizar modificaciones sobre la base de datos, se trabajará

sobre una copia de desarrollo denominada `copia\_trabajo`.



La copia se utilizará exclusivamente para las pruebas y ejercicios del

Trabajo Práctico, evitando realizar cambios directamente sobre una base

que contenga datos importantes.



La copia se podrá crear mediante PostgreSQL utilizando `createdb` y una

base plantilla o mediante las herramientas de administración disponibles

en el entorno local.



\## 2. Transacción



Todo script que realice modificaciones sobre los datos será probado

primero dentro de una transacción.



El procedimiento será:



```sql

BEGIN;



\-- operaciones a probar



ROLLBACK;

