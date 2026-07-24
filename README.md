# redshift-data-analysis
# Amazon Redshift Customer Orders Analytics

## 📌 Project Overview

This project implements a cloud-based ETL and analytics pipeline using **Amazon S3** and **Amazon Redshift Serverless** to process customer and order data.

The project simulates a retail company's data warehouse workflow where raw CSV files contain data quality issues such as duplicate customer records, duplicate orders, missing email addresses, missing states, and missing order amounts.

The pipeline ingests raw data from Amazon S3 into Amazon Redshift staging tables, performs data cleansing and deduplication, creates curated analytical tables, and generates business insights using SQL-based analytics.

The final solution provides customer-level metrics such as:

- Total Orders
- Total Sales / Revenue
- Average Order Value

These metrics are used to support business analysis and dashboard visualizations.

---

## 🎯 Business Problem

A retail company receives customer and order data in CSV format.

The incoming data contains several data quality issues:

- Duplicate customer records
- Duplicate order records
- Missing email values
- Missing state values
- Missing order amounts
- Inconsistent or incomplete data

The objective is to build an ETL pipeline that:

1. Ingests raw customer and order data from Amazon S3.
2. Loads the data into Amazon Redshift staging tables.
3. Identifies data quality issues.
4. Removes duplicate customers and orders.
5. Handles missing and invalid values.
6. Creates cleaned and curated tables.
7. Generates customer-level business metrics.
8. Produces analytical insights for business decision-making.

---

## 🏗️ Architecture

```text
                    ┌──────────────────────┐
                    │      CSV Files       │
                    │                      │
                    │  customers_1000.csv  │
                    │   orders_5000.csv    │
                    └──────────┬───────────┘
                               │
                               │ Upload
                               ▼
                    ┌──────────────────────┐
                    │      Amazon S3       │
                    │                      │
                    │   Raw Data Storage   │
                    └──────────┬───────────┘
                               │
                               │ COPY Command
                               ▼
              ┌──────────────────────────────────┐
              │      Amazon Redshift Serverless  │
              │                                  │
              │          STAGING LAYER            │
              │                                  │
              │  staging.stg_customers           │
              │  staging.stg_orders              │
              └────────────────┬─────────────────┘
                               │
                               │ Data Quality Checks
                               │ Deduplication
                               │ Missing Value Handling
                               ▼
              ┌──────────────────────────────────┐
              │          CLEANED LAYER            │
              │                                  │
              │  mart.cleaned_customers          │
              │  mart.cleaned_orders             │
              └────────────────┬─────────────────┘
                               │
                               │ Aggregation
                               ▼
              ┌──────────────────────────────────┐
              │        ANALYTICS LAYER            │
              │                                  │
              │  mart.customer_metrics           │
              │                                  │
              │  • total_orders                  │
              │  • total_sales                   │
              │  • average_order_value           │
              └────────────────┬─────────────────┘
                               │
                               ▼
              ┌──────────────────────────────────┐
              │      Business Insights           │
              │                                  │
              │  • Top 10 Customers by Revenue   │
              │  • Revenue by State              │
              │  • Average Order Value           │
              │  • Email Quality Analysis        │
              │  • Monthly Sales Trend            │
              │  • Duplicate Detection           │
              │  • Zero Amount Orders            │
              └──────────────────────────────────┘
