-- =========================================================
-- PHASE 3: DATA QUALITY CHECKS
-- Olist Marketplace Analysis
-- =========================================================

-- ---------------------------------------------------------
-- 1. BASIC ROW COUNTS
-- ---------------------------------------------------------
SELECT 'olist_orders' AS table_name, COUNT(*) AS row_count FROM raw.olist_orders
UNION ALL
SELECT 'olist_order_items', COUNT(*) FROM raw.olist_order_items
UNION ALL
SELECT 'olist_order_payments', COUNT(*) FROM raw.olist_order_payments
UNION ALL
SELECT 'olist_order_reviews', COUNT(*) FROM raw.olist_order_reviews
UNION ALL
SELECT 'olist_customers', COUNT(*) FROM raw.olist_customers
UNION ALL
SELECT 'olist_products', COUNT(*) FROM raw.olist_products
UNION ALL
SELECT 'olist_sellers', COUNT(*) FROM raw.olist_sellers
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM raw.product_category_translation
UNION ALL
SELECT 'olist_geolocation', COUNT(*) FROM raw.olist_geolocation
ORDER BY table_name;


-- ---------------------------------------------------------
-- 2. NULL CHECKS FOR IMPORTANT COLUMNS
-- ---------------------------------------------------------

-- Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_ts,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_delivered_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered_customer_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_delivery_date
FROM raw.olist_orders;

-- Order items
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS null_order_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS null_shipping_limit_date,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight_value
FROM raw.olist_order_items;

-- Customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_customer_unique_id
FROM raw.olist_customers;

-- Payments
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value
FROM raw.olist_order_payments;

-- Reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS null_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS null_review_score,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS null_review_comment_title,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS null_review_comment_message
FROM raw.olist_order_reviews;

-- Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_product_category_name,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS null_product_name_lenght,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS null_product_description_lenght,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS null_product_photos_qty,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_product_weight_g,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_product_length_cm,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_product_height_cm,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_product_width_cm
FROM raw.olist_products;


-- ---------------------------------------------------------
-- 3. DUPLICATE CHECKS
-- ---------------------------------------------------------

-- Orders: order_id should be unique
SELECT order_id, COUNT(*)
FROM raw.olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Customers: customer_id should be unique
SELECT customer_id, COUNT(*)
FROM raw.olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Sellers: seller_id should be unique
SELECT seller_id, COUNT(*)
FROM raw.olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Products: product_id should be unique
SELECT product_id, COUNT(*)
FROM raw.olist_products
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Translation table: category should be unique
SELECT product_category_name, COUNT(*)
FROM raw.product_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Order items: order_id + order_item_id should be unique
SELECT order_id, order_item_id, COUNT(*)
FROM raw.olist_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Payments: order_id + payment_sequential should be unique
SELECT order_id, payment_sequential, COUNT(*)
FROM raw.olist_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;


-- ---------------------------------------------------------
-- 4. REFERENTIAL INTEGRITY CHECKS
-- ---------------------------------------------------------

-- Orders -> Customers
SELECT COUNT(*) AS orders_without_customer
FROM raw.olist_orders o
LEFT JOIN raw.olist_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items -> Orders
SELECT COUNT(*) AS order_items_without_order
FROM raw.olist_order_items oi
LEFT JOIN raw.olist_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items -> Products
SELECT COUNT(*) AS order_items_without_product
FROM raw.olist_order_items oi
LEFT JOIN raw.olist_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Order items -> Sellers
SELECT COUNT(*) AS order_items_without_seller
FROM raw.olist_order_items oi
LEFT JOIN raw.olist_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Payments -> Orders
SELECT COUNT(*) AS payments_without_order
FROM raw.olist_order_payments op
LEFT JOIN raw.olist_orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Reviews -> Orders
SELECT COUNT(*) AS reviews_without_order
FROM raw.olist_order_reviews r
LEFT JOIN raw.olist_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ---------------------------------------------------------
-- 5. ORDER STATUS DISTRIBUTION
-- ---------------------------------------------------------
SELECT order_status, COUNT(*) AS order_count
FROM raw.olist_orders
GROUP BY order_status
ORDER BY order_count DESC;


-- ---------------------------------------------------------
-- 6. DATE LOGIC CHECKS
-- ---------------------------------------------------------

