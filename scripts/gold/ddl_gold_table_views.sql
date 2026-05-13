/*
===============================================================================
DDL Script: Create Gold Table Views
===============================================================================
Script Purpose:
    This script creates views for the Gold Table layer in the corporate actions data warehouse. 
    The Gold layer represents the final dimension and fact views (Star Schema)

    Each view performs transformations and combines data from the Gold Table layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- ===============================================================================
-- 1. Final Dividend Analysis View
-- ===============================================================================
IF OBJECT_ID('gold.vw_final_dividend_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_final_dividend_analysis;
GO

CREATE OR ALTER VIEW gold.vw_final_dividend_analysis AS
SELECT
    f.action_id,
    c.company_name,
    s.ticker,
    s.isin,
    c.sector,
    c.country,
    da.calendar_date AS announcement_date,
    de.calendar_date AS ex_date,
    dr.calendar_date AS record_date,
    dp.calendar_date AS payment_date,
    e.event_name,
    f.currency,
    f.dividend_amount,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_companies_tbl c
    ON f.company_key = c.company_key
LEFT JOIN gold.dim_securities_tbl s
    ON f.security_key = s.security_key
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
LEFT JOIN gold.dim_dates_tbl da
    ON f.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates_tbl de
    ON f.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates_tbl dr
    ON f.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates_tbl dp
    ON f.payment_date_key = dp.date_key
WHERE e.event_name = 'Dividend'
  AND f.currency IS NOT NULL
  AND f.dividend_amount IS NOT NULL

  GO
-- ===============================================================================
-- 2. Final Split Analysis View
-- ===============================================================================

IF OBJECT_ID('gold.vw_final_split_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_final_split_analysis;
GO

CREATE OR ALTER VIEW gold.vw_final_split_analysis AS
SELECT
    f.action_id,
    c.company_name,
    s.ticker,
    s.isin,
    c.sector,
    c.country,
    da.calendar_date AS announcement_date,
    de.calendar_date AS ex_date,
    dr.calendar_date AS record_date,
    dp.calendar_date AS payment_date,
    e.event_name,
    f.split_ratio,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_companies_tbl c
    ON f.company_key = c.company_key
LEFT JOIN gold.dim_securities_tbl s
    ON f.security_key = s.security_key
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
LEFT JOIN gold.dim_dates_tbl da
    ON f.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates_tbl de
    ON f.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates_tbl dr
    ON f.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates_tbl dp
    ON f.payment_date_key = dp.date_key
WHERE e.event_name = 'Split'
  AND f.split_ratio IS NOT NULL;

GO

-- ===============================================================================
-- 3. Final Merger Analysis View
-- ===============================================================================

IF OBJECT_ID('gold.vw_final_merger_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_final_merger_analysis;
GO

CREATE OR ALTER VIEW gold.vw_final_merger_analysis AS
SELECT
    f.action_id,
    c.company_name,
    s.ticker,
    s.isin,
    c.sector,
    c.country,
    da.calendar_date AS announcement_date,
    de.calendar_date AS ex_date,
    dr.calendar_date AS record_date,
    dp.calendar_date AS payment_date,
    e.event_name,
    m.target_company,
    m.acquirer_company,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_companies_tbl c
    ON f.company_key = c.company_key
LEFT JOIN gold.dim_securities_tbl s
    ON f.security_key = s.security_key
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
LEFT JOIN gold.dim_dates_tbl da
    ON f.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates_tbl de
    ON f.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates_tbl dr
    ON f.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates_tbl dp
    ON f.payment_date_key = dp.date_key
INNER JOIN silver.mdv_mergers m
    ON f.action_id = m.action_id
WHERE e.event_name = 'Merger';

GO

-- ===============================================================================
-- 4. Final Corporate Actions Summary View
-- ===============================================================================

IF OBJECT_ID('gold.vw_final_corporate_action_summary', 'V') IS NOT NULL
    DROP VIEW gold.vw_final_corporate_action_summary;
GO

CREATE OR ALTER VIEW gold.vw_final_corporate_action_summary AS
SELECT
    e.event_name,
    c.country,
    c.sector,
    f.ca_status,
    COUNT(*) AS total_events

FROM gold.fact_corporate_actions_tbl f

LEFT JOIN gold.dim_companies_tbl c
    ON f.company_key = c.company_key

LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key

GROUP BY
    e.event_name,
    c.country,
    c.sector,
    f.ca_status;

GO

-- ===============================================================================
-- 5. Final Monthly Corporate Actions Trend View
-- ===============================================================================

IF OBJECT_ID('gold.vw_final_monthly_ca_trend', 'V') IS NOT NULL
    DROP VIEW gold.vw_final_monthly_ca_trend;
GO

CREATE OR ALTER VIEW gold.vw_final_monthly_ca_trend AS
WITH monthly_event_counts AS
(
    SELECT
        d.year_number,
        d.month_number,
        d.month_name,
        e.event_name,
        c.country,
        c.sector,
        f.ca_status,
        COUNT(*) AS total_events

    FROM gold.fact_corporate_actions_tbl f

    LEFT JOIN gold.dim_dates_tbl d
        ON f.announcement_date_key = d.date_key

    LEFT JOIN gold.dim_event_types_tbl e
        ON f.event_type_key = e.event_type_key

    LEFT JOIN gold.dim_companies_tbl c
        ON f.company_key = c.company_key

    WHERE d.date_key IS NOT NULL

    GROUP BY
        d.year_number,
        d.month_number,
        d.month_name,
        e.event_name,
        c.country,
        c.sector,
        f.ca_status
)
SELECT
    year_number,
    month_number,
    month_name,
    event_name,
    country,
    sector,
    ca_status,
    total_events,

    SUM(total_events) OVER (
        PARTITION BY year_number, month_number
    ) AS total_events_in_month,

    DENSE_RANK() OVER (
        PARTITION BY year_number, month_number
        ORDER BY total_events DESC
    ) AS event_rank_in_month,

    CAST(
        total_events * 100.0 /
        SUM(total_events) OVER (
            PARTITION BY year_number, month_number
        )
        AS DECIMAL(10,2)
    ) AS event_percentage_in_month,

    SUM(total_events) OVER (
        PARTITION BY event_name
        ORDER BY year_number, month_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_by_event,

    LAG(total_events) OVER (
        PARTITION BY event_name
        ORDER BY year_number, month_number
    ) AS previous_month_events,

    total_events -
    LAG(total_events) OVER (
        PARTITION BY event_name
        ORDER BY year_number, month_number
    ) AS month_over_month_change

FROM monthly_event_counts;

GO

-- ===============================================================================
-- 6. Final Dividend KPI View
-- ===============================================================================

IF OBJECT_ID('gold.vw_final_dividend_kpi', 'V') IS NOT NULL
    DROP VIEW gold.vw_final_dividend_kpi;
GO

CREATE OR ALTER VIEW gold.vw_final_dividend_kpi AS
SELECT
    c.country,
    c.sector,
    d.currency,
    COUNT(*) AS total_dividend_events,
    SUM(f.dividend_amount) AS total_dividend_amount,
    CAST(AVG(f.dividend_amount) AS DECIMAL(10,2)) AS avg_dividend_amount,
    MAX(f.dividend_amount) AS max_dividend_amount
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_companies_tbl c
    ON f.company_key = c.company_key
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
INNER JOIN silver.mdv_dividends d
    ON f.action_id = d.action_id
WHERE e.event_name = 'Dividend'
GROUP BY
    c.country,
    c.sector,
    d.currency;

GO

-- ===============================================================================
-- 7. Final Data Quality Exception View
-- ===============================================================================

IF OBJECT_ID('gold.vw_final_data_quality_exceptions', 'V') IS NOT NULL
    DROP VIEW gold.vw_final_data_quality_exceptions;
GO

CREATE OR ALTER VIEW gold.vw_final_data_quality_exceptions AS
SELECT
    'Missing Company Key' AS exception_type,
    action_id,
    company_key,
    security_key,
    event_type_key,
    announcement_date_key,
    ca_status
FROM gold.fact_corporate_actions_tbl
WHERE company_key IS NULL

UNION ALL

SELECT
    'Missing Security Key' AS exception_type,
    action_id,
    company_key,
    security_key,
    event_type_key,
    announcement_date_key,
    ca_status
FROM gold.fact_corporate_actions_tbl
WHERE security_key IS NULL

UNION ALL

SELECT
    'Missing Event Type Key' AS exception_type,
    action_id,
    company_key,
    security_key,
    event_type_key,
    announcement_date_key,
    ca_status
FROM gold.fact_corporate_actions_tbl
WHERE event_type_key IS NULL

UNION ALL

SELECT
    'Missing Announcement Date Key' AS exception_type,
    action_id,
    company_key,
    security_key,
    event_type_key,
    announcement_date_key,
    ca_status
FROM gold.fact_corporate_actions_tbl
WHERE announcement_date_key IS NULL

UNION ALL

SELECT
    'Dividend Event Missing Amount' AS exception_type,
    f.action_id,
    f.company_key,
    f.security_key,
    f.event_type_key,
    f.announcement_date_key,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
WHERE e.event_name = 'Dividend'
  AND f.dividend_amount IS NULL

UNION ALL

SELECT
    'Split Event Missing Ratio' AS exception_type,
    f.action_id,
    f.company_key,
    f.security_key,
    f.event_type_key,
    f.announcement_date_key,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
WHERE e.event_name = 'Split'
  AND f.split_ratio IS NULL
  AND EXISTS (
      SELECT 1
      FROM silver.mdv_splits sp
      WHERE sp.action_id = f.action_id
  )

UNION ALL

SELECT
    'Dividend Has Split Ratio' AS exception_type,
    f.action_id,
    f.company_key,
    f.security_key,
    f.event_type_key,
    f.announcement_date_key,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
WHERE e.event_name = 'Dividend'
  AND f.split_ratio IS NOT NULL

UNION ALL

SELECT
    'Split Has Dividend Amount' AS exception_type,
    f.action_id,
    f.company_key,
    f.security_key,
    f.event_type_key,
    f.announcement_date_key,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_event_types_tbl e
    ON f.event_type_key = e.event_type_key
WHERE e.event_name = 'Split'
  AND f.dividend_amount IS NOT NULL;
GO


/*
SELECT * FROM gold.vw_final_dividend_analysis;
SELECT * FROM gold.vw_final_split_analysis;
SELECT * FROM gold.vw_final_merger_analysis;
SELECT * FROM gold.vw_final_corporate_action_summary;
SELECT * FROM gold.vw_final_monthly_ca_trend;
SELECT * FROM gold.vw_final_dividend_kpi;
SELECT * FROM gold.vw_final_data_quality_exceptions;
*/
