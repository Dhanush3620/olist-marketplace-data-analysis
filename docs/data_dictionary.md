# Data Dictionary

## 1. olist_orders_dataset.csv
- **Grain:** One row per order
- **Primary Key:** `order_id`
- **Key Columns:**
    - `order_id` - Unique order identifier
    - `customer_id` - Links to customer table
    - `order_status` - Order state (delivered, shipped, canceled, etc.)
    - `order_purchase_timestamp` - Order placement time
    - `order_approved_at` - Payment/order approval time
    - `order_delivered_carrier_date` - Carrier handoff date
    - `order_delivered_customer_date` - Actual delivery date
    - `order_estimated_delivery_date` - Promised delivery date

## 2. olist_order_items_dataset.csv
- **Grain:** One row per order item
- **Primary Key:** `order_id` + `order_item_id`
- **Key Columns:**
    - `order_id` - References order
    - `order_item_id` - Item sequence number within order
    - `product_id` - Product identifier
    - `seller_id` - Seller identifier
    - `shipping_limit_date` - Shipping deadline
    - `price` - Item price
    - `freight_value` - Shipping cost