# Amazon Redshift Customer Orders Analytics

## End-to-End ETL and Business Analytics Pipeline using Amazon S3 and Amazon Redshift Serverless

---

## Project Overview

This project demonstrates an end-to-end ETL and data analytics pipeline built using Amazon S3 and Amazon Redshift Serverless.

A retail company receives customer and order data in CSV format. The raw datasets contain data quality issues such as duplicate customer records, duplicate order records, missing email values, missing state values, and missing order amounts.

The pipeline ingests raw CSV files from Amazon S3 into Amazon Redshift staging tables, performs data quality validation, cleans and transforms the data, applies business rules, and creates analytics-ready tables.

The final customer metrics table provides customer-level business metrics such as Total Orders, Total Sales, and Average Order Value.

The processed data is then used to generate business insights and analytical dashboards.

---

## Technologies Used

- Amazon S3
- Amazon Redshift Serverless
- AWS IAM
- SQL
- Redshift Query Editor v2
- GitHub

---

## Project Architecture
<h2>Project Architecture</h2>

<table>
<tr>
<td align="center">

<b>Raw CSV Files</b><br><br>
📄 customers_1000.csv<br>
📄 orders_5000.csv

</td>
</tr>

<tr>
<td align="center">⬇️</td>
</tr>

<tr>
<td align="center">

<b>Amazon S3</b><br>
Raw Data Storage

</td>
</tr>

<tr>
<td align="center">⬇️<br><b>Redshift COPY Command</b></td>
</tr>

<tr>
<td align="center">

<b>Bronze Layer – Staging</b><br><br>
📊 staging.stg_customers<br>
📊 staging.stg_orders

</td>
</tr>

<tr>
<td align="center">⬇️</td>
</tr>

<tr>
<td align="center">

<b>Data Quality Checks</b><br><br>
✔ Duplicate Customer Detection<br>
✔ Duplicate Order Detection<br>
✔ Missing Email Detection<br>
✔ Missing State Detection<br>
✔ Missing Order Amount Detection

</td>
</tr>

<tr>
<td align="center">⬇️</td>
</tr>

<tr>
<td align="center">

<b>Silver Layer – Cleaned Data</b><br><br>
📊 mart.cleaned_customers<br>
📊 mart.cleaned_orders

</td>
</tr>

<tr>
<td align="center">⬇️</td>
</tr>

<tr>
<td align="center">

<b>Gold Layer – Customer Metrics</b><br><br>
📊 mart.customer_metrics<br><br>
• Total Orders<br>
• Total Sales<br>
• Average Order Value

</td>
</tr>

<tr>
<td align="center">⬇️</td>
</tr>

<tr>
<td align="center">

<b>Business Analytics</b><br><br>
📈 Top 10 Customers by Revenue<br>
📊 Revenue by State<br>
📊 Average Order Value by Customer<br>
📧 Customers with No Valid Email<br>
📈 Monthly Sales Trend<br>
🔍 Duplicate Detection Report<br>
💰 Orders with Zero Amount

</td>
</tr>

<tr>
<td align="center">⬇️</td>
</tr>

<tr>
<td align="center">

<b>Dashboards</b><br><br>
📊 Business Insights & Data Visualization

</td>
</tr>

</table>

## Dataset

The project uses two CSV files stored in Amazon S3.

### Customers Dataset

File: customers_1000.csv

The customer dataset contains information about customers, including:

- Customer ID
- First Name
- Last Name
- Email
- Phone
- Gender
- City
- State
- Country
- Registration Date
- Customer Status

### Orders Dataset

File: orders_5000.csv

The orders dataset contains information about customer orders, including:

- Order ID
- Customer ID
- Order Date
- Product ID
- Product Category
- Quantity
- Unit Price
- Discount
- Tax
- Shipping Cost
- Order Amount
- Payment Method
- Order Status
- Sales Region

---

## ETL Pipeline

### Step 1 – Data Ingestion

The customer and order CSV files are uploaded to an Amazon S3 bucket.

The raw data is loaded from Amazon S3 into Amazon Redshift Serverless using the Redshift COPY command.

The S3 data is initially stored in staging tables for further validation and transformation.

---

## Step 2 – Bronze Layer – Staging

The Bronze layer contains the raw data loaded from Amazon S3.

### Staging Tables

- staging.stg_customers
- staging.stg_orders

