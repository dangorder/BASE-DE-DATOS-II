# DUIA — Parte 1: Integridad de Datos

**Trabajo Práctico:** Base de Datos II — UTN
**Proyecto:** Food Store
**Base de datos de pruebas:** `mi_proyecto_copia`
**Cliente:** DBeaver
**Motor:** PostgreSQL

---

## Herramienta utilizada

**OpenCode** (IA de asistencia para generación de código y documentación).

---

## Spec o prompt utilizado

El prompt original utilizado con OpenCode no está registrado en el repositorio.
Lo que sí está verificado en el historial Git es el resultado producido:

- Commit `492fc9a` (03/09/2026 17:26) — creación de
  `especificacion_reglas_negocio.md` con las tres reglas de negocio
  documentadas.
- Commit `e1c3e10` (03/09/2026 17:32) — modificación de `schema.sql`
  con las constraints de integridad correspondientes.

El orden de los commits confirma que la especificación fue redactada antes
de modificar el schema.

---

## Qué generó la IA

### `especificacion_reglas_negocio.md`

Documento con tres reglas de negocio:

1. **Regla 1 — Nombre de producto:** el campo `producto.nombre` no puede
   ser vacío ni contener únicamente espacios en blanco.

2. **Regla 2 — Nombre y apellido de cliente:** los campos `cliente.nombre`
   y `cliente.apellido` no pueden ser vacíos ni contener únicamente
   espacios en blanco.

3. **Regla 3 — Formato básico de email:** el campo `cliente.email` no
   puede ser vacío, no puede contener únicamente espacios, y debe tener
   estructura básica de email (texto antes del `@`, dominio después,
   punto dentro del dominio).

Cada regla incluye tabla afectada, campo afectado, comportamiento
esperado, ejemplos válidos y ejemplos inválidos.

### Constraints agregadas en `schema.sql`

```sql
-- En tabla producto:
CONSTRAINT chk_producto_nombre_no_vacio CHECK (btrim(nombre) <> '')

-- En tabla cliente:
CONSTRAINT chk_cliente_nombre_no_vacio   CHECK (btrim(nombre) <> ''),
CONSTRAINT chk_cliente_apellido_no_vacio CHECK (btrim(apellido) <> ''),
CONSTRAINT chk_cliente_email_formato CHECK (
    btrim(email) <> '' AND email ~* '^[^@]+@[^@]+\.[^.]+$'
)
```

---

## Qué se aceptó

Se aceptaron las cuatro constraints tal como fueron generadas:

- La implementación mediante `btrim()` para rechazo de vacíos y cadenas
  de solo espacios es correcta para los tres campos de texto.
- El patrón regex `'^[^@]+@[^@]+\.[^.]+$'` con operador `~*`
  (case-insensitive) cubre todos los casos inválidos definidos en la
  especificación y acepta los ejemplos válidos documentados.
- El operador `~*` es propio de PostgreSQL y adecuado para este motor.

---

## Qué se modificó o descartó, y por qué

No hay evidencia en el repositorio de modificaciones o descartes aplicados
sobre el output generado por la IA antes de los commits. El diff del
commit `e1c3e10` muestra que las constraints fueron incorporadas
directamente.

---

## Verificación realizada

Las siguientes pruebas fueron ejecutadas manualmente en DBeaver sobre
`mi_proyecto_copia`, siguiendo el protocolo de seguridad
(`BEGIN` / verificación / `ROLLBACK`).

### Prueba 1 — `producto.nombre` inválido

| Campo                 | Valor                                          |
|-----------------------|------------------------------------------------|
| Valor probado         | `'   '` (solo espacios)                        |
| Resultado             | PostgreSQL rechazó el INSERT con error `23514` |
| Constraint activada   | `chk_producto_nombre_no_vacio`                 |
| Cierre de transacción | `ROLLBACK` ejecutado                           |

### Prueba 2 — `producto.nombre` válido

| Campo                 | Valor                 |
|-----------------------|-----------------------|
| Valor probado         | `'Producto válido'`   |
| Resultado             | INSERT aceptado       |
| Cierre de transacción | `ROLLBACK` ejecutado  |

### Prueba 3 — `cliente.nombre` inválido

| Campo                 | Valor                         |
|-----------------------|-------------------------------|
| Valor probado         | `'   '` (solo espacios)       |
| Resultado             | PostgreSQL rechazó el INSERT  |
| Constraint activada   | `chk_cliente_nombre_no_vacio` |
| Cierre de transacción | `ROLLBACK` ejecutado          |

### Prueba 4 — `cliente.apellido` inválido

| Campo                 | Valor                            |
|-----------------------|----------------------------------|
| Valor probado         | `'   '` (solo espacios)          |
| Resultado             | PostgreSQL rechazó el INSERT     |
| Constraint activada   | `chk_cliente_apellido_no_vacio`  |
| Cierre de transacción | `ROLLBACK` ejecutado             |

### Prueba 5 — Cliente completo válido

| Campo                 | Valor                          |
|-----------------------|--------------------------------|
| `nombre`              | `'Juan'`                       |
| `apellido`            | `'Pérez'`                      |
| `email`               | `'prueba.cliente@gmail.com'`   |
| Resultado             | INSERT aceptado                |
| Cierre de transacción | `ROLLBACK` ejecutado           |

### Prueba 6 — `cliente.email` inválido

| Campo                 | Valor                                  |
|-----------------------|----------------------------------------|
| Valor probado         | `'ana@gmail'` (sin punto en dominio)   |
| Resultado             | PostgreSQL rechazó el INSERT           |
| Constraint activada   | `chk_cliente_email_formato`            |
| Cierre de transacción | `ROLLBACK` ejecutado                   |

### Prueba 7 — `cliente.email` válido

| Campo                 | Valor              |
|-----------------------|--------------------|
| Valor probado         | `'ana@gmail.com'`  |
| Resultado             | INSERT aceptado    |
| Cierre de transacción | `ROLLBACK` ejecutado |

### Cobertura de verificación

| Constraint                      | Caso inválido probado | Caso válido probado      |
|---------------------------------|-----------------------|--------------------------|
| `chk_producto_nombre_no_vacio`  | ✅ Prueba 1           | ✅ Prueba 2              |
| `chk_cliente_nombre_no_vacio`   | ✅ Prueba 3           | ✅ Prueba 5 (implícito)  |
| `chk_cliente_apellido_no_vacio` | ✅ Prueba 4           | ✅ Prueba 5 (implícito)  |
| `chk_cliente_email_formato`     | ✅ Prueba 6           | ✅ Prueba 7              |
