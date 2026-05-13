/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the corporate actions data warehouse. 
    The Gold layer represents the final dimension and fact views (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_companies
-- =============================================================================
IF OBJECT_ID('gold.dim_companies', 'V') IS NOT NULL
    DROP VIEW gold.dim_companies;
GO

CREATE VIEW gold.dim_companies AS
SELECT
    ROW_NUMBER() OVER (ORDER BY company_id) AS company_key, -- Surrogate key
    company_id,
    company_name,
    sector,
    country
FROM silver.mdv_companies;
GO

-- =============================================================================
-- Create Dimension: gold.dim_securities
-- =============================================================================
IF OBJECT_ID('gold.dim_securities', 'V') IS NOT NULL
    DROP VIEW gold.dim_securities;
GO

CREATE VIEW gold.dim_securities AS
SELECT
    ROW_NUMBER() OVER (ORDER BY security_id) AS security_key, -- Surrogate key
    security_id,
    ticker,
    isin,
    company_id
FROM silver.mdv_securities;
GO

-- =============================================================================
-- Create Dimension: gold.dim_event_types
-- =============================================================================
IF OBJECT_ID('gold.dim_event_types', 'V') IS NOT NULL
    DROP VIEW gold.dim_event_types;
GO

CREATE VIEW gold.dim_event_types AS
SELECT
    ROW_NUMBER() OVER (ORDER BY event_type_id) AS event_type_key, -- Surrogate key
    event_type_id,
    event_name
FROM silver.mdv_event_types;
GO

-- =============================================================================
-- Create Dimension: gold.dim_dates
-- =============================================================================
IF OBJECT_ID('gold.dim_dates', 'V') IS NOT NULL
    DROP VIEW gold.dim_dates;
GO

CREATE VIEW gold.dim_dates AS
SELECT
    CAST(FORMAT(full_date, 'yyyyMMdd') AS INT) AS date_key,
    full_date AS calendar_date,
    day AS day_number,
    day_name,
    day_of_week,
    week_of_year AS week_number,
    month AS month_number,
    month_name,
    quarter AS quarter_number,
    year AS year_number,
    is_weekend
FROM silver.mdv_dates
WHERE full_date IS NOT NULL;
GO

-- =============================================================================
-- Create Fact Table: gold.fact_corporate_actions
-- =============================================================================
IF OBJECT_ID('gold.fact_corporate_actions', 'V') IS NOT NULL
    DROP VIEW gold.fact_corporate_actions;
GO

CREATE VIEW gold.fact_corporate_actions AS
SELECT
    ca.action_id,

    dc.company_key,
    ds.security_key,
    det.event_type_key,

    da.date_key AS announcement_date_key,
    de.date_key AS ex_date_key,
    dr.date_key AS record_date_key,
    dp.date_key AS payment_date_key,

    ca.dividend_amount,
    ca.split_ratio,
    ca.ca_status

FROM silver.mdv_corporate_actions ca

LEFT JOIN gold.dim_companies dc
    ON ca.company_id = dc.company_id

LEFT JOIN gold.dim_securities ds
    ON ca.security_id = ds.security_id

LEFT JOIN gold.dim_event_types det
    ON ca.event_type_id = det.event_type_id

LEFT JOIN gold.dim_dates da
    ON ca.announcement_date = da.calendar_date

LEFT JOIN gold.dim_dates de
    ON ca.ex_date = de.calendar_date

LEFT JOIN gold.dim_dates dr
    ON ca.record_date = dr.calendar_date

LEFT JOIN gold.dim_dates dp
    ON ca.payment_date = dp.calendar_date;
GO

-- =============================================================================
-- Create Dividend Analysis View
-- =============================================================================
IF OBJECT_ID('gold.vw_dividend_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_dividend_analysis;
GO

CREATE VIEW gold.vw_dividend_analysis AS
SELECT
    fc.action_id,
    dc.company_name,
    ds.ticker,
    ds.isin,
    dc.sector,
    dc.country,
    da.calendar_date AS announcement_date,
    de.calendar_date AS ex_date,
    dr.calendar_date AS record_date,
    dp.calendar_date AS payment_date,
    det.event_name,
    d.currency,
    d.dividend_amount,
    fc.ca_status
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_companies dc
    ON fc.company_key = dc.company_key
LEFT JOIN gold.dim_securities ds
    ON fc.security_key = ds.security_key
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
LEFT JOIN gold.dim_dates da
    ON fc.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates de
    ON fc.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates dr
    ON fc.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates dp
    ON fc.payment_date_key = dp.date_key
INNER JOIN silver.mdv_dividends d
    ON fc.action_id = d.action_id
WHERE det.event_name = 'Dividend';

GO

-- =============================================================================
-- Create Split Analysis View
-- =============================================================================
IF OBJECT_ID('gold.vw_split_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_split_analysis;
GO

CREATE VIEW gold.vw_split_analysis AS
SELECT
    fc.action_id,
    dc.company_name,
    ds.ticker,
    ds.isin,
    dc.sector,
    dc.country,
    da.calendar_date AS announcement_date,
    de.calendar_date AS ex_date,
    dr.calendar_date AS record_date,
    dp.calendar_date AS payment_date,
    det.event_name,
    s.split_ratio,
    fc.ca_status
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_companies dc
    ON fc.company_key = dc.company_key
LEFT JOIN gold.dim_securities ds
    ON fc.security_key = ds.security_key
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
LEFT JOIN gold.dim_dates da
    ON fc.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates de
    ON fc.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates dr
    ON fc.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates dp
    ON fc.payment_date_key = dp.date_key
INNER JOIN silver.mdv_splits s
    ON fc.action_id = s.action_id
WHERE det.event_name = 'Split';

GO

-- =============================================================================
-- Create Merger Analysis View
-- =============================================================================
IF OBJECT_ID('gold.vw_merger_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_merger_analysis;
GO

CREATE VIEW gold.vw_merger_analysis AS
SELECT
    fc.action_id,
    dc.company_name,
    ds.ticker,
    ds.isin,
    dc.sector,
    dc.country,
    da.calendar_date AS announcement_date,
    de.calendar_date AS ex_date,
    dr.calendar_date AS record_date,
    dp.calendar_date AS payment_date,
    det.event_name,
    m.target_company,
    m.acquirer_company,
    fc.ca_status
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_companies dc
    ON fc.company_key = dc.company_key
LEFT JOIN gold.dim_securities ds
    ON fc.security_key = ds.security_key
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
LEFT JOIN gold.dim_dates da
    ON fc.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates de
    ON fc.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates dr
    ON fc.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates dp
    ON fc.payment_date_key = dp.date_key
INNER JOIN silver.mdv_mergers m
    ON fc.action_id = m.action_id
WHERE det.event_name = 'Merger';

GO

-- =============================================================================
-- Create Corporate Actions Summary View
-- =============================================================================
IF OBJECT_ID('gold.vw_corporate_action_summary', 'V') IS NOT NULL
    DROP VIEW gold.vw_corporate_action_summary;
GO

CREATE VIEW gold.vw_corporate_action_summary AS
SELECT
    det.event_name,
    dc.country,
    dc.sector,
    fc.ca_status,
    COUNT(*) AS total_events
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_companies dc
    ON fc.company_key = dc.company_key
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
GROUP BY
    det.event_name,
    dc.country,
    dc.sector,
    fc.ca_status;

GO

-- =============================================================================
-- Create Monthly Corporate Actions Trend
-- =============================================================================
IF OBJECT_ID('gold.vw_monthly_ca_trend', 'V') IS NOT NULL
    DROP VIEW gold.vw_monthly_ca_trend;
GO

CREATE VIEW gold.vw_monthly_ca_trend AS
WITH monthly_event_counts AS
(
    SELECT
        dd.year_number,
        dd.month_number,
        dd.month_name,
        det.event_name,
        dc.country,
        dc.sector,
        fc.ca_status,
        COUNT(*) AS total_events
    FROM gold.fact_corporate_actions fc
    LEFT JOIN gold.dim_dates dd
        ON fc.announcement_date_key = dd.date_key
    LEFT JOIN gold.dim_event_types det
        ON fc.event_type_key = det.event_type_key
    LEFT JOIN gold.dim_companies dc
        ON fc.company_key = dc.company_key
    WHERE dd.date_key IS NOT NULL
    GROUP BY
        dd.year_number,
        dd.month_number,
        dd.month_name,
        det.event_name,
        dc.country,
        dc.sector,
        fc.ca_status
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

-- =============================================================================
-- Create Dividend KPI / Dividend Analytics
-- =============================================================================
IF OBJECT_ID('gold.vw_dividend_kpi', 'V') IS NOT NULL
    DROP VIEW gold.vw_dividend_kpi;
GO

CREATE VIEW gold.vw_dividend_kpi AS
SELECT
    dc.country,
    dc.sector,
    d.currency,
    COUNT(*) AS total_dividend_events,
    SUM(d.dividend_amount) AS total_dividend_amount,
    CAST(AVG(d.dividend_amount) AS DECIMAL(10,2)) AS avg_dividend_amount,
    MAX(d.dividend_amount) AS max_dividend_amount
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_companies dc
    ON fc.company_key = dc.company_key
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
INNER JOIN silver.mdv_dividends d
    ON fc.action_id = d.action_id
WHERE det.event_name = 'Dividend'
GROUP BY
    dc.country,
    dc.sector,
    d.currency;
GO

-- =============================================================================
-- Create Data Quality Exception View
-- =============================================================================
IF OBJECT_ID('gold.vw_data_quality_exceptions', 'V') IS NOT NULL
    DROP VIEW gold.vw_data_quality_exceptions;
GO

CREATE VIEW gold.vw_data_quality_exceptions AS
-- Missing key mappings
SELECT
    'Missing Company Key' AS exception_type,
    action_id,
    company_key,
    security_key,
    event_type_key,
    announcement_date_key,
    ca_status
FROM gold.fact_corporate_actions
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
FROM gold.fact_corporate_actions
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
FROM gold.fact_corporate_actions
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
FROM gold.fact_corporate_actions
WHERE announcement_date_key IS NULL

UNION ALL

-- Event-specific issues
SELECT
    'Dividend Event Missing Amount' AS exception_type,
    fc.action_id,
    fc.company_key,
    fc.security_key,
    fc.event_type_key,
    fc.announcement_date_key,
    fc.ca_status
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
WHERE det.event_name = 'Dividend'
  AND fc.dividend_amount IS NULL

UNION ALL

SELECT
    'Split Event Missing Ratio' AS exception_type,
    fc.action_id,
    fc.company_key,
    fc.security_key,
    fc.event_type_key,
    fc.announcement_date_key,
    fc.ca_status
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
WHERE det.event_name = 'Split'
  AND fc.split_ratio IS NULL

UNION ALL

-- Invalid cross-field issues
SELECT
    'Dividend Has Split Ratio' AS exception_type,
    fc.action_id,
    fc.company_key,
    fc.security_key,
    fc.event_type_key,
    fc.announcement_date_key,
    fc.ca_status
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
WHERE det.event_name = 'Dividend'
  AND fc.split_ratio IS NOT NULL

UNION ALL

SELECT
    'Split Has Dividend Amount' AS exception_type,
    fc.action_id,
    fc.company_key,
    fc.security_key,
    fc.event_type_key,
    fc.announcement_date_key,
    fc.ca_status
FROM gold.fact_corporate_actions fc
LEFT JOIN gold.dim_event_types det
    ON fc.event_type_key = det.event_type_key
WHERE det.event_name = 'Split'
  AND fc.dividend_amount IS NOT NULL;
GO
