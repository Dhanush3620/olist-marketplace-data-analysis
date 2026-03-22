# Data Quality Summary

## Overview
Phase 3 validated the Olist raw tables after PostgreSQL ingestion. The purpose of this step was to confirm that the dataset is structurally reliable for downstream SQL analysis, Python-based exploration, and Power BI reporting.

The validation covered row counts, null behavior, duplicate checks, referential integrity, order status distribution, date consistency, numeric sanity, category translation coverage, geolocation duplication, grain/fanout risk, and payment-versus-item total alignment.

The dataset spans the business time window from **2016-09-04 21:15:19** to **2018-10-17 17:30:18**, based on `order_purchase_timestamp` in the orders table.

---

## 1. Row Count Validation
All expected raw tables loaded successfully into PostgreSQL:

- `olist_orders`: 99,441 rows
- `olist_customers`: 99,441 rows
- `olist_order_items`: 112,650 rows
- `olist_order_payments`: 103,886 rows
- `olist_order_reviews`: 99,224 rows
- `olist_products`: 32,951 rows
- `olist_sellers`: 3,095 rows
- `product_category_translation`: 71 rows
- `olist_geolocation`: 1,000,163 rows

These counts are internally consistent with the raw file audit and confirm successful ingestion of the full dataset.

---

## 2. Null Behavior
### Orders table
The `olist_orders` table is well populated on core identifiers and transaction timestamps:
- `order_id`, `customer_id`, `order_status`, `order_purchase_timestamp`, and `order_estimated_delivery_date` contain no nulls.
- Nulls appear in lifecycle fields:
  - `order_approved_at`: 160
  - `order_delivered_carrier_date`: 1,783
  - `order_delivered_customer_date`: 2,965

These nulls are expected in part because not all orders reached the same fulfillment stage. They should be interpreted in the context of `order_status`, not treated as blanket data errors.

### Order items table
The `olist_order_items` table has no nulls in key business columns:
- `order_id`, `order_item_id`, `product_id`, `seller_id`, `shipping_limit_date`, `price`, and `freight_value` are fully populated.

This makes it a reliable line-item fact table for sales and freight analysis.

### Customers table
The customer table has no nulls in either `customer_id` or `customer_unique_id`, which supports stable customer linkage and repeat-customer analysis.

### Payments table
The payment table has no nulls in `order_id`, `payment_type`, or `payment_value`, which makes it usable for payment mix and order-level revenue aggregation.

### Reviews table
The review table has no nulls in `review_id`, `order_id`, or `review_score`, so quantitative review analysis is safe.
However, text fields are sparse:
- `review_comment_title`: 87,656 nulls
- `review_comment_message`: 58,247 nulls

This means review score analysis is reliable, but text mining or sentiment analysis on review comments would require caution.

### Products table
The product table is mostly usable, but metadata incompleteness exists:
- `product_category_name`: 610 nulls
- `product_name_lenght`: 610 nulls
- `product_description_lenght`: 610 nulls
- `product_photos_qty`: 610 nulls
- `product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm`: 2 nulls each

This affects category and product-attribute reporting slightly and should be handled with fallback labels such as “Unknown”.

---

## 3. Duplicate Checks
Duplicate tests returned zero duplicate rows for all expected keys:

- `olist_orders.order_id`
- `olist_customers.customer_id`
- `olist_sellers.seller_id`
- `olist_products.product_id`
- `product_category_translation.product_category_name`
- `olist_order_items (order_id, order_item_id)`
- `olist_order_payments (order_id, payment_sequential)`

This confirms that the main table grains are preserved correctly and that the assumed primary/composite keys are valid for analysis.

---

## 4. Referential Integrity
All major foreign-key-style relationships passed the orphan checks:

- orders without customer: 0
- order items without order: 0
- order items without product: 0
- order items without seller: 0
- payments without order: 0
- reviews without order: 0

This is a strong result. It means the core joins required for downstream modeling are clean and no immediate exclusion logic is needed to handle orphaned records.

---

## 5. Order Status Distribution
The dataset is heavily dominated by delivered orders:

