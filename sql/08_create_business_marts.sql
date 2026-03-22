DROP VIEW IF EXISTS analytics.v_category_performance;
DROP VIEW IF EXISTS analytics.v_seller_performance;
DROP VIEW IF EXISTS analytics.v_state_performance;

-- 1. Category performance mart
CREATE OR REPLACE VIEW analytics.v_category_performance AS
WITH category_order_values AS (
    SELECT
        oi.order_id,
        oi.product_category_en,
        COUNT(*) AS item_rows,
        COUNT(DISTINCT oi.product_id) AS distinct_products,
        COUNT(DISTINCT oi.seller_id) AS distinct_sellers,
        ROUND(SUM(oi.price)::numeric, 2) AS product_revenue,
        ROUND(SUM(oi.freight_value)::numeric, 2) AS freight_revenue,
        ROUND(SUM(oi.item_total)::numeric, 2) AS gross_item_value
    FROM analytics.v_order_items_enriched oi
    GROUP BY oi.order_id, oi.product_category_en
)
SELECT
    o.purchase_month_start,
    o.purchase_year_month,
    cov.product_category_en,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT o.customer_unique_id) AS unique_customers,
    SUM(cov.item_rows) AS item_rows,
    ROUND(SUM(cov.product_revenue)::numeric, 2) AS product_revenue,
    ROUND(SUM(cov.freight_revenue)::numeric, 2) AS freight_revenue,
    ROUND(SUM(cov.gross_item_value)::numeric, 2) AS gross_item_value,
    ROUND(AVG(o.avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(o.delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(o.late_delivery_flag::numeric), 4) AS late_delivery_rate
FROM category_order_values cov
JOIN analytics.v_orders_enriched o
    ON cov.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    o.purchase_month_start,
    o.purchase_year_month,
    cov.product_category_en;


-- 2. Seller performance mart
CREATE OR REPLACE VIEW analytics.v_seller_performance AS
WITH seller_order_values AS (
    SELECT
        oi.order_id,
        oi.seller_id,
        COUNT(*) AS item_rows,
        COUNT(DISTINCT oi.product_id) AS distinct_products,
        ROUND(SUM(oi.price)::numeric, 2) AS product_revenue,
        ROUND(SUM(oi.freight_value)::numeric, 2) AS freight_revenue,
        ROUND(SUM(oi.item_total)::numeric, 2) AS gross_item_value
    FROM analytics.v_order_items_enriched oi
    GROUP BY oi.order_id, oi.seller_id
)
SELECT
    o.purchase_month_start,
    o.purchase_year_month,
    sov.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT o.customer_unique_id) AS unique_customers,
    SUM(sov.item_rows) AS item_rows,
    ROUND(SUM(sov.product_revenue)::numeric, 2) AS product_revenue,
    ROUND(SUM(sov.freight_revenue)::numeric, 2) AS freight_revenue,
    ROUND(SUM(sov.gross_item_value)::numeric, 2) AS gross_item_value,
    ROUND(AVG(o.avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(o.delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(o.late_delivery_flag::numeric), 4) AS late_delivery_rate
FROM seller_order_values sov
JOIN analytics.v_orders_enriched o
    ON sov.order_id = o.order_id
LEFT JOIN raw.olist_sellers s
    ON sov.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY
    o.purchase_month_start,
    o.purchase_year_month,
    sov.seller_id,
    s.seller_state;


-- 3. State performance mart
CREATE OR REPLACE VIEW analytics.v_state_performance AS
SELECT
    purchase_month_start,
    purchase_year_month,
    customer_state,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
    COUNT(DISTINCT customer_unique_id) FILTER (WHERE order_status = 'delivered') AS unique_customers,
    ROUND(SUM(
        CASE
            WHEN order_status = 'delivered' THEN COALESCE(order_value_proxy, 0)
            ELSE 0
        END
    )::numeric, 2) AS delivered_gpv,
    ROUND(SUM(
        CASE
            WHEN order_status = 'delivered' THEN COALESCE(product_revenue, 0)
            ELSE 0
        END
    )::numeric, 2) AS product_revenue,
    ROUND(AVG(
        CASE
            WHEN order_status = 'delivered' THEN avg_review_score
            ELSE NULL
        END
    )::numeric, 2) AS avg_review_score,
    ROUND(AVG(
        CASE
            WHEN order_status = 'delivered' THEN delivery_days
            ELSE NULL
        END
    )::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(
        CASE
            WHEN order_status = 'delivered' THEN late_delivery_flag::numeric
            ELSE NULL
        END
    ), 4) AS late_delivery_rate
FROM analytics.v_orders_enriched
GROUP BY
    purchase_month_start,
    purchase_year_month,
    customer_state;