STEP 1: CREATE SCHEMAS
-- =========================================================
-- STEP 1: CREATE SCHEMAS
-- =========================================================

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

STEP 2: CREATE STAGING TABLES

The staging tables store the data loaded directly from S3.
-- =========================================================
-- STEP 2: CREATE STAGING TABLES
-- =========================================================
-- -------------------------
-- STAGING CUSTOMERS
-- -------------------------

DROP TABLE IF EXISTS staging.stg_customers;

CREATE TABLE staging.stg_customers (
    customer_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(50),
    gender VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    registration_date DATE,
    customer_status VARCHAR(50)
);

-- -------------------------
-- STAGING ORDERS
-- -------------------------

DROP TABLE IF EXISTS staging.stg_orders;

CREATE TABLE staging.stg_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    product_id INT,
    product_category VARCHAR(100),
    quantity INT,
    unit_price DECIMAL(12,2),
    discount DECIMAL(12,2),
    tax DECIMAL(12,2),
    shipping_cost DECIMAL(12,2),
    order_amount DECIMAL(12,2),
    payment_method VARCHAR(50),
    order_status VARCHAR(50),
    sales_region VARCHAR(100)
);


STEP 3: LOAD RAW DATA FROM S3
-- =========================================================
-- STEP 3: LOAD DATA FROM S3 INTO STAGING TABLES
-- =========================================================

-- -------------------------
-- LOAD CUSTOMERS
-- -------------------------

COPY staging.stg_customers
FROM 's3://customer-order-analytics/customers_1000.csv'
IAM_ROLE 'arn:aws:iam::676726973615:role/RedshiftServerlessS3AccessRole'
CSV
IGNOREHEADER 1
REGION 'ap-south-1';


-- -------------------------
-- LOAD ORDERS
-- -------------------------

COPY staging.stg_orders
FROM 's3://customer-order-analytics/orders_5000.csv'
IAM_ROLE 'arn:aws:iam::676726973615:role/RedshiftServerlessS3AccessRole'
CSV
IGNOREHEADER 1
REGION 'ap-south-1';

STEP 4: VALIDATE STAGING DATA
-- =========================================================
-- STEP 4: VALIDATE STAGING DATA
-- =========================================================

-- Check sample orders
SELECT *
FROM staging.stg_orders
LIMIT 10;


-- Check total customer records
SELECT COUNT(*) AS total_customer_rows
FROM staging.stg_customers;


-- Check total order records
SELECT COUNT(*) AS total_order_rows
FROM staging.stg_orders;


-- Check recent load history
SELECT *
FROM sys_load_history
ORDER BY start_time DESC
LIMIT 5;

STEP 5: DATA QUALITY CHECKS
5.1 Duplicate Customers
-- =========================================================
-- STEP 5.1: CHECK DUPLICATE CUSTOMERS
-- =========================================================

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM staging.stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

5.2 Missing Emails
-- =========================================================
-- STEP 5.2: CHECK MISSING EMAILS
-- =========================================================
SELECT
    COUNT(*) AS missing_email_count
FROM staging.stg_customers
WHERE email IS NULL
   OR TRIM(email) = '';

5.3 Missing States
-- =========================================================
-- STEP 5.3: CHECK MISSING STATES
-- =========================================================

SELECT
    COUNT(*) AS missing_state_count
FROM staging.stg_customers
WHERE state IS NULL
   OR TRIM(state) = '';


5.4 Duplicate Orders
-- =========================================================
-- STEP 5.4: CHECK DUPLICATE ORDERS
-- =========================================================

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM staging.stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

5.5 Missing Order Amount
-- =========================================================
-- STEP 5.5: CHECK MISSING ORDER AMOUNT
-- =========================================================

SELECT
    COUNT(*) AS missing_order_amount_count
FROM staging.stg_orders
WHERE order_amount IS NULL;
STEP 6: CREATE CLEANED CUSTOMER TABLE

This table:
Removes duplicate customers using customer_id
Keeps one record per customer
Replaces missing email with unknown@example.com
Replaces missing state with UNKNOWN
-- =========================================================
-- STEP 6: CREATE CLEANED CUSTOMER TABLE
-- =========================================================

DROP TABLE IF EXISTS mart.cleaned_customers;

CREATE TABLE mart.cleaned_customers AS

SELECT
    customer_id,
    first_name,
    last_name,

    -- Replace missing email
    COALESCE(
        NULLIF(TRIM(email), ''),
        'unknown@example.com'
    ) AS email,

    phone,
    gender,
    city,

    -- Replace missing state
    COALESCE(
        NULLIF(TRIM(state), ''),
        'UNKNOWN'
    ) AS state,

    country,
    registration_date,
    customer_status

