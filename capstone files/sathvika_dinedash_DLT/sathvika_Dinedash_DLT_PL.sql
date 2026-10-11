-- Databricks notebook source
CREATE OR REFRESH STREAMING TABLE sath_orders_bronze
AS
SELECT *
FROM STREAM read_files(
  '/Volumes/sathvika_databricks_workspace_7405612503983294/sathvika_dinedash_db/sathvika_dinedash_volume/orders/',
  format => 'json'
);

-- COMMAND ----------

-- DBTITLE 1,Cell 2
CREATE OR REFRESH MATERIALIZED VIEW sath_restaurants_bronze AS
SELECT *
FROM read_files(
    '/Volumes/sathvika_databricks_workspace_7405612503983294/sathvika_dinedash_db/sathvika_dinedash_volume/restaurants/dim_restaurants.csv',
    format=>'csv',
    inferSchema => true,
    header => true
);

-- COMMAND ----------

-- DBTITLE 1,Cell 3
CREATE OR REFRESH MATERIALIZED VIEW sath_items_bronze AS
SELECT *
FROM read_files(
    '/Volumes/sathvika_databricks_workspace_7405612503983294/sathvika_dinedash_db/sathvika_dinedash_volume/menu_items/dim_menu_items.csv',
    format=>'csv',
    inferSchema => true,
    header => true
);

-- COMMAND ----------

-- DBTITLE 1,Cell 4
CREATE OR REFRESH MATERIALIZED VIEW sath_customers_bronze AS
SELECT *
FROM read_files(
    '/Volumes/sathvika_databricks_workspace_7405612503983294/sathvika_dinedash_db/sathvika_dinedash_volume/customers/dim_customers.csv',
    format=>'csv',
    inferSchema => true,
    header => true
);

-- COMMAND ----------

-- DBTITLE 1,Cell 5
CREATE OR REFRESH MATERIALIZED VIEW sath_agents_bronze AS
SELECT *
FROM read_files(
    '/Volumes/sathvika_databricks_workspace_7405612503983294/sathvika_dinedash_db/sathvika_dinedash_volume/delivery_agents/dim_delivery_agents.csv',
    format=>'csv',
    inferSchema => true,
    header => true
);

-- COMMAND ----------

-- DBTITLE 1,Cell 6
CREATE OR REFRESH MATERIALIZED VIEW sath_locations_bronze AS
SELECT *
FROM read_files(
    '/Volumes/sathvika_databricks_workspace_7405612503983294/sathvika_dinedash_db/sathvika_dinedash_volume/locations/dim_locations.csv',
    format=>'csv',
    inferSchema => true,
    header => true
);

-- COMMAND ----------

-- SILVER LAYER: Clean + Normalize
CREATE OR REFRESH STREAMING LIVE TABLE sath_cleaned_orders (
    CONSTRAINT valid_order_id EXPECT (order_id IS NOT NULL) ON VIOLATION DROP ROW,
    CONSTRAINT valid_customer EXPECT (customer_id IS NOT NULL) ON VIOLATION DROP ROW,
    CONSTRAINT valid_items EXPECT (size(items_ordered) > 0) ON VIOLATION DROP ROW
)
AS
SELECT
    order_id,
    timestamp AS order_ts,
    customer_id,
    restaurant_id,
    agent_id,
    delivery_location_id,
    items_ordered,
    explode(items_ordered) AS item,
    total_amount,
    tip,
    payment_method,
    order_status
FROM STREAM(Live.sath_orders_bronze);

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE sath_orders_silver
(
    CONSTRAINT valid_restaurant_name EXPECT (restaurant_name IS NOT NULL) ON VIOLATION DROP ROW,
    CONSTRAINT valid_agent EXPECT (agent_name IS NOT NULL) ON VIOLATION DROP ROW,
    CONSTRAINT valid_item EXPECT (item_id IS NOT NULL) ON VIOLATION DROP ROW
)
AS
SELECT
    o.order_id,
    o.order_ts,
    o.customer_id,
    c.name AS customer_name,
    c.email,
    o.restaurant_id,
    r.name AS restaurant_name,
    r.cuisines,
    r.rating AS restaurant_rating,
    o.agent_id,
    a.name AS agent_name,
    a.rating AS agent_rating,
    o.delivery_location_id,
    l.city,
    o.item.item_id AS item_id,
    i.item_name,
    i.category,
    o.item.price AS item_price,
    o.item.quantity AS item_quantity,
    o.total_amount,
    o.tip,
    o.payment_method,
    o.order_status
