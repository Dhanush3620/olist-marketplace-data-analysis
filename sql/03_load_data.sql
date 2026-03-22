COPY raw.olist_sellers
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY raw.product_category_translation
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/product_category_name_translation.csv'
DELIMITER ','
CSV HEADER;

COPY raw.olist_orders
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY raw.olist_order_items
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY raw.olist_customers
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_customers_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY raw.olist_geolocation
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_geolocation_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY raw.olist_order_payments
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY raw.olist_order_reviews
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY raw.olist_products
FROM '/Users/dhanushgarikapati/olist-end-to-end-analysis/data/raw/olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;