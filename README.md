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

<img width="1176" height="627" alt="image" src="https://github.com/user-attachments/assets/c86179b0-3eeb-400a-a92b-5871fdf01a8c" />


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

**Notion Documentation**

https://flawless-colby-098.notion.site/SQL-Corporate-Actions-Data-Warehouse-Project-3580b1ba682080739c4df23c8122bea1

## BI: Analytics & Reporting (Data Analytics)

#### Objective
Develop SQL-based analytics on corporate actions data to generate actionable insights and support business decision-making.
- **Corporate Actions Summary**
- **Dividend Trends Over Time**
- **Dividends, Split Ratio and Mergers Distribution**

**Power BI Dashboards**

**Corporate Actions Summary Dashboard**

<img width="898" height="504" alt="image" src="https://github.com/user-attachments/assets/e3c7c48d-115c-499f-945d-fb9c17780058" />

**Dividend Analysis**

<img width="771" height="437" alt="image" src="https://github.com/user-attachments/assets/4a3e9142-10ba-4303-bcff-ac07650c949d" />

**Split Analysis**

<img width="771" height="446" alt="image" src="https://github.com/user-attachments/assets/156e3f93-dd48-4758-9177-783452ea75d9" />

**Merger Analysis**

<img width="773" height="436" alt="image" src="https://github.com/user-attachments/assets/56aef149-c07d-4cc5-aef3-bfd3465f91dd" />

**Data Quality Summary**

<img width="773" height="436" alt="image" src="https://github.com/user-attachments/assets/e756a994-df96-4288-b261-45969512c41e" />

***Power BI Report:***

https://app.powerbi.com/groups/4d035023-cb6e-4ee3-a744-9dae630dc3d1/reports/726b30a3-1db8-43b3-9196-324a5dbfa60d/6015e9738fd9f235f5e3?experience=power-bi

---

## License

This project is licensed under the [MIT License](LICENSE). you are free to use, modify, and share this project with proper attribution.

## About Me

Hi there! I'm **Saikiran Gunturu**, I have over 10 years experience in financial data analysis, corporate actions & ownership structures, M&A data analysis, business research and data validation.

This project reflects my expertise in combining financial domain knowledge with data engineering and analytics.
