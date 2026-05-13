# Data Catalog for Corporate Actions Gold Layer

## Overview
The Gold Layer is the final business-ready layer of the Corporate Actions Data Warehouse. It is designed for analytical reporting, Power BI dashboards, KPI tracking, lifecycle monitoring, and data quality checks.

The Gold Layer follows a star schema model with one central fact table and multiple dimension tables.

---

## Gold Layer Tables

### 1. **gold.dim_companies_tbl**
- **Purpose:** Stores company-level master information used for corporate action reporting and analysis.
- **Grain:** One row per company.

| Column Name | Data Type | Key Type | Description |
|---|---|---|---|
| company_key | INT | Primary Key | Surrogate key uniquely identifying each company in the Gold company dimension. |
| company_id | NVARCHAR(50) | Business Key | Source/business identifier for the company, used for traceability back to Silver/Bronze data. |
| company_name | NVARCHAR(200) | Attribute | Standardized legal or business name of the company. |
| sector | NVARCHAR(100) | Attribute | Business sector or industry group of the company. |
| country | NVARCHAR(100) | Attribute | Country associated with the company. |
| dwh_create_date | DATETIME2 | Audit Column | Date and time when the record was inserted into the Gold table. |

---

### 2. **gold.dim_securities_tbl**
- **Purpose:** Stores security-level information such as ticker and ISIN used to identify tradable instruments linked to corporate action events.
- **Grain:** One row per security.
- **Note:** `company_id` has been removed from this table. Company relationship is handled directly in the fact table through `company_key`.

| Column Name | Data Type | Key Type | Description |
|---|---|---|---|
| security_key | INT | Primary Key | Surrogate key uniquely identifying each security in the Gold security dimension. |
| security_id | NVARCHAR(50) | Business Key | Source/business identifier for the security. |
| ticker | NVARCHAR(50) | Attribute | Exchange ticker or trading symbol for the security. |
| isin | NVARCHAR(50) | Attribute | International Securities Identification Number used to uniquely identify the security. |
| dwh_create_date | DATETIME2 | Audit Column | Date and time when the record was inserted into the Gold table. |

---

### 3. **gold.dim_event_types_tbl**
- **Purpose:** Stores standardized corporate action event types used for classification and reporting.
- **Grain:** One row per event type.

| Column Name | Data Type | Key Type | Description |
|---|---|---|---|
| event_type_key | INT | Primary Key | Surrogate key uniquely identifying each corporate action event type. |
| event_type_id | INT | Business Key | Source/business identifier for the event type. |
| event_name | NVARCHAR(100) | Attribute | Standardized event type name, such as Dividend, Split, or Merger. |
| dwh_create_date | DATETIME2 | Audit Column | Date and time when the record was inserted into the Gold table. |

---

### 4. **gold.dim_dates_tbl**
- **Purpose:** Stores reusable calendar information for reporting and lifecycle tracking of corporate action dates.
- **Grain:** One row per calendar date.
- **Note:** This is a role-playing dimension used by multiple date keys in the fact table.

| Column Name | Data Type | Key Type | Description |
|---|---|---|---|
| date_key | INT | Primary Key | Calendar surrogate key in YYYYMMDD format. |
| calendar_date | DATE | Attribute | Actual calendar date. |
| day_number | INT | Attribute | Day number within the month. |
| day_name | NVARCHAR(20) | Attribute | Name of the day, such as Monday or Tuesday. |
| day_of_week | INT | Attribute | Numeric representation of day within the week. |
| week_number | INT | Attribute | Week number within the year. |
| month_number | INT | Attribute | Numeric month value from 1 to 12. |
| month_name | NVARCHAR(20) | Attribute | Name of the month. |
| quarter_number | INT | Attribute | Calendar quarter number. |
| year_number | INT | Attribute | Calendar year. |
| is_weekend | NVARCHAR(10) | Attribute | Indicates whether the date falls on a weekend. |
| dwh_create_date | DATETIME2 | Audit Column | Date and time when the record was inserted into the Gold table. |

---

### 5. **gold.fact_corporate_actions_tbl**
- **Purpose:** Stores corporate action events at the business reporting level. This table connects company, security, event type, and date dimensions for lifecycle tracking and analytics.
- **Grain:** One row per corporate action event.