FROM STREAM(Live.sath_cleaned_orders) o
LEFT JOIN Live.sath_customers_bronze c
    ON o.customer_id = c.customer_id
LEFT JOIN Live.sath_restaurants_bronze r
    ON o.restaurant_id = r.restaurant_id
LEFT JOIN Live.sath_agents_bronze a
    ON o.agent_id = a.agent_id
LEFT JOIN Live.sath_items_bronze i
    ON o.item.item_id = i.item_id
LEFT JOIN Live.sath_locations_bronze l
    ON o.delivery_location_id = l.location_id;

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE sath_orders_with_agents AS
SELECT
    o.order_id,
    o.order_ts,
    o.agent_id,
    a.name AS agent_name,
    a.rating AS agent_rating,
    o.tip
FROM STREAM(Live.sath_cleaned_orders) o
LEFT JOIN sath_agents_bronze a
    ON o.agent_id = a.agent_id;

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE sath_orders_with_items AS
SELECT
    o.order_id,
    o.order_ts,
    o.restaurant_id,
    exploded.item_id,
    i.item_name,
    i.category,
    exploded.price,
    exploded.quantity
FROM (
    SELECT order_id, timestamp AS order_ts, restaurant_id, explode(items_ordered) AS exploded
    FROM STREAM(Live.sath_orders_bronze)
) o
LEFT JOIN sath_items_bronze i
    ON o.exploded.item_id = i.item_id;

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE sath_orders_with_locations AS
SELECT
    o.order_id,
    o.order_ts,
    o.delivery_location_id,
    l.city,
    l.state,
    l.area
FROM STREAM(Live.sath_cleaned_orders) o
LEFT JOIN sath_locations_bronze l
    ON o.delivery_location_id = l.location_id;

-- COMMAND ----------

-- GOLD LAYER: Insightful Metrics

-- 1. Total orders per restaurant
CREATE OR REFRESH MATERIALIZED VIEW sath_total_orders_per_restaurant AS
SELECT restaurant_name, COUNT(DISTINCT order_id) AS total_orders
FROM sath_orders_silver
GROUP BY restaurant_name;

-- COMMAND ----------

-- 2. Top-selling items
CREATE OR REFRESH MATERIALIZED VIEW sath_top_selling_items AS
SELECT item_name, SUM(item_quantity) AS total_qty_sold
FROM sath_orders_silver
GROUP BY item_name
ORDER BY total_qty_sold DESC
LIMIT 10;

-- COMMAND ----------

-- 3. Avg delivery fee and tip by city
CREATE OR REFRESH MATERIALIZED VIEW sath_avg_fees_by_city AS
SELECT city, AVG(restaurant_rating) AS avg_restaurant_rating, AVG(tip) AS avg_tip
FROM sath_orders_silver
GROUP BY city;

-- COMMAND ----------

-- 4. Agent performance
CREATE OR REFRESH MATERIALIZED VIEW sath_agent_order_counts AS
SELECT agent_name, COUNT(DISTINCT order_id) AS orders_handled,
AVG(agent_rating) AS avg_rating
FROM sath_orders_silver
GROUP BY agent_name
ORDER BY orders_handled DESC;

-- COMMAND ----------

-- 5. Revenue trend
CREATE OR REFRESH MATERIALIZED VIEW daily_revenue_trend AS
SELECT DATE(order_ts) AS order_date, SUM(total_amount) AS total_revenue
FROM Live.sath_orders_silver
GROUP BY order_date
ORDER BY order_date;

-- COMMAND ----------

-- 6. Customer lifetime value
CREATE OR REFRESH MATERIALIZED VIEW sath_customer_ltv AS
SELECT customer_id, customer_name, SUM(total_amount) AS lifetime_spend
FROM sath_orders_silver
GROUP BY customer_id, customer_name
ORDER BY lifetime_spend DESC;

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE sath_orders_with_customers AS
SELECT
    o.order_id,
    o.customer_id,
    c.name AS customer_name,
    c.location_id AS customer_location_id,
    o.total_amount,
    o.tip,
    o.payment_method,
    o.order_status
FROM STREAM(Live.sath_cleaned_orders) o
LEFT JOIN Live.sath_customers_bronze c
ON o.customer_id = c.customer_id;

-- COMMAND ----------


CREATE OR REFRESH MATERIALIZED VIEW sath_customer_order_counts AS
SELECT customer_name, COUNT(*) AS total_orders
FROM sath_orders_with_customers
GROUP BY customer_name;