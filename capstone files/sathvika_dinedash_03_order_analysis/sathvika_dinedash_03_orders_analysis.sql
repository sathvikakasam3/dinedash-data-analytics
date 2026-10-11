-- Databricks notebook source
SELECT COUNT(*) AS total_orders
FROM sathvika_dinedash_db.sathvika_orders_bronze;

-- COMMAND ----------

SELECT
    payment_method,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY payment_method
ORDER BY order_count DESC;

-- COMMAND ----------

DESCRIBE sathvika_dinedash_db.sathvika_orders_bronze;

-- COMMAND ----------

SELECT 
    order_status,
    COUNT(*) AS order_count
from sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY order_status
ORDER BY order_count DESC;

-- COMMAND ----------

SELECT 
    restaurant_id,
    COUNT(*) AS order_count
from sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY restaurant_id
ORDER BY order_count DESC;

-- COMMAND ----------

SELECT 
    customer_id,
    COUNT(*) AS order_count
from sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY customer_id
ORDER BY order_count DESC;

-- COMMAND ----------

SELECT 
    agent_id,
    COUNT(*) AS order_count
from sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY agent_id
ORDER BY order_count DESC;

-- COMMAND ----------

SELECT
    order_id,
    customer_id,
    restaurant_id,
    total_amount
FROM sathvika_dinedash_db.sathvika_orders_bronze
ORDER BY total_amount DESC
LIMIT 10;

-- COMMAND ----------

SELECT
    payment_method,
    ROUND(AVG(tip), 2) AS average_tip_amount
FROM sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY payment_method
ORDER BY average_tip_amount DESC;

-- COMMAND ----------

SELECT
    ROUND(COUNT(CASE WHEN tip > total_amount * 0.10 THEN 1 END) * 100.0 / COUNT(*),2) AS percentage_orders
FROM sathvika_dinedash_db.sathvika_orders_bronze;

-- COMMAND ----------

SELECT
    order_status,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sathvika_dinedash_db.sathvika_orders_bronze), 2) AS percentage_orders
FROM sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY order_status
ORDER BY percentage_orders DESC;

-- COMMAND ----------

SELECT
    customer_id,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY customer_id
ORDER BY order_count DESC
LIMIT 10;

-- COMMAND ----------

SELECT
    restaurant_id,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze
GROUP BY restaurant_id
ORDER BY order_count DESC
LIMIT 10;

-- COMMAND ----------

SELECT
    item.item_id,
    COUNT(*) AS order_count
FROM sathvika_dinedash_db.sathvika_orders_bronze
LATERAL VIEW EXPLODE(items_ordered) t AS item
GROUP BY item.item_id
ORDER BY order_count DESC
LIMIT 10;

-- COMMAND ----------

SELECT
    ROUND(AVG(size(items_ordered)), 2) AS average_items_per_order
FROM sathvika_dinedash_db.sathvika_orders_bronze;

-- COMMAND ----------

SELECT
    restaurant_id,
    item.item_id,
    ROUND(SUM(item.quantity * item.price), 2) AS item_revenue
FROM sathvika_dinedash_db.sathvika_orders_bronze
LATERAL VIEW EXPLODE(items_ordered) t AS item
GROUP BY restaurant_id, item.item_id
ORDER BY item_revenue DESC;