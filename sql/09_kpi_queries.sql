-- =========================================================
-- PHASE 4 KPI QUERIES
-- =========================================================

-- 1. Executive summary KPI block
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'delivered')
        / COUNT(DISTINCT order_id),
        2
    ) AS delivered_rate_pct,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'canceled') AS canceled_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'canceled')
        / COUNT(DISTINCT order_id),
        2
    ) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN order_status = 'delivered' THEN COALESCE(order_value_proxy, 0) ELSE 0 END)::numeric, 2) AS delivered_gpv,
    ROUND(SUM(CASE WHEN order_status = 'delivered' THEN COALESCE(product_revenue, 0) ELSE 0 END)::numeric, 2) AS delivered_product_revenue,
    ROUND(SUM(CASE WHEN order_status = 'delivered' THEN COALESCE(freight_revenue, 0) ELSE 0 END)::numeric, 2) AS delivered_freight_revenue,
    ROUND(AVG(CASE WHEN order_status = 'delivered' THEN order_value_proxy ELSE NULL END)::numeric, 2) AS avg_order_value,
    ROUND(AVG(CASE WHEN order_status = 'delivered' THEN avg_review_score ELSE NULL END)::numeric, 2) AS avg_review_score,
    ROUND(AVG(CASE WHEN order_status = 'delivered' THEN delivery_days ELSE NULL END)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(CASE WHEN order_status = 'delivered' THEN late_delivery_flag::numeric ELSE NULL END) * 100, 2) AS late_delivery_rate_pct
FROM analytics.v_orders_enriched;


-- 2. Monthly KPI trend
WITH monthly AS (
    SELECT
        purchase_month_start,
        COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
        ROUND(SUM(CASE WHEN order_status = 'delivered' THEN COALESCE(order_value_proxy, 0) ELSE 0 END)::numeric, 2) AS delivered_gpv,
        ROUND(AVG(CASE WHEN order_status = 'delivered' THEN avg_review_score ELSE NULL END)::numeric, 2) AS avg_review_score,
        ROUND(AVG(CASE WHEN order_status = 'delivered' THEN delivery_days ELSE NULL END)::numeric, 2) AS avg_delivery_days,
        ROUND(AVG(CASE WHEN order_status = 'delivered' THEN late_delivery_flag::numeric ELSE NULL END) * 100, 2) AS late_delivery_rate_pct
    FROM analytics.v_orders_enriched
    GROUP BY purchase_month_start
)
SELECT
    purchase_month_start,
    delivered_orders,
    delivered_gpv,
    avg_review_score,
    avg_delivery_days,
    late_delivery_rate_pct,
    ROUND(
        (
            (delivered_gpv - LAG(delivered_gpv) OVER (ORDER BY purchase_month_start))
            / NULLIF(LAG(delivered_gpv) OVER (ORDER BY purchase_month_start), 0)
        ) * 100,
        2
    ) AS mom_gpv_growth_pct
FROM monthly
ORDER BY purchase_month_start;


-- 3. Customer repeat metrics
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE repeat_customer_flag = 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE repeat_customer_flag = 1) / COUNT(*), 2) AS repeat_customer_rate_pct,
    ROUND(AVG(total_orders)::numeric, 2) AS avg_orders_per_customer,
    ROUND(AVG(lifetime_value_delivered)::numeric, 2) AS avg_customer_lifetime_value
FROM analytics.v_customer_summary;


-- 4. Payment mix for delivered orders
SELECT
    op.payment_type,
    COUNT(*) AS payment_rows,
    ROUND(SUM(op.payment_value)::numeric, 2) AS payment_value,
    ROUND(
        100.0 * SUM(op.payment_value) / SUM(SUM(op.payment_value)) OVER (),
        2
    ) AS payment_value_share_pct
FROM raw.olist_order_payments op
JOIN raw.olist_orders o
    ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY payment_value DESC;


-- 5. Top 10 categories by product revenue
SELECT
    product_category_en,
    SUM(delivered_orders) AS total_delivered_orders,
    ROUND(SUM(product_revenue)::numeric, 2) AS total_product_revenue,
    ROUND(SUM(freight_revenue)::numeric, 2) AS total_freight_revenue,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(late_delivery_rate) * 100, 2) AS late_delivery_rate_pct
FROM analytics.v_category_performance
GROUP BY product_category_en
ORDER BY total_product_revenue DESC
LIMIT 10;


-- 6. Bottom 10 categories by review score (with meaningful volume)
SELECT
    product_category_en,
    SUM(delivered_orders) AS total_delivered_orders,
    ROUND(SUM(product_revenue)::numeric, 2) AS total_product_revenue,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(late_delivery_rate) * 100, 2) AS late_delivery_rate_pct
FROM analytics.v_category_performance
GROUP BY product_category_en
HAVING SUM(delivered_orders) >= 100
ORDER BY avg_review_score ASC, total_product_revenue DESC
LIMIT 10;


-- 7. Top 10 sellers by product revenue
SELECT
    seller_id,
    seller_state,
    SUM(delivered_orders) AS total_delivered_orders,
    ROUND(SUM(product_revenue)::numeric, 2) AS total_product_revenue,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(avg_delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(late_delivery_rate) * 100, 2) AS late_delivery_rate_pct
FROM analytics.v_seller_performance
GROUP BY seller_id, seller_state
ORDER BY total_product_revenue DESC
LIMIT 10;


-- 8. Top states by delivered GPV
SELECT
    customer_state,
    SUM(delivered_orders) AS total_delivered_orders,
    ROUND(SUM(delivered_gpv)::numeric, 2) AS total_delivered_gpv,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(avg_delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(late_delivery_rate) * 100, 2) AS late_delivery_rate_pct
FROM analytics.v_state_performance
GROUP BY customer_state
ORDER BY total_delivered_gpv DESC
LIMIT 10;


-- 9. Delivery performance vs review score
SELECT
    CASE
        WHEN late_delivery_flag = 1 THEN 'Late'
        WHEN late_delivery_flag = 0 AND order_status = 'delivered' THEN 'On Time / Early'
        ELSE 'Other'
    END AS delivery_bucket,
    COUNT(*) AS orders,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days
FROM analytics.v_orders_enriched
WHERE order_status = 'delivered'
  AND avg_review_score IS NOT NULL
GROUP BY delivery_bucket
ORDER BY orders DESC;


-- 10. Revenue opportunity categories:
-- high revenue but weak customer experience
WITH category_totals AS (
    SELECT
        product_category_en,
        SUM(delivered_orders) AS total_delivered_orders,
        ROUND(SUM(product_revenue)::numeric, 2) AS total_product_revenue,
        ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
        ROUND(AVG(late_delivery_rate) * 100, 2) AS late_delivery_rate_pct
    FROM analytics.v_category_performance
    GROUP BY product_category_en
)
SELECT *
FROM category_totals
WHERE total_delivered_orders >= 100
  AND total_product_revenue >= (
      SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_product_revenue)
      FROM category_totals
  )
  AND (
      avg_review_score < (
          SELECT AVG(avg_review_score) FROM category_totals
      )
      OR late_delivery_rate_pct > (
          SELECT AVG(late_delivery_rate_pct) FROM category_totals
      )
  )
ORDER BY total_product_revenue DESC;