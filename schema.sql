-- =============================================================================
-- TRABAJO PRÁCTICO N.º 1 - PROYECTO INTEGRADOR: FOOD STORE
-- Cátedra: Base de Datos I - UTN
-- Script DDL de creación de estructura (PostgreSQL)
-- Archivo: schema.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. ELIMINACIÓN PREVIA DE TABLAS Y TIPOS
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS detalle_pedido CASCADE;
DROP TABLE IF EXISTS pedido CASCADE;
DROP TABLE IF EXISTS producto CASCADE;
DROP TABLE IF EXISTS categoria CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;

DROP TYPE IF EXISTS forma_pago_enum CASCADE;
DROP TYPE IF EXISTS estado_pedido_enum CASCADE;

-- -----------------------------------------------------------------------------
-- 1. TIPOS ENUMERADOS
-- -----------------------------------------------------------------------------
CREATE TYPE forma_pago_enum AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA');
CREATE TYPE estado_pedido_enum AS ENUM ('PENDIENTE', 'EN_PREPARACION', 'ENTREGADO', 'CANCELADO');

-- -----------------------------------------------------------------------------
-- 2. CREACIÓN DE TABLAS
-- -----------------------------------------------------------------------------

-- Tabla: CATEGORIA
CREATE TABLE categoria (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tabla: PRODUCTO
CREATE TABLE producto (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria_id BIGINT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio_lista NUMERIC(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT fk_producto_categoria 
        FOREIGN KEY (categoria_id) 
        REFERENCES categoria (id) 
        ON DELETE RESTRICT,
        
    CONSTRAINT chk_producto_precio_positivo CHECK (precio_lista >= 0),
    CONSTRAINT chk_producto_stock_no_negativo CHECK (stock >= 0),
    CONSTRAINT chk_producto_nombre_no_vacio CHECK (btrim(nombre) <> '')
);

-- Tabla: CLIENTE
CREATE TABLE cliente (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellido VARCHAR(80) NOT NULL,
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(30),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT uq_cliente_email UNIQUE (email),
    CONSTRAINT chk_cliente_nombre_no_vacio CHECK (btrim(nombre) <> ''),
    CONSTRAINT chk_cliente_apellido_no_vacio CHECK (btrim(apellido) <> ''),
    CONSTRAINT chk_cliente_email_formato CHECK (
        btrim(email) <> '' AND email ~* '^[^@]+@[^@]+\.[^.]+$'
    )
);

-- Tabla: PEDIDO
CREATE TABLE pedido (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT now(),
    forma_pago forma_pago_enum NOT NULL,
    estado estado_pedido_enum NOT NULL DEFAULT 'PENDIENTE',
    
    CONSTRAINT fk_pedido_cliente 
        FOREIGN KEY (cliente_id) 
        REFERENCES cliente (id) 
        ON DELETE RESTRICT
);

-- Tabla: DETALLE_PEDIDO
CREATE TABLE detalle_pedido (
    pedido_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario NUMERIC(10, 2) NOT NULL,
    
    CONSTRAINT pk_detalle_pedido PRIMARY KEY (pedido_id, producto_id),
    
    CONSTRAINT fk_detalle_pedido 
        FOREIGN KEY (pedido_id) 
        REFERENCES pedido (id) 
        ON DELETE RESTRICT,
        
    CONSTRAINT fk_detalle_producto 
        FOREIGN KEY (producto_id) 
        REFERENCES producto (id) 
        ON DELETE RESTRICT,
        
    CONSTRAINT chk_detalle_cantidad_positiva CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_precio_no_negativo CHECK (precio_unitario >= 0)
);

-- -----------------------------------------------------------------------------
-- 3. ÍNDICES DE RENDIMIENTO
-- -----------------------------------------------------------------------------
CREATE INDEX idx_pedido_cliente_id ON pedido (cliente_id);
CREATE INDEX idx_producto_categoria_activo ON producto (categoria_id, activo);