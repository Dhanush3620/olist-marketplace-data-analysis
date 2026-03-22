# KPI Definitions

## Order KPIs
- Total Orders = count of distinct order_id
- Delivered Orders = count of distinct order_id where order_status = 'delivered'
- Delivery Rate = delivered orders / total orders
- Cancellation Rate = canceled orders / total orders

## Revenue KPIs
- Gross Payment Value = sum of payment_value at order level
- Product Revenue = sum of price from order items
- Freight Revenue = sum of freight_value from order items
- Average Order Value = gross payment value / total orders

## Customer KPIs
- Total Customers = count of distinct customer_unique_id
- Repeat Customers = customers with more than one distinct order
- Repeat Customer Rate = repeat customers / total customers

## Satisfaction KPIs
- Average Review Score = average of review_score
- 1-Star Review Rate = 1-star reviews / total reviews

## Delivery KPIs
- Avg Delivery Days = avg(order_delivered_customer_date - order_purchase_timestamp)
- Late Delivery Rate = orders delivered after estimated delivery date / delivered orders