| Column Name | Data Type | Key Type | Description |
|---|---|---|---|
| action_id | INT | Primary Key | Unique identifier for each corporate action event. |
| company_key | INT | Foreign Key | Links the corporate action event to `gold.dim_companies_tbl`. |
| security_key | INT | Foreign Key | Links the corporate action event to `gold.dim_securities_tbl`. |
| event_type_key | INT | Foreign Key | Links the corporate action event to `gold.dim_event_types_tbl`. |
| announcement_date_key | INT | Foreign Key | Links the announcement date to `gold.dim_dates_tbl`. |
| ex_date_key | INT | Foreign Key | Links the ex-date to `gold.dim_dates_tbl`. |
| record_date_key | INT | Foreign Key | Links the record date to `gold.dim_dates_tbl`. |
| payment_date_key | INT | Foreign Key | Links the payment date to `gold.dim_dates_tbl`. |
| currency | NVARCHAR(10) | Measure Attribute | Currency related to the corporate action, mainly applicable to dividend events. |
| dividend_amount | DECIMAL(18,2) | Measure | Dividend amount declared for dividend events. Null for non-dividend events. |
| split_ratio | NVARCHAR(20) | Measure Attribute | Split ratio for split events, such as 2:1 or 5:1. Null for non-split events. |
| ca_status | NVARCHAR(50) | Lifecycle Attribute | Current lifecycle status of the corporate action event, such as PENDING, COMPLETED, CANCELLED, or UNKNOWN. |
| dwh_create_date | DATETIME2 | Audit Column | Date and time when the record was inserted into the Gold table. |

---

## Final Reporting Views

### 1. **gold.vw_final_dividend_analysis**
- **Purpose:** Provides dividend-specific reporting by combining fact, company, security, event type, and date details.

| Column Name | Description |
|---|---|
| action_id | Corporate action event identifier. |
| company_name | Company associated with the dividend event. |
| ticker | Security ticker. |
| isin | Security ISIN. |
| sector | Company sector. |
| country | Company country. |
| announcement_date | Date the dividend was announced. |
| ex_date | Ex-dividend date. |
| record_date | Record date for shareholder eligibility. |
| payment_date | Dividend payment date. |
| event_name | Corporate action event type. |
| dividend_amount | Dividend amount. |
| ca_status | Lifecycle status of the event. |

---

### 2. **gold.vw_final_split_analysis**
- **Purpose:** Provides split-specific reporting by combining fact, company, security, event type, and date details.

| Column Name | Description |
|---|---|
| action_id | Corporate action event identifier. |
| company_name | Company associated with the split event. |
| ticker | Security ticker. |
| isin | Security ISIN. |
| sector | Company sector. |
| country | Company country. |
| announcement_date | Date the split was announced. |
| ex_date | Ex-date for the split. |
| record_date | Record date for shareholder eligibility. |
| payment_date | Payment or effective date, where applicable. |
| event_name | Corporate action event type. |
| split_ratio | Split ratio, such as 2:1 or 5:1. |
| ca_status | Lifecycle status of the event. |

---

### 3. **gold.vw_final_merger_analysis**
- **Purpose:** Provides merger-specific reporting by combining fact, company, security, event type, and date details.

| Column Name | Description |
|---|---|
| action_id | Corporate action event identifier. |
| company_name | Company associated with the merger event. |
| ticker | Security ticker. |
| isin | Security ISIN. |
| sector | Company sector. |
| country | Company country. |
| announcement_date | Date the merger was announced. |
| ex_date | Ex-date or effective date, where applicable. |
| record_date | Record date, where applicable. |
| payment_date | Payment or completion date, where applicable. |
| event_name | Corporate action event type. |
| ca_status | Lifecycle status of the event. |

---

### 4. **gold.vw_final_corporate_action_summary**
- **Purpose:** Provides summarized corporate action counts by event type, country, sector, and status.

| Column Name | Description |
|---|---|
| event_name | Corporate action event type. |
| country | Company country. |
| sector | Company sector. |
| ca_status | Lifecycle status of the event. |
| total_events | Total number of corporate action events. |

---

### 5. **gold.vw_final_monthly_ca_trend**
- **Purpose:** Provides monthly corporate action trend analysis, ranking, percentages, running totals, and month-over-month change.