FROM (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        gender,
        city,
        state,
        country,
        registration_date,
        customer_status,

        -- Remove duplicate customers
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY customer_id
        ) AS rn

    FROM staging.stg_customers
) c
WHERE rn = 1;

STEP 7: VALIDATE CLEANED CUSTOMERS
-- =========================================================
-- STEP 7: VALIDATE CLEANED CUSTOMERS
-- =========================================================

-- Total cleaned customers
SELECT COUNT(*) AS total_cleaned_customers
FROM mart.cleaned_customers;


-- Check duplicate customers after cleansing
-- Expected result: No rows

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM mart.cleaned_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


STEP 8: CREATE CLEANED ORDERS TABLE

This table:
Removes duplicate orders using order_id
Keeps one record per order
Replaces missing order_amount with 0
-- =========================================================
-- STEP 8: CREATE CLEANED ORDERS TABLE
-- =========================================================

DROP TABLE IF EXISTS mart.cleaned_orders;

CREATE TABLE mart.cleaned_orders AS

SELECT
    order_id,
    customer_id,
    order_date,
    product_id,
    product_category,
    quantity,
    unit_price,
    discount,
    tax,
    shipping_cost,

    -- Replace missing order amount with 0
    COALESCE(order_amount, 0) AS order_amount,

    payment_method,
    order_status,
    sales_region

FROM (
    SELECT
        order_id,
        customer_id,
        order_date,
        product_id,
        product_category,
        quantity,
        unit_price,
        discount,
        tax,
        shipping_cost,
        order_amount,
        payment_method,
        order_status,
        sales_region,

        -- Remove duplicate orders
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_date
        ) AS rn

    FROM staging.stg_orders
) o

WHERE rn = 1;


STEP 9: VALIDATE CLEANED ORDERS
-- =========================================================
-- STEP 9: VALIDATE CLEANED ORDERS
-- =========================================================

-- Total cleaned orders
SELECT COUNT(*) AS total_cleaned_orders
FROM mart.cleaned_orders;


-- Check duplicate orders after cleansing
-- Expected result: No rows

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM mart.cleaned_orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Check zero-amount orders after cleansing

SELECT
    COUNT(*) AS zero_amount_orders
FROM mart.cleaned_orders
WHERE order_amount = 0;

STEP 10: EXACT DUPLICATE ORDER REPORT
This checks exact duplicate records in the original staging data.

-- =========================================================
-- STEP 10: EXACT DUPLICATE ORDER REPORT
-- =========================================================

SELECT
    order_id,
    customer_id,
    order_date,
    product_id,
    product_category,
    quantity,
    unit_price,
    discount,
    tax,
    shipping_cost,
    order_amount,
    payment_method,
    order_status,
    sales_region,
    COUNT(*) AS duplicate_count

FROM staging.stg_orders

GROUP BY
    order_id,
    customer_id,
    order_date,
    product_id,
    product_category,
    quantity,
    unit_price,
    discount,
    tax,
    shipping_cost,
    order_amount,
    payment_method,
    order_status,
    sales_region

HAVING COUNT(*) > 1;

STEP 11: CREATE CUSTOMER METRICS TABLE
This is your final analytical table.
It creates:
total_orders
total_sales
average_order_value
per customer.

-- =========================================================
-- STEP 11: CREATE CUSTOMER METRICS TABLE
-- =========================================================

DROP TABLE IF EXISTS mart.customer_metrics;

CREATE TABLE mart.customer_metrics AS

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.state,

    -- Total number of orders
    COUNT(o.order_id) AS total_orders,

    -- Total revenue
    COALESCE(
        SUM(o.order_amount),
        0
    ) AS total_sales,

    -- Average order value
    COALESCE(
        ROUND(AVG(o.order_amount), 2),
        0
    ) AS average_order_value

FROM mart.cleaned_customers c

LEFT JOIN mart.cleaned_orders o
    ON c.customer_id = o.customer_id

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.state;

    
STEP 12: VALIDATE CUSTOMER METRICS
-- =========================================================
-- STEP 12: VALIDATE CUSTOMER METRICS
-- =========================================================

-- View sample customer metrics
SELECT *
FROM mart.customer_metrics
LIMIT 10;
-- Check total customer metrics records
SELECT COUNT(*) AS total_customers
FROM mart.customer_metrics;
