# AGENTS.md

## What this repo is

University project for "Base de Datos II" (UTN). A PostgreSQL database schema for a "Food Store" application — no application code, no build system.

## Key files

- `schema.sql` — DDL script (PostgreSQL). Creates tables: `categoria`, `producto`, `cliente`, `pedido`, `detalle_pedido` with enum types, constraints, and indexes. **Drops and recreates all tables on each run** (idempotent).
- `Protocolo_seguridad.md` — Working protocol: always test modifications inside a transaction with `ROLLBACK` before committing; work on a `copia_trabajo` copy database.

## Database conventions

- Engine: **PostgreSQL** (uses `GENERATED ALWAYS AS IDENTITY`, `TIMESTAMPTZ`, enum types).
- Client: **DBeaver**.
- All DDL goes through `schema.sql`. Do not create tables outside this file.
- Before writing any DML/DDL, wrap in `BEGIN; ... ROLLBACK;` per the security protocol.
- The schema uses `BIGINT` for all IDs, `NUMERIC(10,2)` for prices, and `CASCADE` drops.

## Workflow

1. Apply schema: run `schema.sql` against a local PostgreSQL instance (or `copia_trabajo` database).
2. Any data modifications must be tested inside a transaction (`BEGIN` / `ROLLBACK`).
3. There are no tests, linters, CI, or build steps in this repo.