The staging layer is used for:

- Raw data ingestion
- Data quality validation
- Duplicate detection
- Missing value identification
- Initial data analysis

The raw data is not directly used for business reporting. It is first checked for data quality issues and then transformed into cleaned tables.

---

## Step 3 – Data Quality Checks

Data quality checks are performed on the staging tables before applying transformations.

The following data quality issues are identified:

### Duplicate Customer Records

Customer records are checked using customer_id to identify duplicate customers.

### Duplicate Order Records

Order records are checked using order_id to identify duplicate orders.

### Missing Email Values

Customer records are checked for NULL or blank email values.

### Missing State Values

Customer records are checked for NULL or blank state values.

### Missing Order Amount

Order records are checked for NULL order_amount values.

These checks help identify the quality issues present in the raw datasets before cleansing.

---

## Step 4 – Silver Layer – Data Cleaning

The raw staging data is cleaned and transformed to create analytics-ready datasets.

### Cleaned Tables

- mart.cleaned_customers
- mart.cleaned_orders

### Customer Data Cleaning

The following transformations are applied to customer data:

- Duplicate customer records are removed using customer_id.
- Only one customer record is retained for each customer_id.
- Missing email values are replaced with unknown@example.com.
- Missing state values are replaced with UNKNOWN.
- Blank text values are handled using SQL functions.
- ROW_NUMBER() is used for customer-level deduplication.

### Order Data Cleaning

The following transformations are applied to order data:

- Duplicate order records are removed using order_id.
- Only one record is retained for each order_id.
- Missing order_amount values are replaced with 0.
- Duplicate records are identified using ROW_NUMBER().
- Cleaned order data is prepared for analytics.

---

## Step 5 – Gold Layer – Customer Metrics

The Gold layer contains the final customer-level analytical metrics.

### Final Analytical Table

mart.customer_metrics

The customer metrics table is created by combining customer and order information and calculating customer-level business metrics.

### Metrics Created

Total Orders

The total number of orders placed by each customer.

Total Sales

The total revenue generated by each customer.

Average Order Value

The average order amount for each customer.

The final customer metrics table contains:

- Customer ID
- First Name
- Last Name
- State
- Total Orders
- Total Sales
- Average Order Value

The customer_metrics table is the primary source for customer-level business analysis and dashboard visualizations.

---

## Business Rules

The following business rules are implemented:

- One customer record per customer_id.
- One order record per order_id.
- Duplicate customer records are removed.
- Duplicate order records are removed.
- Missing email values are replaced with unknown@example.com.
- Missing state values are replaced with UNKNOWN.
- Missing order_amount values are replaced with 0.
- Revenue is calculated using the total order amount.
- Average Order Value is calculated using the average order amount.
- Customers are ranked based on total revenue.
- Cleaned data is used for business reporting and analytics.

---

## Business Insights

The project generates seven key business insights.

### 1. Top 10 Customers by Revenue

Identifies the top 10 customers based on total sales or revenue.

The analysis uses the customer_metrics table and ranks customers based on total_sales.

This helps the business identify its highest-value customers.

---

### 2. Revenue by State

Analyzes total revenue generated across different customer states.

This helps identify which states contribute the highest revenue to the business.

Example results from the analysis:

- TX – 527,844.20
- NY – 527,272.87
- UNKNOWN – 520,528.25
- CA – 487,534.28

---

### 3. Average Order Value by Customer

Calculates the average order value for each customer.

This helps identify customers who make higher-value purchases.

The analysis uses the average_order_value metric from the customer_metrics table.

---

### 4. Customers with No Valid Email

Identifies customers whose email information is missing or invalid.

Missing email values are replaced with:

unknown@example.com

The analysis helps identify customers whose contact information may need to be updated.

---

### 5. Monthly Sales Trend

Analyzes sales and revenue performance across different months.

The analysis provides:

- Monthly Revenue
- Number of Orders

This helps identify sales patterns and changes in business performance over time.

The dataset returned 17 monthly sales periods during the analysis.

---

### 6. Duplicate Detection Report

Identifies duplicate records from the original staging data before cleansing.

The report analyzes:

- Duplicate customer records
- Duplicate order records

The analysis identified 145 duplicate order IDs in the raw order dataset.

This demonstrates the importance of data quality validation before creating analytical tables.

---

### 7. Orders with Zero Amount After Cleansing

