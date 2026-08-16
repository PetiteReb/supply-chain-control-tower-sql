/* =============================================================================
   Warehouse dimensions
   Purpose : star schema design - descriptive context around the fact table
   Author  : Rebecca Olivier
   -----------------------------------------------------------------------------
   This file is idempotent: it drops and rebuilds the whole warehouse schema,
   so it can be re-run at will while the model is still evolving.
   WARNING: from milestone 2c onwards, re-running it wipes the loaded data.
   ============================================================================= */

DROP SCHEMA IF EXISTS warehouse CASCADE;
CREATE SCHEMA warehouse;


-- =============================================================================
-- dim_shipping_mode
-- =============================================================================
-- Grain: one row per shipping mode.
CREATE TABLE warehouse.dim_shipping_mode (
    shipping_mode_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- surrogate key
    shipping_mode     TEXT NOT NULL UNIQUE                               -- natural key
);


-- =============================================================================
-- dim_customer
-- =============================================================================
-- Grain: one row per customer.
--
-- PII deliberately excluded: customer_email, customer_password and
-- customer_street answer no business question here and carry a real breach
-- risk. GDPR data minimisation applies. City is the finest geographic level
-- that stays interpretable for analysis.
--
-- First and last name kept separate: they can always be concatenated later,
-- but splitting a merged name is painful. It also lets us group households
-- (e.g. Amelie Roger and Alex Roger).
--
-- NO NULLS POLICY: every attribute is NOT NULL. Missing source values are
-- replaced by 'Unknown' at load time (see sql/02_transform/). A NULL would
-- silently drop out of filters and GROUP BY; an 'Unknown' row stays visible,
-- countable and fixable. Source completeness measured at 0.006% missing
-- (8 rows without last name, 3 without zipcode, out of 180,519).
CREATE TABLE warehouse.dim_customer (
    customer_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- surrogate key
    customer_id  INTEGER NOT NULL UNIQUE,                           -- natural key
    first_name   TEXT    NOT NULL,
    last_name    TEXT    NOT NULL,
    segment      TEXT    NOT NULL,   -- Consumer / Corporate / Home Office
    city         TEXT    NOT NULL,
    state        TEXT    NOT NULL,
    country      TEXT    NOT NULL,
    zipcode      TEXT    NOT NULL    -- TEXT, not INTEGER: leading zeros matter
);


-- =============================================================================
-- dim_product
-- =============================================================================
-- Grain: one row per product.
--
-- STAR, not snowflake: the category > department hierarchy is flattened here
-- rather than split into dim_category / dim_department. Storage redundancy is
-- cheap; joins at query time are not. It also gives BI tools a hierarchy they
-- can drill through natively.
--
-- "department" is a MERCHANDISING department (Apparel, Fitness, Golf...), not a
-- geographic one - verified against the source values. It therefore belongs to
-- the product hierarchy, not to dim_geography.
--
-- product_card_id and order_item_cardprod_id are identical in the source, so
-- only one is kept as the natural key.
--
-- list_price is the CATALOGUE price. The price actually charged lives on the
-- fact table; the two differ whenever a promotion applies.
CREATE TABLE warehouse.dim_product (
    product_key     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- surrogate key
    product_card_id INTEGER NOT NULL UNIQUE,                           -- natural key
    product_name    TEXT    NOT NULL,
    list_price      NUMERIC(12,2) NOT NULL CHECK (list_price >= 0),
    category_id     INTEGER NOT NULL,
    category_name   TEXT    NOT NULL,
    department_id   INTEGER NOT NULL,
    department_name TEXT    NOT NULL
);


-- =============================================================================
-- dim_geography
-- =============================================================================
-- Grain: one row per distinct shipping destination.
-- Hierarchy: market > region > country > state > city.
--
-- These columns describe where the ORDER ships, not where the customer lives:
-- a customer can order into several markets. That is why they live here and
-- not in dim_customer.
--
-- The source provides NO natural key for a destination. Uniqueness is enforced
-- by a composite UNIQUE constraint over the five columns. City alone would not
-- be enough (Paris, France vs Paris, Texas).
--
-- NO NULLS POLICY: PostgreSQL treats two NULLs as distinct inside a UNIQUE
-- constraint, so a NULL state would produce one duplicate row per order line
-- instead of one row per destination. Missing values become 'Unknown' at load
-- time (see sql/02_transform/).
CREATE TABLE warehouse.dim_geography (
    geography_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- surrogate key
    market        TEXT NOT NULL,
    region        TEXT NOT NULL,
    country       TEXT NOT NULL,
    state         TEXT NOT NULL,
    city          TEXT NOT NULL,
    -- Composite natural key: table-level syntax, used when no single column
    -- identifies a row.
    CONSTRAINT dim_geography_uk UNIQUE (market, region, country, state, city)
);

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'warehouse'
ORDER BY table_name;