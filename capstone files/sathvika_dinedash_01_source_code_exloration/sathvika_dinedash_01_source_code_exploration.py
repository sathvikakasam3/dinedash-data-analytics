# Databricks notebook source
orders_path = "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/orders/"

# COMMAND ----------

orders_df = spark.read.json(orders_path)

orders_df.printSchema()
display(orders_df.limit(10))

# COMMAND ----------

orders_df.count()

# COMMAND ----------

orders_jan = spark.read.json(
    "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/orders/orders_2024_01.json"
)

orders_feb = spark.read.json(
    "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/orders/orders_2024_02.json"
)

print("January records:", orders_jan.count())
print("February records:", orders_feb.count())

# COMMAND ----------

customers_path = "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/customers/dim_customers.csv"

customers_df = spark.read.option("header", "true").option("inferSchema", "true").csv(customers_path)

customers_df.printSchema()

display(customers_df)

print("Customers records:", customers_df.count())

# COMMAND ----------

agents_path = "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/delivery_agents/dim_delivery_agents.csv"

agents_df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv(agents_path)
)

agents_df.printSchema()
display(agents_df)

print("Delivery agent records:", agents_df.count())

# COMMAND ----------

locations_path = "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/locations/dim_locations.csv"

locations_df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv(locations_path)
)

locations_df.printSchema()
display(locations_df)

print("Location records:", locations_df.count())

# COMMAND ----------

menu_path = "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/menu_items/dim_menu_items.csv"

menu_df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv(menu_path)
)

menu_df.printSchema()
display(menu_df)

print("Menu item records:", menu_df.count())

# COMMAND ----------

restaurants_path = "/Volumes/sathvika_databricks_workspace_7405616609696478/sathvika_dinedash_db/sathvika_dinedash_volume/restaurants/dim_restaurants.csv"

restaurants_df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv(restaurants_path)
)

restaurants_df.printSchema()
display(restaurants_df)

print("Restaurant records:", restaurants_df.count())