# Corporate Actions Data Warehouse and Analytics Project

Welcome to the **Corporate Actions Data Warehouse and Analytics Project** repository!
This project demonstrates the design and implementation of an end-to-end SQL-based data warehouse for corporate actions. It transforms raw financial datasets into clean, integrated, and analytics-ready data models, enabling meaningful insights and business reporting.

---

## Project Overview
Corporate actions (such as dividends, stock splits, and mergers) are critical financial events that impact securities and investors. This project simulates a real-world data engineering and analytics pipeline to:
- Consolidate data from multiple financial sources
- Track the lifecycle of corporate actions
- Enable historical analysis and reporting
- Deliver business-ready insights using SQL

## Architecture
The project follows a Medallion Architecture (Bronze → Silver → Gold):

- Bronze Layer: Raw data ingestion from source CSV files
- Silver Layer: Data cleansing, standardization, and transformation
- Gold Layer: Business-ready fact and dimension tables for analytics

This layered approach ensures data quality, scalability, and maintainability.

## Requirements

### Building the Data Warehouse (Data Engineering)

#### Objective
Design and build a data warehouse using SQL server to consolidate corporate actions data, making it reliable and ready for analytics.

#### Specifications
- **Data Sources**: Import data from multiple source systems (Corporate Actions, Companies, Securities, Event types, Dividends, Splits and Mergers) provided as CSV files.
- **Data Quality**: cleanse and resolve data quality issues prior to analysis.
- **Integration**: Combine data from multiple sources into a unified, structured, and analytics-ready data model for querying and reporting.
- **Scope**: Design an end-to-end data warehouse for corporate actions using a Bronze-Silver-Gold architecture, supporting lifecycle tracking and historical analysis.
- **Documentation**: Provide clear documentation of the data model, data sources, and transformations to support both business stakeholders and analytics teams.

---

## BI: Analytics & Reporting (Data Analytics)

#### Objective
Develop SQL-based analytics on corporate actions data to generate actionable insights and support business decision-making.
- **Corporate Actions Behavior**
- **Dividend Trends Over Time**
- **Sector-wise Corporate Actions Comparison**

---

## License

This project is licensed under the [MIT License](LICENSE). you are free to use, modify, and share this project with proper attribution.

## About Me

Hi there! I'm **Saikiran Gunturu**, I have over 10 years experience in financial data analysis, corporate actions & ownership structures, M&A data analysis, business research and data validation.

This project reflects my expertise in combining financial domain knowledge with data engineering and analytics.