| Column Name | Description |
|---|---|
| year_number | Calendar year of the announcement date. |
| month_number | Calendar month number. |
| month_name | Calendar month name. |
| event_name | Corporate action event type. |
| country | Company country. |
| sector | Company sector. |
| ca_status | Lifecycle status of the event. |
| total_events | Number of events in that month/category. |
| total_events_in_month | Total events in the month across categories. |
| event_rank_in_month | Rank of event category within the month based on event count. |
| event_percentage_in_month | Percentage contribution of the event category within the month. |
| running_total_by_event | Cumulative event count by event type over time. |
| previous_month_events | Previous month event count for the same event type. |
| month_over_month_change | Difference between current and previous month event count. |

---

### 6. **gold.vw_final_dividend_kpi**
- **Purpose:** Provides dividend KPI metrics by country and sector.

| Column Name | Description |
|---|---|
| country | Company country. |
| sector | Company sector. |
| total_dividend_events | Total number of dividend events. |
| total_dividend_amount | Total dividend amount. |
| avg_dividend_amount | Average dividend amount. |
| max_dividend_amount | Maximum dividend amount. |

---

### 7. **gold.vw_final_data_quality_exceptions**
- **Purpose:** Provides data quality exceptions from Gold fact data for monitoring missing mappings and event-specific issues.

| Column Name | Description |
|---|---|
| exception_type | Type of data quality issue identified. |
| action_id | Corporate action event identifier. |
| company_key | Company dimension key. |
| security_key | Security dimension key. |
| event_type_key | Event type dimension key. |
| announcement_date_key | Announcement date key. |
| ca_status | Lifecycle status of the event. |

---

## Gold Layer Relationships

| Parent Table | Parent Key | Child Table | Child Key | Relationship |
|---|---|---|---|---|
| gold.dim_companies_tbl | company_key | gold.fact_corporate_actions_tbl | company_key | One-to-Many |
| gold.dim_securities_tbl | security_key | gold.fact_corporate_actions_tbl | security_key | One-to-Many |
| gold.dim_event_types_tbl | event_type_key | gold.fact_corporate_actions_tbl | event_type_key | One-to-Many |
| gold.dim_dates_tbl | date_key | gold.fact_corporate_actions_tbl | announcement_date_key | One-to-Many |
| gold.dim_dates_tbl | date_key | gold.fact_corporate_actions_tbl | ex_date_key | One-to-Many |
| gold.dim_dates_tbl | date_key | gold.fact_corporate_actions_tbl | record_date_key | One-to-Many |
| gold.dim_dates_tbl | date_key | gold.fact_corporate_actions_tbl | payment_date_key | One-to-Many |

---

## Business Rules Captured

| Business Rule | Implementation |
|---|---|
| One corporate action event should have one unique action identifier. | `action_id` is the primary key in the fact table. |
| Each corporate action should map to a company. | `company_key` links fact to company dimension. |
| Each corporate action should map to a security. | `security_key` links fact to security dimension. |
| Each corporate action should map to a standardized event type. | `event_type_key` links fact to event type dimension. |
| One date dimension supports multiple lifecycle dates. | `announcement_date_key`, `ex_date_key`, `record_date_key`, and `payment_date_key` all link to `dim_dates_tbl`. |
| Dividend events should have dividend amount and currency where available. | Stored in `dividend_amount` and `currency`. |
| Split events should have split ratio where available. | Stored in `split_ratio`. |
| Event lifecycle should be trackable. | `ca_status` stores the corporate action lifecycle status. |
| Data quality issues should be reportable. | `vw_final_data_quality_exceptions` captures missing keys and event-specific issues. |

---

## Recommended Usage

| Use Case | Recommended Object |
|---|---|
| Power BI model relationship building | Gold dimension and fact tables |
| Dividend dashboard | `gold.vw_final_dividend_analysis` |
| Split dashboard | `gold.vw_final_split_analysis` |
| Merger dashboard | `gold.vw_final_merger_analysis` |
| KPI summary dashboard | `gold.vw_final_corporate_action_summary` |
| Monthly trend analysis | `gold.vw_final_monthly_ca_trend` |
| Dividend KPI analysis | `gold.vw_final_dividend_kpi` |
| Data quality monitoring | `gold.vw_final_data_quality_exceptions` |

---

## Notes

- `gold.dim_securities_tbl` does not contain `company_id` in the final version.
- Company-to-security relationship is handled through the fact table using `company_key` and `security_key`.
- `gold.dim_dates_tbl` is a role-playing dimension because the same date table supports announcement, ex-date, record date, and payment date.
- Final reporting views should be used for dashboarding, while physical Gold tables should be used for Power BI model relationships and performance.
