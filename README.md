# Olist Marketplace Performance Analysis

An end-to-end data analysis project on the Olist Brazilian e-commerce marketplace using PostgreSQL, Python, and Tableau-ready exports.

## Overview

The goal of this project is to analyze marketplace performance across sales, customers, sellers, delivery operations, and customer satisfaction, and convert the findings into actionable business recommendations.

### Project Objective

This project answers the question:

> **How can Olist improve marketplace growth, customer retention, and delivery performance using transaction, payment, product, seller, and review data?**

The analysis is designed as a real business case study rather than a simple academic EDA exercise. It follows a full workflow:

- Ingest raw data into SQL
- Validate data quality and referential integrity
- Build analytical views and marts
- Perform KPI and business analysis
- Conduct Python EDA and insight generation
- Prepare Tableau-ready dashboard datasets

## Dataset

**Source:** Brazilian E-Commerce Public Dataset by Olist from Kaggle

The dataset includes information on orders, items, payments, reviews, customers, sellers, products, category translations, and geolocation. The business time window spans **2016-09-04 to 2018-10-17**.

> **Note:** Raw source files are not stored in this repository. Download the dataset from Kaggle and place the CSV files in `data/raw/`.

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| **PostgreSQL** | SQL Database |
| **Python** | Pandas, Numpy, Matplotlib, Jupyter |
| **Tableau** | Tableau-ready CSV exports |
| **Git + GitHub** | Version Control |

## Project Workflow

### Phase 1 — Dataset Intake and Audit

- Profiled all tables and documented table grain, keys, and joins
- Created a data dictionary and KPI definitions

### Phase 2 — PostgreSQL Setup and Data Loading

- Created PostgreSQL database and schemas
- Loaded raw CSVs and validated row counts

### Phase 3 — Data Quality Checks

- Verified null behavior and tested composite keys
- Validated date logic and business-safe modeling rules

### Phase 4 — KPI SQL and Analytical Marts

Built reusable analytical views including:

- `v_orders_enriched`
- `v_customer_summary`
- `v_category_performance`
- `v_seller_performance`
- `v_state_performance`

### Phase 5 — Python EDA

- Analyzed monthly GPV trends and repeat customer behavior
- Correlated delivery timeliness with review scores

### Phase 6 — Tableau Preparation

Curated specific exports for dashboarding:

- `executive_monthly_kpis.csv`
- `customer_summary.csv`
- `delivery_experience_summary.csv`

## Repository Structure

```
olist-marketplace-analysis/
├── data/
│   ├── raw/                 # raw Kaggle files (not committed)
├── sql/
│   ├── 01_create_schema.sql
│   ├── 02_create_tables.sql
├── notebooks/
│   ├── 01_data_audit.ipynb
│   └── 02_eda.ipynb
├── docs/
│   ├── project_brief.md
│   ├── data_dictionary.md
│   └── kpi_definitions.md
├── tableau_exports/         # Cleaned CSVs for BI tools
└── README.md
```

## Data Modeling Notes

| Concept | Details |
|---------|---------|
| **Customer Logic** | `customer_unique_id` is used for repeat-customer analysis, while `order_id` is the base grain for KPIs |
| **Aggregation** | `order_payments` were aggregated to the order level before joining with items to avoid data duplication |
| **Categories** | Used translated product categories with fallbacks for missing values |

## Key Findings

### Strong Top-Line Performance

- **97.02%** delivery rate with a low cancellation rate (**0.63%**)
- **Total GPV:** ~**$15.42M**

### Weak Retention

- Repeat customers account for only **3.12%** of the base
- Olist is currently **acquisition-led**

### Delivery Impact

- **On-time orders:** average **4.29** review score
- **Late orders:** average **2.57** review score

### Category Concentration

Revenue is driven by **health_beauty**, **watches_gifts**, and **bed_bath_table**

### Operational Gaps

**office_furniture** shows high revenue but consistently low review scores

## Business Recommendations

### Improve Retention

Implement loyalty programs and post-purchase remarketing

### Logistics Optimization

Tighten seller SLAs, especially in lagging states like **BA**

### Category Quality Control

Investigate fulfillment issues in high-value/low-rating categories like **office furniture**

## How to Run This Project

### Clone the Repo

```bash
git clone https://github.com/Dhanush3620/olist-marketplace-analysis.git
```

### Environment Setup

```bash
pip install -r requirements.txt
```

### Data Placement

Place Kaggle CSVs in `data/raw/`

### Database

Run SQL scripts **01 through 09** in order in your PostgreSQL instance

### Analysis

Execute Jupyter notebooks in the `notebooks/` folder

## Current Status & Future Improvements

### Completed

- SQL Ingestion
- Data Quality
- KPI Marts
- Python EDA

### Next Steps

- Build interactive Tableau dashboards
- Add Cohort Analysis and RFM Segmentation
- Add predictive forecasting for GPV

## Author

**Dhanush Garikapati**

- M.S. in Data Science, University of Maryland
- Specializing in Data Analysis, BI, and SQL