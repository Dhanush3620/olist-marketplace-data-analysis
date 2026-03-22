SELECT 'olist_sellers' AS table_name, COUNT(*) AS row_count FROM raw.olist_sellers
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM raw.product_category_translation
UNION ALL
SELECT 'olist_orders', COUNT(*) FROM raw.olist_orders
UNION ALL
SELECT 'olist_order_items', COUNT(*) FROM raw.olist_order_items
UNION ALL
SELECT 'olist_customers', COUNT(*) FROM raw.olist_customers
UNION ALL
SELECT 'olist_geolocation', COUNT(*) FROM raw.olist_geolocation
UNION ALL
SELECT 'olist_order_payments', COUNT(*) FROM raw.olist_order_payments
UNION ALL
SELECT 'olist_order_reviews', COUNT(*) FROM raw.olist_order_reviews
UNION ALL
SELECT 'olist_products', COUNT(*) FROM raw.olist_products
ORDER BY table_name;