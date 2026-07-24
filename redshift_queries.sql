=========PART — Create Staging Tables (schema matches your actual CSV headers)

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS staging.stg_customers;
CREATE TABLE staging.stg_customers (
    customer_id       INTEGER,
    first_name        VARCHAR(100),
    last_name         VARCHAR(100),
    email             VARCHAR(255),
    phone             VARCHAR(50),
    gender            VARCHAR(10),
    city              VARCHAR(100),
    state             VARCHAR(50),
    country            VARCHAR(50),
    registration_date DATE,
    customer_status    VARCHAR(20)
);

DROP TABLE IF EXISTS staging.stg_orders;
CREATE TABLE staging.stg_orders (
    order_id         INTEGER,
    customer_id      INTEGER,
    order_date       DATE,
    product_id       INTEGER,
    product_category VARCHAR(100),
    quantity         INTEGER,
    unit_price       DECIMAL(10,2),
    discount         DECIMAL(10,2),
    tax              DECIMAL(10,2),
    shipping_cost    DECIMAL(10,2),
    order_amount     DECIMAL(12,2),
    payment_method   VARCHAR(50),
    order_status     VARCHAR(30),
    sales_region     VARCHAR(50)
);

=============PART  — Load Raw Data with COPY

COPY staging.stg_customers
FROM 's3://customer-order-analytics/customers_1000.csv'
IAM_ROLE 'arn:aws:iam::676726973615:role/RedshiftServerlessS3AccessRole'
CSV
IGNOREHEADER 1
EMPTYASNULL
BLANKSASNULL
DATEFORMAT 'YYYY-MM-DD';

COPY staging.stg_orders
FROM 's3://customer-order-analytics/orders_5000.csv'
IAM_ROLE 'arn:aws:iam::676726973615:role/RedshiftServerlessS3AccessRole'
CSV
IGNOREHEADER 1
EMPTYASNULL
BLANKSASNULL
DATEFORMAT 'YYYY-MM-DD';

Verify:

sql
SELECT COUNT(*) FROM staging.stg_customers;  -- expect 1000
SELECT COUNT(*) FROM staging.stg_orders;     -- expect 5000

========PART  — Data Quality / Cleansing Transformations

-- Deduplicated, cleansed, valid customers → dim_customers
DROP TABLE IF EXISTS mart.dim_customers;
CREATE TABLE mart.dim_customers AS
WITH ranked AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        COALESCE(NULLIF(TRIM(email), ''), 'unknown@example.com')  AS email,
        phone,
        gender,
        city,
        COALESCE(NULLIF(TRIM(state), ''), 'UNKNOWN')               AS state,
        country,
        registration_date,
        customer_status,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY registration_date DESC NULLS LAST
        ) AS rn
    FROM staging.stg_customers
    WHERE customer_id IS NOT NULL
      AND customer_id > 0          -- excludes the one negative/invalid id
)
SELECT
    customer_id, first_name, last_name, email, phone, gender,
    city, state, country, registration_date, customer_status
FROM ranked
WHERE rn = 1;                      -- one row per customer_id (dedup rule)

-- Deduplicated, cleansed orders → fact_orders
DROP TABLE IF EXISTS mart.fact_orders;
CREATE TABLE mart.fact_orders AS
WITH ranked AS (
    SELECT
        order_id, customer_id, order_date, product_id, product_category,
        quantity, unit_price, discount, tax, shipping_cost,
        COALESCE(order_amount, 0) AS order_amount,
        payment_method, order_status, sales_region,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_date DESC NULLS LAST
        ) AS rn
    FROM staging.stg_orders
)
SELECT
    order_id, customer_id, order_date, product_id, product_category,
    quantity, unit_price, discount, tax, shipping_cost, order_amount,
    payment_method, order_status, sales_region
FROM ranked
WHERE rn = 1;                      -- one row per order_id (dedup rule)

-- Row counts to quote in your write-up
SELECT 'stg_customers' AS tbl, COUNT(*) FROM staging.stg_customers
UNION ALL SELECT 'dim_customers', COUNT(*) FROM mart.dim_customers
UNION ALL SELECT 'stg_orders', COUNT(*) FROM staging.stg_orders
UNION ALL SELECT 'fact_orders', COUNT(*) FROM mart.fact_orders;

===========PART — Customer Aggregate Metrics Table

DROP TABLE IF EXISTS mart.customer_metrics;
CREATE TABLE mart.customer_metrics AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.state,
    COUNT(f.order_id)                              AS total_orders,
    COALESCE(SUM(f.order_amount), 0)                AS total_sales,
    COALESCE(ROUND(AVG(NULLIF(f.order_amount,0)),2),0) AS average_order_value
FROM mart.dim_customers c
LEFT JOIN mart.fact_orders f
    ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.state;