- delivered: 96,478
- shipped: 1,107
- canceled: 625
- unavailable: 609
- invoiced: 314
- processing: 301
- created: 5
- approved: 2

Delivered orders account for the vast majority of the dataset, so most operational and revenue analyses will be strongly influenced by successfully completed purchases. At the same time, the smaller set of non-delivered statuses remains important for cancellation, failure, and fulfillment-friction analysis.

---

## 6. Date Consistency Checks
Date logic is mostly sound, with a few anomalies:

- `approval_before_purchase`: 0
- `estimated_before_purchase`: 0
- `carrier_before_approval`: 1,359
- `customer_delivery_before_carrier`: 23
- delivered orders missing `order_delivered_customer_date`: 8
- delivered orders missing `order_approved_at`: 14

Interpretation:
- The absence of approvals before purchase and estimated dates before purchase is a good sign.
- The 1,359 cases where carrier handoff appears before approval should be treated as timestamp anomalies or operational logging inconsistencies.
- The 23 cases where customer delivery appears before carrier handoff are also likely timestamp-quality issues.
- The 8 delivered orders missing customer delivery date and 14 delivered orders missing approval date are very small relative to total delivered volume and do not materially threaten analysis.

These date anomalies should be documented, but they are not large enough to block business analysis.

---

## 7. Numeric and Value Sanity
Numeric sanity checks are strong overall:

- non-positive item prices: 0
- negative freight values: 0
- invalid review scores: 0
- non-positive payment values: 9

This means pricing, freight, and review-score fields are highly reliable. The 9 non-positive payment rows are a tiny exception and should be reviewed later before final payment-based KPI calculations.

---

## 8. Category Translation Coverage
Category coverage is good but not perfect:

- products missing category: 610
- untranslated product categories: 2

This means most category reporting can safely use the translation table, but dashboard logic should include a fallback bucket such as “Unknown / Untranslated”.

---

## 9. Geolocation Quality
The geolocation table is complete in null terms, but it is not a clean dimension table:

- total rows: 1,000,163
- distinct geo rows: 738,327
- duplicate geo rows: 261,836

This confirms that geolocation contains heavy duplication and should not be joined directly into the analytical model without deduplication or pre-aggregation.

---

## 10. Grain and Fanout Risk
The grain checks confirm two important modeling realities:

- orders with multiple items: 9,803
- orders with multiple payments: 2,961

This validates the earlier modeling warning that `olist_order_items` and `olist_order_payments` are both one-to-many relative to `olist_orders`. Because of that, they should **not** be raw-joined together in KPI queries or Power BI models without first aggregating one or both tables to order level.

---

## 11. Payment vs Item Total Alignment
Comparing order-level item totals (`price + freight_value`) against aggregated payment totals gives:

- compared orders: 98,665
- exact match orders: 98,089
- near match orders (within 0.01): 98,362
- mismatch orders: 303

This is a very good result. It shows that item-level totals and payment-level totals align for the overwhelming majority of comparable orders, with only a very small number of mismatches. That supports the use of both metrics, provided they are aggregated correctly before comparison.

---

## Business-Safe Modeling Decisions
Based on the Phase 3 results, the following rules should be used in the rest of the project:

1. Use `customer_unique_id` for customer-level analysis and repeat-customer metrics.
2. Use `order_id` as the base grain for order-level KPIs.
3. Aggregate payments to order level before joining to item-level data.
4. Treat `olist_order_items` as the source of product revenue and freight metrics.
5. Treat `olist_order_payments` as the source of payment-method and gross payment metrics.
6. Restrict delivery-timing KPIs primarily to delivered orders.
7. Use translated English category names where available, with fallback handling for missing/untranslated categories.
8. Do not use geolocation directly without preprocessing.

---

## Conclusion
The Olist raw dataset is analytically strong and suitable for end-to-end business analysis. Structural integrity is excellent: expected keys are unique, core joins are clean, and the major transactional tables are well populated. The main caveats are operational timestamp anomalies, sparse review text fields, a small amount of missing product metadata, a few non-positive payment rows, and substantial duplication in geolocation.

None of these issues prevent Phase 4 analysis. They simply define the modeling rules and caveats that should be carried forward into KPI development, Python analysis, and dashboard design.