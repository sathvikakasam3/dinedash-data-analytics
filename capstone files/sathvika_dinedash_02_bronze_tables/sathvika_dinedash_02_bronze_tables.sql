-- Databricks notebook source
CREATE OR REPLACE TEMP VIEW dinedash_customers_tmp_view AS

SELECT
    *,
    current_timestamp() AS ingestion_time,
    _metadata.file_name AS source_file_name

FROM read_files(
    '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/customers/*.csv',
    format => 'csv',
    header => true,
    inferSchema => true
);

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW dinedash_delivery_agents_tmp_view
AS
SELECT *,current_timestamp() AS ingestion_time,_metadata.file_name AS source_file_name
FROM read_files(
  '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/delivery_agents/*.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW dinedash_locations_tmp_view
AS
SELECT *,current_timestamp() AS ingestion_time,_metadata.file_name AS source_file_name
FROM read_files(
  '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/locations/*.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW dinedash_menu_items_tmp_view
AS
SELECT *,current_timestamp() AS ingestion_time, _metadata.file_name AS source_file_name
FROM read_files(
  '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/menu_items/*.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW dinedash_restaurants_tmp_view
AS
SELECT *,current_timestamp() AS ingestion_time, _metadata.file_name AS source_file_name
FROM read_files(
  '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/restaurants/*.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

-- COMMAND ----------

show tables;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_customers_bronze (
    customer_id STRING,
    name STRING,
    email STRING,
    dob DATE,
    signup_date DATE,
    location_id STRING,
    ingestion_time TIMESTAMP,
    source_file_name STRING
);

-- COMMAND ----------

INSERT INTO sathvika_dinedash_db.sathvika_customers_bronze
SELECT
    customer_id,
    name,
    email,
    CAST(dob AS DATE),
    CAST(signup_date AS DATE),
    location_id,
    ingestion_time,
    source_file_name
FROM dinedash_customers_tmp_view;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_delivery_agents_bronze (
    agent_id STRING,
    name STRING,
    phone STRING,
    rating DOUBLE,
    _rescued_data STRING,
    ingestion_time TIMESTAMP,
    source_file_name STRING
);

-- COMMAND ----------

INSERT INTO sathvika_dinedash_db.sathvika_delivery_agents_bronze
SELECT
    agent_id,
    name,
    phone,
    rating,
    _rescued_data,
    ingestion_time,
    source_file_name
FROM dinedash_delivery_agents_tmp_view;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_locations_bronze (
    location_id STRING,
    area STRING,
    city STRING,
    state STRING,
    latitude DOUBLE,
    longitude DOUBLE,
    _rescued_data STRING,
    ingestion_time TIMESTAMP,
    source_file_name STRING
);

-- COMMAND ----------

INSERT INTO sathvika_dinedash_db.sathvika_locations_bronze
SELECT
    location_id,
    area,
    city,
    state,
    latitude,
    longitude,
    _rescued_data,
    ingestion_time,
    source_file_name
FROM dinedash_locations_tmp_view;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_menu_items_bronze (
    item_id STRING,
    restaurant_id STRING,
    item_name STRING,
    price DOUBLE,
    category STRING,
    _rescued_data STRING,
    ingestion_time TIMESTAMP,
    source_file_name STRING
);

-- COMMAND ----------

INSERT INTO sathvika_dinedash_db.sathvika_menu_items_bronze
SELECT
    item_id,
    restaurant_id,
    item_name,
    price,
    category,
    _rescued_data,
    ingestion_time,
    source_file_name
FROM dinedash_menu_items_tmp_view;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_restaurants_bronze (
    restaurant_id STRING,
    name STRING,
    cuisines STRING,
    location_id STRING,
    rating DOUBLE,
    delivery_fee DOUBLE,
    _rescued_data STRING,
    ingestion_time TIMESTAMP,
    source_file_name STRING
);

-- COMMAND ----------

INSERT INTO sathvika_dinedash_db.sathvika_restaurants_bronze
SELECT
    restaurant_id,
    name,
    cuisines,
    location_id,
    rating,
    delivery_fee,
    _rescued_data,
    ingestion_time,
    source_file_name
FROM dinedash_restaurants_tmp_view;

-- COMMAND ----------

DESCRIBE sathvika_dinedash_db.sathvika_customers_bronze;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC FILTERED TABLES

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_customers_filtered
AS
SELECT *
FROM sathvika_dinedash_db.sathvika_customers_bronze
WHERE customer_id IS NOT NULL
  AND location_id IS NOT NULL
  AND signup_date IS NOT NULL
  AND dob IS NOT NULL
  AND email IS NOT NULL
  AND name IS NOT NULL;

-- COMMAND ----------

select * from sathvika_dinedash_db.sathvika_customers_filtered;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_restaurants_filtered
AS
SELECT *
FROM sathvika_dinedash_db.sathvika_restaurants_bronze
WHERE restaurant_id IS NOT NULL
  AND name IS NOT NULL
  AND cuisines IS NOT NULL
  AND location_id IS NOT NULL
  AND rating IS NOT NULL
  AND delivery_fee IS NOT NULL;

-- COMMAND ----------

select * from sathvika_dinedash_db.sathvika_restaurants_filtered;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_locations_filtered
AS
SELECT *
FROM sathvika_dinedash_db.sathvika_locations_bronze
WHERE location_id IS NOT NULL
  AND area IS NOT NULL
  AND city IS NOT NULL
  AND state IS NOT NULL
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

-- COMMAND ----------

select * from sathvika_dinedash_db.sathvika_locations_filtered;

-- COMMAND ----------

CREATE OR REPLACE TABLE sathvika_dinedash_db.sathvika_delivery_agents_filtered
AS
SELECT *
FROM sathvika_dinedash_db.sathvika_delivery_agents_bronze
WHERE agent_id IS NOT NULL
  AND name IS NOT NULL
  AND phone IS NOT NULL
  AND rating IS NOT NULL;

-- COMMAND ----------

select * from sathvika_dinedash_db.sathvika_delivery_agents_filtered;

-- COMMAND ----------

CREATE Or REPLACE TABLE sathvika_dinedash_db.sathvika_menu_items_filtered AS
SELECT * FROM sathvika_dinedash_db.sathvika_menu_items_bronze
WHERE item_id IS NOT NULL
  AND restaurant_id IS NOT NULL
  AND item_name IS NOT NULL
  AND price IS NOT NULL
  AND category IS NOT NULL;

-- COMMAND ----------

select * from sathvika_dinedash_db.sathvika_menu_items_filtered;

-- COMMAND ----------

SELECT
    'customers' AS dataset,
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_customers_bronze) AS bronze_count,
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_customers_filtered) AS filtered_count

UNION ALL

SELECT
    'restaurants',
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_restaurants_bronze),
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_restaurants_filtered)

