-- ============================================================
-- FILE: sql_server/01_create_tables.sql
-- PURPOSE: Create source schema in SQL Server (RetailDB)
-- Run this first before seeding data
-- ============================================================

-- Create database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RetailDB')
    CREATE DATABASE RetailDB;
GO

USE RetailDB;
GO

-- ── customers ────────────────────────────────────────────────
IF OBJECT_ID('dbo.customers', 'U') IS NOT NULL DROP TABLE dbo.customers;
CREATE TABLE dbo.customers (
    customer_id   INT           PRIMARY KEY,
    first_name    NVARCHAR(50)  NOT NULL,
    last_name     NVARCHAR(50)  NOT NULL,
    email         NVARCHAR(100) NOT NULL UNIQUE,
    age           TINYINT,
    gender        CHAR(1)       CHECK (gender IN ('M','F')),
    city          NVARCHAR(100),
    country       NVARCHAR(50)  NOT NULL DEFAULT 'India',
    created_at    DATETIME2     NOT NULL
);

-- ── products ─────────────────────────────────────────────────
IF OBJECT_ID('dbo.products', 'U') IS NOT NULL DROP TABLE dbo.products;
CREATE TABLE dbo.products (
    product_id    INT            PRIMARY KEY,
    name          NVARCHAR(200)  NOT NULL,
    brand         NVARCHAR(100),
    category      NVARCHAR(100),
    department    NVARCHAR(50),
    cost          DECIMAL(10,2)  NOT NULL,
    retail_price  DECIMAL(10,2)  NOT NULL
);

-- ── orders ───────────────────────────────────────────────────
IF OBJECT_ID('dbo.orders', 'U') IS NOT NULL DROP TABLE dbo.orders;
CREATE TABLE dbo.orders (
    order_id      INT          PRIMARY KEY,
    customer_id   INT          NOT NULL REFERENCES dbo.customers(customer_id),
    status        NVARCHAR(20) NOT NULL,
    num_of_items  TINYINT      NOT NULL DEFAULT 1,
    created_at    DATETIME2    NOT NULL,
    shipped_at    DATETIME2    NULL,
    delivered_at  DATETIME2    NULL,
    returned_at   DATETIME2    NULL
);

-- ── order_items ──────────────────────────────────────────────
IF OBJECT_ID('dbo.order_items', 'U') IS NOT NULL DROP TABLE dbo.order_items;
CREATE TABLE dbo.order_items (
    item_id      INT           PRIMARY KEY,
    order_id     INT           NOT NULL REFERENCES dbo.orders(order_id),
    customer_id  INT           NOT NULL REFERENCES dbo.customers(customer_id),
    product_id   INT           NOT NULL REFERENCES dbo.products(product_id),
    status       NVARCHAR(20)  NOT NULL,
    sale_price   DECIMAL(10,2) NOT NULL,
    created_at   DATETIME2     NOT NULL
);

PRINT 'RetailDB schema created successfully.';
GO
