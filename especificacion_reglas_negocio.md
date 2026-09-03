\# Especificación de Reglas de Negocio



\## Regla 1 — Nombre de producto



\### Descripción

El nombre de un producto no puede estar vacío ni contener únicamente espacios en blanco.



\### Tabla afectada

`producto`



\### Campo afectado

`nombre`



\### Comportamiento esperado



Debe rechazarse cualquier valor que:



\- sea una cadena vacía;

\- contenga únicamente espacios en blanco.



Debe aceptarse un nombre que contenga al menos un carácter no perteneciente a espacios en blanco.



\### Ejemplos válidos



\- `Hamburguesa`

\- `Papas Fritas`

\- `Coca Cola`



\### Ejemplos inválidos



\- `''`

\- `'     '`



\---



\## Regla 2 — Nombre y apellido del cliente



\### Descripción

El nombre y el apellido de un cliente no pueden estar vacíos ni contener únicamente espacios en blanco.



\### Tabla afectada

`cliente`



\### Campos afectados

\- `nombre`

\- `apellido`



\### Comportamiento esperado



Debe rechazarse cualquier valor de `nombre` o `apellido` que:



\- sea una cadena vacía;

\- contenga únicamente espacios en blanco.



Debe aceptarse cualquier valor que contenga al menos un carácter no perteneciente a espacios en blanco.



\### Ejemplos válidos



\- `Juan`

\- `Nicolás`

\- `García`



\### Ejemplos inválidos



\- `''`

\- `'     '`



\---



\## Regla 3 — Formato básico del email



\### Descripción

El email de un cliente debe tener un formato básico válido y no puede estar vacío ni contener únicamente espacios en blanco.



\### Tabla afectada

`cliente`



\### Campo afectado

`email`



\### Comportamiento esperado



Debe rechazarse cualquier valor que:



\- sea una cadena vacía;

\- contenga únicamente espacios en blanco;

\- no contenga una estructura básica de email válida.



Debe aceptarse un email que tenga como mínimo:



\- texto antes del `@`;

\- un `@`;

\- un dominio después del `@`;

\- un punto dentro del dominio.



\### Ejemplos válidos



\- `juan@gmail.com`

\- `cliente@hotmail.com`



\### Ejemplos inválidos



\- `''`

\- `'     '`

\- `juan@`

\- `@gmail.com`

\- `juan@gmail`