UNION ALL

SELECT
    'locations',
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_locations_bronze),
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_locations_filtered)

UNION ALL

SELECT
    'delivery_agents',
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_delivery_agents_bronze),
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_delivery_agents_filtered)

UNION ALL

SELECT
    'menu_items',
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_menu_items_bronze),
    (SELECT COUNT(*) 
     FROM sathvika_dinedash_db.sathvika_menu_items_filtered);

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS sathvika_dinedash_db.sathvika_orders_bronze;

-- COMMAND ----------

COPY INTO sathvika_dinedash_db.sathvika_orders_bronze
FROM '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/orders/orders_2024_01.json'
FILEFORMAT = JSON
COPY_OPTIONS ('mergeSchema' = 'true');

-- COMMAND ----------

SELECT COUNT(*) AS record_count
FROM sathvika_dinedash_db.sathvika_orders_bronze;

-- COMMAND ----------

COPY INTO sathvika_dinedash_db.sathvika_orders_bronze
FROM '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/orders/orders_2024_02.json'
FILEFORMAT = JSON
COPY_OPTIONS ('mergeSchema' = 'true');

-- COMMAND ----------

SELECT COUNT(*) AS record_count
FROM sathvika_dinedash_db.sathvika_orders_bronze;

-- COMMAND ----------

COPY INTO sathvika_dinedash_db.sathvika_orders_bronze
FROM '/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/orders/orders_2024_03.json'
FILEFORMAT = JSON
COPY_OPTIONS ('mergeSchema' = 'true');

-- COMMAND ----------

SELECT COUNT(*) AS record_count
FROM sathvika_dinedash_db.sathvika_orders_bronze;