/* =============================================================================
   Profiling of staging.raw_orders
   Purpose : understand the raw data before designing the star schema
   Author  : Rebecca Olivier
   ============================================================================= */

-- Total row count. The load target was ~180k lines from the DataCo extract.
SELECT count(*) FROM staging.raw_orders;


-- Column inventory: names, types and physical order.
-- Everything is TEXT on purpose — casting happens in the transform layer.
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name   = 'raw_orders'
ORDER BY ordinal_position;


-- Cardinality of the three future dimension keys.
-- The gap between count(*) above and nb_unique_orders proves the grain:
-- one row = one ORDER LINE, not one order.
SELECT
    count(DISTINCT order_id)               AS nb_unique_orders,
    count(DISTINCT customer_id)            AS nb_unique_customers,
    count(DISTINCT order_item_cardprod_id) AS nb_unique_products
FROM staging.raw_orders;


-- Shipping modes: volume per service level.
-- Two measures side by side on purpose — line items vs actual orders —
-- to keep the "grain" distinction visible.
SELECT
    shipping_mode,
    count(*)                 AS nb_order_lines,
    count(DISTINCT order_id) AS nb_orders
FROM staging.raw_orders
GROUP BY shipping_mode
ORDER BY nb_order_lines DESC;


-- Customers per market x segment.
-- NOTE: market describes the ORDER destination, not the customer. A customer
-- can appear under several markets, so these counts do NOT sum to the total
-- customer base. => market belongs to a geography dimension on the fact table,
-- never to dim_customer.
SELECT
    market,
    customer_segment,
    count(DISTINCT customer_id) AS nb_unique_customers
FROM staging.raw_orders
GROUP BY market, customer_segment
ORDER BY nb_unique_customers DESC;