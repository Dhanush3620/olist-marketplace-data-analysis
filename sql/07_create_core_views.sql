CREATE SCHEMA IF NOT EXISTS analytics;

DROP VIEW IF EXISTS analytics.v_customer_summary;
DROP VIEW IF EXISTS analytics.v_orders_enriched;
DROP VIEW IF EXISTS analytics.v_order_reviews_agg;
DROP VIEW IF EXISTS analytics.v_order_payments_agg;
DROP VIEW IF EXISTS analytics.v_order_items_agg;
DROP VIEW IF EXISTS analytics.v_order_items_enriched;
DROP VIEW IF EXISTS analytics.v_products_enriched;

-- 1. Products enriched with translated category names
CREATE OR REPLACE VIEW analytics.v_products_enriched AS
SELECT
    p.product_id,
    p.product_category_name,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown / Untranslated'
    ) AS product_category_en,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM raw.olist_products p
LEFT JOIN raw.product_category_translation t
    ON p.product_category_name = t.product_category_name;


-- 2. Order items enriched with category
CREATE OR REPLACE VIEW analytics.v_order_items_enriched AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    pe.product_category_en,
    oi.seller_id,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    ROUND((oi.price + oi.freight_value)::numeric, 2) AS item_total
FROM raw.olist_order_items oi
LEFT JOIN analytics.v_products_enriched pe
    ON oi.product_id = pe.product_id;


-- 3. Order items aggregated to order level
CREATE OR REPLACE VIEW analytics.v_order_items_agg AS
SELECT
    order_id,
    COUNT(*) AS item_count,
    COUNT(DISTINCT product_id) AS distinct_products,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    ROUND(SUM(price)::numeric, 2) AS product_revenue,
    ROUND(SUM(freight_value)::numeric, 2) AS freight_revenue,
    ROUND(SUM(item_total)::numeric, 2) AS item_total
FROM analytics.v_order_items_enriched
GROUP BY order_id;


-- 4. Payments aggregated to order level
CREATE OR REPLACE VIEW analytics.v_order_payments_agg AS
WITH payment_primary AS (
    SELECT
        order_id,
        payment_type AS primary_payment_type
    FROM (
        SELECT
            order_id,
            payment_type,
            payment_sequential,
            payment_value,
            ROW_NUMBER() OVER (
                PARTITION BY order_id
                ORDER BY payment_value DESC, payment_sequential ASC, payment_type ASC
            ) AS rn
        FROM raw.olist_order_payments
    ) x
    WHERE rn = 1
)
SELECT
    p.order_id,
    ROUND(SUM(p.payment_value)::numeric, 2) AS payment_total,
    SUM(p.payment_installments) AS total_installments,
    COUNT(*) AS payment_rows,
    COUNT(DISTINCT p.payment_type) AS distinct_payment_types,
    STRING_AGG(DISTINCT p.payment_type, ', ' ORDER BY p.payment_type) AS payment_types_used,
    pp.primary_payment_type
FROM raw.olist_order_payments p
LEFT JOIN payment_primary pp
    ON p.order_id = pp.order_id
GROUP BY p.order_id, pp.primary_payment_type;


-- 5. Reviews aggregated to order level
CREATE OR REPLACE VIEW analytics.v_order_reviews_agg AS
SELECT
    order_id,
    COUNT(*) AS review_rows,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    MIN(review_score) AS min_review_score,
    MAX(review_score) AS max_review_score,
    MAX(review_creation_date) AS latest_review_creation_date
FROM raw.olist_order_reviews
GROUP BY order_id;


-- 6. Orders enriched: this is the main order-level analytics view
CREATE OR REPLACE VIEW analytics.v_orders_enriched AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_purchase_timestamp::date AS purchase_date,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS purchase_month_start,
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS purchase_year_month,
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::int AS purchase_year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp)::int AS purchase_month_num,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    ia.item_count,
    ia.distinct_products,
    ia.distinct_sellers,
    ia.product_revenue,
    ia.freight_revenue,
    ia.item_total,

    pa.payment_total,
    pa.total_installments,
    pa.payment_rows,
    pa.distinct_payment_types,
    pa.payment_types_used,
    pa.primary_payment_type,

    ra.review_rows,
    ra.avg_review_score,
    ra.min_review_score,
    ra.max_review_score,

    COALESCE(pa.payment_total, ia.item_total, 0) AS order_value_proxy,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN ROUND(
            (EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0)::numeric,
            2
        )
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN ROUND(
            (EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0)::numeric,
            2
        )
        ELSE NULL
    END AS days_from_estimated_delivery,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS late_delivery_flag,

    CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END AS delivered_flag,
    CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END AS canceled_flag
FROM raw.olist_orders o
LEFT JOIN raw.olist_customers c
    ON o.customer_id = c.customer_id
LEFT JOIN analytics.v_order_items_agg ia
    ON o.order_id = ia.order_id
LEFT JOIN analytics.v_order_payments_agg pa
    ON o.order_id = pa.order_id
LEFT JOIN analytics.v_order_reviews_agg ra
    ON o.order_id = ra.order_id;


-- 7. Customer summary view
CREATE OR REPLACE VIEW analytics.v_customer_summary AS
SELECT
    customer_unique_id,
    MIN(purchase_date) AS first_purchase_date,
    MAX(purchase_date) AS last_purchase_date,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
    ROUND(SUM(
        CASE
            WHEN order_status = 'delivered' THEN COALESCE(order_value_proxy, 0)
            ELSE 0
        END
    )::numeric, 2) AS lifetime_value_delivered,
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
    CASE
        WHEN COUNT(DISTINCT order_id) > 1 THEN 1
        ELSE 0
    END AS repeat_customer_flag
FROM analytics.v_orders_enriched
GROUP BY customer_unique_id;