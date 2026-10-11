-- Databricks notebook source
-- 1. Find the preferred restaurant names for each customer
SELECT
    o.customer_id,
    r.name AS restaurant_name,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
GROUP BY
    o.customer_id,
    r.name
ORDER BY
    o.customer_id,
    order_count DESC;

-- COMMAND ----------

-- 2. Find the top 10 areas receiving orders in each month
SELECT month, area_name, order_count
FROM (
    SELECT
        MONTH(o.timestamp) AS month,
        l.area AS area_name,
        COUNT(*) AS order_count,
        ROW_NUMBER() OVER (
            PARTITION BY MONTH(o.timestamp)
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM sathvika_dinedash_db.sathvika_orders_bronze o
    JOIN sathvika_dinedash_db.sathvika_locations_bronze l
        ON o.delivery_location_id = l.location_id
    GROUP BY MONTH(o.timestamp), l.area
)
WHERE rn <= 10
ORDER BY month, order_count DESC;

-- COMMAND ----------

-- 3. Find all successfully delivered orders that were paid using a card, to analyze payment preferences and delivery success rates
SELECT
    order_id,
    customer_id,
    restaurant_id,
    payment_method,
    order_status,
    total_amount
FROM sathvika_dinedash_db.sathvika_orders_bronze
WHERE order_status = 'delivered'
  AND payment_method = 'card';

-- COMMAND ----------

-- 4. Which cuisines generate the highest average order value?
-- Hint: Join orders, restaurants, group by cuisine, and calculate average total_amount.
SELECT
    r.cuisines,
    ROUND(AVG(o.total_amount), 2) AS average_order_value
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
GROUP BY r.cuisines
ORDER BY average_order_value DESC;

-- COMMAND ----------

-- 5. Which delivery agents have delivered the most high-value orders (above $50)?
-- Hint: Filter orders for total_amount > 50, join with agent, group by agent_id, count orders.

SELECT
    o.agent_id,
    a.name,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_delivery_agents_bronze a
    ON o.agent_id = a.agent_id
WHERE o.total_amount > 50
GROUP BY o.agent_id, a.name
ORDER BY order_count DESC;

-- COMMAND ----------

-- 6. Which cities (area_name) are generating the most revenue for Italian restaurants?
-- Hint: Join orders, restaurants, locations, filter cuisine = 'Italian', group by area_name, sum total_amount.

SELECT
    l.area AS area_name,
    ROUND(SUM(o.total_amount), 2) AS revenue
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
JOIN sathvika_dinedash_db.sathvika_locations_bronze l
    ON r.location_id = l.location_id
WHERE r.cuisines LIKE '%Italian%'
GROUP BY l.area
ORDER BY revenue DESC;

-- COMMAND ----------

-- 7. What is the tip-to-total ratio by cuisine type?
-- Hint: Join orders, restaurants, group by cuisine, calculate average tip / total_amount.

SELECT
    r.cuisines,
    SUM(o.tip) / SUM(o.total_amount) AS tip_to_total_ratio
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
GROUP BY r.cuisines
ORDER BY tip_to_total_ratio DESC;

-- COMMAND ----------

-- 8. Which menu items are most frequently ordered, and from which restaurants?
-- Hint: Explode items_ordered in orders, join with menu_items, group by item_name, restaurant_id, count.

SELECT
    m.item_name,
    sub.restaurant_id,
    COUNT(*) AS order_count
FROM (
    SELECT o.restaurant_id, item.item_id
    FROM sathvika_dinedash_db.sathvika_orders_bronze o
    LATERAL VIEW EXPLODE(o.items_ordered) t AS item
) sub
JOIN sathvika_dinedash_db.sathvika_menu_items_bronze m
    ON sub.item_id = m.item_id
GROUP BY m.item_name, sub.restaurant_id
ORDER BY order_count DESC;

-- COMMAND ----------

-- 9. Which agents have delivered the most diverse cuisines?
-- Hint: Join orders, restaurants, group by agent_id, count distinct cuisine.

SELECT
    o.agent_id,
    COUNT(DISTINCT r.cuisines) AS cuisine_count
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
GROUP BY o.agent_id
ORDER BY cuisine_count DESC;

-- COMMAND ----------

-- 10. What is the average customer lifetime value by signup year?
-- Hint: Join orders, customers, extract year from signup_date, group by year, sum total_amount per customer, then average total amount per customer, then average.

SELECT
    signup_year,
    ROUND(AVG(customer_total), 2) AS average_customer_lifetime_value
FROM (
    SELECT
        c.customer_id,
        YEAR(c.signup_date) AS signup_year,
        SUM(o.total_amount) AS customer_total
    FROM sathvika_dinedash_db.sathvika_orders_bronze o
    JOIN sathvika_dinedash_db.sathvika_customers_bronze c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, YEAR(c.signup_date)
)
GROUP BY signup_year
ORDER BY signup_year;

-- COMMAND ----------

-- 11. Which restaurants have the highest order frequency per location?
-- Hint: Join orders, restaurants, locations, group by restaurant_id, location_id, count orders.

SELECT
    o.restaurant_id,
    r.location_id,
    l.area,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
JOIN sathvika_dinedash_db.sathvika_locations_bronze l
    ON r.location_id = l.location_id
GROUP BY
    o.restaurant_id,
    r.location_id,
    l.area
ORDER BY order_count DESC;

-- COMMAND ----------

-- 12. Which locations are prone to order cancellations?
-- Hint: Filter orders with order_status = 'cancelled', join locations using delivery_location_id, group by area_name, count.

SELECT
    l.area AS area_name,
    COUNT(*) AS cancelled_orders
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_locations_bronze l
    ON o.delivery_location_id = l.location_id
WHERE o.order_status = 'cancelled'
GROUP BY l.area
ORDER BY cancelled_orders DESC;

-- COMMAND ----------

-- 13. Find top 10 customers who have ordered from the widest variety of restaurants.
-- Hint: Join orders, group by customer_id, count distinct restaurant_id, sort and pick top 10.

SELECT
    customer_id,
    COUNT(DISTINCT restaurant_id) AS restaurant_count
FROM sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY customer_id
ORDER BY restaurant_count DESC
LIMIT 10;

-- COMMAND ----------

-- 14. Identify restaurants with frequent repeat customers.
-- Hint: Join orders, group by restaurant_id, customer_id, count, filter where count > 1.

SELECT
    restaurant_id,
    customer_id,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY restaurant_id, customer_id
HAVING COUNT(*) > 1
ORDER BY order_count DESC;

-- COMMAND ----------

-- 15. Which payment methods are most preferred for high-value orders across cuisines?
-- Hint: Filter orders with total_amount > 40, join restaurants, group by cuisine, payment_method, count.

SELECT
    r.cuisines,
    o.payment_method,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze o
JOIN sathvika_dinedash_db.sathvika_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
WHERE o.total_amount > 40
GROUP BY r.cuisines, o.payment_method
ORDER BY order_count DESC;