Identifies orders where the original order_amount was missing and was replaced with 0 during the cleansing process.

The analysis identified 246 zero-amount orders after cleansing.

This allows the business to monitor orders that may require further investigation.

---

## Dashboard Visualizations

The analytical results are used to create visualizations and dashboards.

The dashboard includes:

- Top 10 Customers by Revenue
- Revenue by State
- Average Order Value by Customer
- Customers with No Valid Email
- Monthly Sales Trend
- Duplicate Detection Report
- Orders with Zero Amount After Cleansing

These visualizations provide business insights into:

- Customer revenue contribution
- Geographic revenue performance
- Customer purchasing behavior
- Monthly sales performance
- Data quality issues
- Duplicate records
- Missing and zero-value orders

The Gold layer customer_metrics table is used as the primary source for customer-level dashboard analysis.

---

## Key Results

The ETL pipeline successfully identified and processed several data quality issues.

Key results from the analysis include:

- Customers without valid email: 41
- Duplicate order IDs: 145
- Zero-amount orders after cleansing: 246
- Monthly sales periods: 17
- Unique customers after deduplication: 961

The revenue-by-state analysis showed that TX generated the highest revenue, followed closely by NY.

The customer-level metrics analysis was used to identify top customers based on revenue and compare customer purchasing behavior using total orders and average order value.

---

## SQL Concepts Used

The following SQL concepts were implemented in the project:

- CREATE SCHEMA
- CREATE TABLE
- COPY
- SELECT
- WHERE
- COALESCE
- NULLIF
- TRIM
- ROW_NUMBER()
- PARTITION BY
- GROUP BY
- HAVING
- LEFT JOIN
- COUNT()
- SUM()
- AVG()
- ORDER BY
- LIMIT
- DATE_TRUNC()

---

## Project Outcome

Successfully built an end-to-end ETL and analytics pipeline using Amazon S3 and Amazon Redshift Serverless.

The project demonstrates the complete data flow from raw data ingestion to business analytics.

The pipeline successfully:

- Loaded raw customer data from Amazon S3.
- Loaded raw order data from Amazon S3.
- Created Redshift staging tables.
- Performed data quality validation.
- Identified duplicate customer records.
- Identified duplicate order records.
- Handled missing email values.
- Handled missing state values.
- Handled missing order amounts.
- Removed duplicate customer records.
- Removed duplicate order records.
- Created cleaned customer and order datasets.
- Created a customer-level metrics table.
- Calculated total orders.
- Calculated total sales.
- Calculated average order value.
- Generated seven business insights.
- Created analytical charts and dashboards.
- Prepared analytics-ready data for business reporting.

---

## Learning Outcomes

Through this project, the following concepts were implemented and practiced:

- Amazon S3 Integration
- Amazon Redshift Serverless
- Redshift COPY Command
- AWS IAM Role Integration
- End-to-End ETL Pipeline
- Staging and Data Mart Architecture
- Bronze, Silver, and Gold Layer Concepts
- Data Quality Validation
- Duplicate Detection and Removal
- NULL and Missing Value Handling
- SQL Data Cleansing
- SQL Window Functions
- ROW_NUMBER() for Deduplication
- SQL Aggregate Functions
- SQL Joins
- Customer-Level Data Aggregation
- Business Rule Implementation
- Business Analytics using SQL
- Data Visualization
- GitHub Version Control

---

## Files Included

- project01.sql
- customers_1000.csv
- orders_5000.csv
- README.md

---

## Future Enhancements

The following improvements can be implemented in future versions of the project:

- Automate the ETL pipeline using AWS Glue or Apache Airflow.
- Implement incremental data loading and Change Data Capture (CDC).
- Optimize Redshift tables using Sort Keys and Distribution Styles.
- Add ETL logging and error handling.
- Monitor ETL execution using Amazon CloudWatch.
- Create interactive dashboards using Amazon QuickSight or Power BI.
- Schedule automated ETL workflows.
- Implement automated data quality monitoring.
- Add data auditing and validation.
- Implement CI/CD for SQL and ETL scripts.
- Add automated testing for data transformations.
- Integrate AWS Lambda for event-driven data processing.

---

## Author

Tadem Madhuri

B.Tech – Computer Science (AI & ML Specialization)

Data Engineering | Amazon Redshift Serverless | Amazon S3 | SQL | AWS | ETL | GitHub
