---
inclusion: always
---

# Contexto del proyecto — Food Store (Base de Datos II — UTN)

## 1. Identidad del proyecto

- **Trabajo Práctico:** Base de Datos II — UTN
- **Proyecto:** Food Store
- **Motor:** PostgreSQL 17
- **Cliente utilizado para las pruebas:** DBeaver (dos sesiones concurrentes)
- **Base de desarrollo:** `mi_proyecto_copia`
- **No existe código de aplicación ni sistema de build.** El repositorio contiene exclusivamente DDL, documentación y scripts SQL.

---

## 2. Estructura principal

### Tablas y relaciones

| Tabla | Descripción | Relaciones |
|---|---|---|
| `categoria` | Categorías de productos | — |
| `producto` | Productos del catálogo | `categoria_id → categoria(id)` (ON DELETE RESTRICT) |
| `cliente` | Clientes registrados | — |
| `pedido` | Cabecera de pedidos | `cliente_id → cliente(id)` (ON DELETE RESTRICT) |
| `detalle_pedido` | Líneas de cada pedido | `pedido_id → pedido(id)`, `producto_id → producto(id)` (ambas ON DELETE RESTRICT) |

### Tipos ENUM

- `forma_pago_enum`: `EFECTIVO`, `TARJETA`, `TRANSFERENCIA`
- `estado_pedido_enum`: `PENDIENTE`, `EN_PREPARACION`, `ENTREGADO`, `CANCELADO`

### Restricciones de integridad relevantes

- `chk_producto_precio_positivo` — `precio_lista >= 0`
- `chk_producto_stock_no_negativo` — `stock >= 0`
- `chk_producto_nombre_no_vacio` — `btrim(nombre) <> ''`
- `chk_cliente_nombre_no_vacio` — `btrim(nombre) <> ''`
- `chk_cliente_apellido_no_vacio` — `btrim(apellido) <> ''`
- `chk_cliente_email_formato` — email no vacío y con formato `texto@dominio.ext`
- `uq_cliente_email` — email único por cliente

### Convenciones del esquema

- Todos los IDs: `BIGINT GENERATED ALWAYS AS IDENTITY`
- Precios: `NUMERIC(10,2)`
- Timestamps: `TIMESTAMPTZ NOT NULL DEFAULT now()`
- El script `schema.sql` es idempotente: hace `DROP … CASCADE` antes de cada `CREATE`. Ejecutarlo destruye y recrea todas las tablas.
- Todo DDL va en `schema.sql`. No crear tablas fuera de ese archivo.
- Los drops usan `CASCADE`.

### Índices existentes

- `idx_pedido_cliente_id` sobre `pedido(cliente_id)`
- `idx_producto_categoria_activo` sobre `producto(categoria_id, activo)`

---

## 3. Protocolo de seguridad

Fuente: `Protocolo_seguridad.md`. Estas reglas son obligatorias para cualquier trabajo sobre este repositorio.

### 3.1 Copia

- **Nunca trabajar sobre la base original.**
- Toda prueba y modificación se realiza sobre `mi_proyecto_copia`.

### 3.2 Transacciones

- Todo DML o prueba que pueda modificar datos debe ejecutarse primero dentro de una transacción con `ROLLBACK`:

```sql
BEGIN;

-- operaciones a probar

ROLLBACK;
```

- `COMMIT` solo se usa cuando el cambio ha sido verificado y se decide conservarlo de forma definitiva:

```sql
BEGIN;

-- operaciones verificadas

COMMIT;
```

### 3.3 Backup

- Antes de cualquier cambio estructural o potencialmente destructivo debe existir un backup de `mi_proyecto_copia`.
- Actualmente existe `backup_mi_proyecto_copia.sql`, generado mediante `pg_dump`. Este archivo constituye una copia de respaldo de `mi_proyecto_copia`.
- Ante cualquier cambio estructural importante, generar un nuevo backup antes de proceder.

### 3.4 Autorización y revisión

- **La IA no modifica datos ni estructura sin autorización explícita del alumno.**
- La IA propone los comandos SQL; el alumno los revisa y los ejecuta manualmente en DBeaver.
- Los resultados documentados deben provenir de ejecuciones reales. No inventar ni reemplazar resultados por valores teóricos.

### 3.5 Control de versiones

- Revisar los cambios en los archivos antes de cada commit.
- Cada commit debe representar un cambio claro, verificado y con propósito definido.
- **La IA no realiza commits sin autorización explícita del alumno.**

---

## 4. Estado actual del TP

Los siguientes escenarios de concurrencia están **realizados, verificados experimentalmente y documentados** en `informe_concurrencia.md`:

1. **Lectura no repetible** — verificada con `READ COMMITTED` (cambio visible) y `REPEATABLE READ` (snapshot estable).
2. **Espera por bloqueo** — verificada con `SELECT ... FOR UPDATE` sobre `producto(id=2)`: la segunda sesión esperó hasta el `COMMIT` de la primera.
3. **Lectura fantasma** — verificada con `READ COMMITTED` (COUNT cambió de 1 a 2) y `REPEATABLE READ` (COUNT se mantuvo en 2).

Cada escenario incluye comandos reales, resultados observados, explicación técnica y revisión crítica de las explicaciones de IA.

**No inventar nuevos experimentos ni resultados. No modificar los registrados sin solicitud explícita.**

---

## 5. Uso de IA en este proyecto

- Las explicaciones generadas por IA deben contrastarse con el comportamiento real observado en PostgreSQL/DBeaver.
- Si se detectan errores o imprecisiones, deben registrarse y corregirse antes de incorporarse a cualquier documento.
- Los resultados experimentales provienen exclusivamente de las pruebas reales ejecutadas en DBeaver. La IA no simula ni reemplaza esos resultados.

---

## 6. Reglas para futuras modificaciones

- No modificar `schema.sql` sin solicitud explícita.
- No modificar datos de `mi_proyecto_copia` directamente ni proponer DML destructivo sin autorización.
- No ejecutar SQL automáticamente. La IA propone; el alumno ejecuta.
- No modificar documentación ya verificada (`informe_concurrencia.md`, `especificacion_reglas_negocio.md`, `Protocolo_seguridad.md`) salvo solicitud explícita.
- No realizar commits automáticamente.
