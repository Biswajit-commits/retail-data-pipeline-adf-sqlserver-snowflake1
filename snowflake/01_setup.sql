-- ============================================================
-- FILE: snowflake/01_setup.sql
-- PURPOSE: One-time setup — warehouse, database, roles, schemas,
--          and RAW layer table definitions
-- Run as ACCOUNTADMIN or a role with CREATE privileges
-- ============================================================

-- ── Warehouse ────────────────────────────────────────────────
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    COMMENT        = 'Retail ETL pipeline compute';

-- ── Database & Schemas ───────────────────────────────────────
CREATE DATABASE IF NOT EXISTS RETAIL_DW;
USE DATABASE RETAIL_DW;

CREATE SCHEMA IF NOT EXISTS RAW       COMMENT = 'Direct copy from SQL Server — no transformations';
CREATE SCHEMA IF NOT EXISTS TRANSFORM COMMENT = 'Cleaned, validated, business-rule-applied tables';
CREATE SCHEMA IF NOT EXISTS REPORTING COMMENT = 'Aggregated metrics ready for BI tools';

USE WAREHOUSE COMPUTE_WH;

-- ════════════════════════════════════════════════════════════
-- RAW LAYER — mirrors SQL Server schema 1-to-1
-- ADF Copy Activity writes directly into these tables
-- ════════════════════════════════════════════════════════════
USE SCHEMA RAW;

CREATE OR REPLACE TABLE RAW.customers (
    customer_id   NUMBER        NOT NULL,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    email         VARCHAR(100),
    age           NUMBER(3),
    gender        CHAR(1),
    city          VARCHAR(100),
    country       VARCHAR(50),
    created_at    TIMESTAMP_NTZ,
    _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()   -- pipeline audit column
);

CREATE OR REPLACE TABLE RAW.products (
    product_id    NUMBER        NOT NULL,
    name          VARCHAR(200),
    brand         VARCHAR(100),
    category      VARCHAR(100),
    department    VARCHAR(50),
    cost          NUMBER(10,2),
    retail_price  NUMBER(10,2),
    _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE RAW.orders (
    order_id      NUMBER        NOT NULL,
    customer_id   NUMBER        NOT NULL,
    status        VARCHAR(20),
    num_of_items  NUMBER(3),
    created_at    TIMESTAMP_NTZ,
    shipped_at    TIMESTAMP_NTZ,
    delivered_at  TIMESTAMP_NTZ,
    returned_at   TIMESTAMP_NTZ,
    _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE RAW.order_items (
    item_id       NUMBER        NOT NULL,
    order_id      NUMBER        NOT NULL,
    customer_id   NUMBER        NOT NULL,
    product_id    NUMBER        NOT NULL,
    status        VARCHAR(20),
    sale_price    NUMBER(10,2),
    created_at    TIMESTAMP_NTZ,
    _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Pipeline audit log (populated by validate.py)
CREATE OR REPLACE TABLE RAW.pipeline_run_log (
    run_id        VARCHAR(36)   DEFAULT UUID_STRING(),
    table_name    VARCHAR(100),
    check_name    VARCHAR(200),
    status        VARCHAR(10),  -- PASS / FAIL
    detail        VARCHAR(500),
    checked_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

PRINT 'RAW schema ready.';