-- Orders where approval is before purchase (should normally be 0 or near 0)
SELECT COUNT(*) AS approval_before_purchase
FROM raw.olist_orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;

-- Orders where carrier delivery date is before approval
SELECT COUNT(*) AS carrier_before_approval
FROM raw.olist_orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date < order_approved_at;

-- Orders where customer delivery date is before carrier date
SELECT COUNT(*) AS customer_delivery_before_carrier
FROM raw.olist_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;

-- Orders where estimated delivery date is before purchase date
SELECT COUNT(*) AS estimated_before_purchase
FROM raw.olist_orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date < order_purchase_timestamp;

-- Delivered orders missing delivered_customer_date
SELECT COUNT(*) AS delivered_status_missing_customer_delivery_date
FROM raw.olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Delivered orders missing approval date
SELECT COUNT(*) AS delivered_status_missing_approval_date
FROM raw.olist_orders
WHERE order_status = 'delivered'
  AND order_approved_at IS NULL;


-- ---------------------------------------------------------
-- 7. NUMERIC / VALUE SANITY CHECKS
-- ---------------------------------------------------------

-- Non-positive item prices
SELECT COUNT(*) AS non_positive_price_rows
FROM raw.olist_order_items
WHERE price <= 0 OR price IS NULL;

-- Negative freight values
SELECT COUNT(*) AS negative_freight_rows
FROM raw.olist_order_items
WHERE freight_value < 0;

-- Non-positive payment values
SELECT COUNT(*) AS non_positive_payment_rows
FROM raw.olist_order_payments
WHERE payment_value <= 0 OR payment_value IS NULL;

-- Review scores outside expected range 1-5
SELECT COUNT(*) AS invalid_review_scores
FROM raw.olist_order_reviews
WHERE review_score NOT BETWEEN 1 AND 5;


-- ---------------------------------------------------------
-- 8. CATEGORY TRANSLATION COVERAGE
-- ---------------------------------------------------------

-- Products with missing category
SELECT COUNT(*) AS products_missing_category
FROM raw.olist_products
WHERE product_category_name IS NULL;

-- Product categories not found in translation table
SELECT COUNT(DISTINCT p.product_category_name) AS untranslated_categories
FROM raw.olist_products p
LEFT JOIN raw.product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;


-- ---------------------------------------------------------
-- 9. GEOLOCATION DUPLICATION CHECK
-- ---------------------------------------------------------

SELECT COUNT(*) AS total_geo_rows
FROM raw.olist_geolocation;

SELECT COUNT(DISTINCT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)) AS distinct_geo_rows
FROM raw.olist_geolocation;

SELECT COUNT(*) - COUNT(DISTINCT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)) AS duplicate_geo_rows
FROM raw.olist_geolocation;


-- ---------------------------------------------------------
-- 10. FANOUT / GRAIN CHECKS
-- ---------------------------------------------------------

-- Orders with multiple items
SELECT COUNT(*) AS orders_with_multiple_items
FROM (
    SELECT order_id
    FROM raw.olist_order_items
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x;

-- Orders with multiple payments
SELECT COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT order_id
    FROM raw.olist_order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x;

-- This confirms why order_items and order_payments should not be raw-joined without aggregation.


-- ---------------------------------------------------------
-- 11. PAYMENT VS ITEM TOTALS (ORDER-LEVEL SANITY CHECK)
-- ---------------------------------------------------------

WITH item_totals AS (
    SELECT
        order_id,
        ROUND(SUM(price + freight_value)::numeric, 2) AS item_total
    FROM raw.olist_order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT
        order_id,
        ROUND(SUM(payment_value)::numeric, 2) AS payment_total
    FROM raw.olist_order_payments
    GROUP BY order_id
)
SELECT
    COUNT(*) AS compared_orders,
    COUNT(*) FILTER (WHERE item_total = payment_total) AS exact_match_orders,
    COUNT(*) FILTER (WHERE ABS(item_total - payment_total) <= 0.01) AS near_match_orders,
    COUNT(*) FILTER (WHERE ABS(item_total - payment_total) > 0.01) AS mismatch_orders
FROM item_totals i
JOIN payment_totals p
    ON i.order_id = p.order_id;