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
-- 1. Executive Summary View
-- ===============================================================================
IF OBJECT_ID('gold.vw_executive_summary', 'V') IS NOT NULL
    DROP VIEW gold.vw_executive_summary;
GO

CREATE OR ALTER VIEW gold.vw_executive_summary AS
SELECT
    COUNT(*) AS total_corporate_actions,
    COUNT(DISTINCT action_id) AS unique_actions,
    SUM(CASE WHEN validation_status = 'Valid' THEN 1 ELSE 0 END) AS valid_records,
    SUM(CASE WHEN validation_status = 'Warning' THEN 1 ELSE 0 END) AS warning_records,
    SUM(CASE WHEN validation_status = 'Invalid' THEN 1 ELSE 0 END) AS invalid_records
FROM gold.fact_corporate_actions;

GO

-- ===============================================================================
-- 2. Dividend Analysis View
-- ===============================================================================
IF OBJECT_ID('gold.vw_dividend_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_dividend_analysis;
GO

CREATE OR ALTER VIEW gold.vw_dividend_analysis AS
SELECT
    f.corporate_action_id,
    c.company_name,
    s.ticker,
    f.announcement_date,
    f.ex_date,
    f.record_date,
    f.payment_date,
    f.dividend_amount,
    f.ca_status,
    f.validation_status
FROM gold.fact_corporate_actions f
JOIN gold.dim_event_types e
    ON f.event_type_key = e.event_type_key
LEFT JOIN gold.dim_companies c
    ON f.company_key = c.company_key
LEFT JOIN gold.dim_securities s
    ON f.security_key = s.security_key
WHERE e.event_type_standard = 'Dividend'
AND f.validation_status = 'Valid';

GO
-- ===============================================================================
-- 3. Split Analysis View
-- ===============================================================================

IF OBJECT_ID('gold.vw_split_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_split_analysis;
GO

CREATE OR ALTER VIEW gold.vw_split_analysis AS
SELECT
    f.corporate_action_id,
    c.company_name,
    s.ticker,
    f.announcement_date,
    f.ex_date,
    f.record_date,
    f.payment_date,
    f.split_ratio,
    f.ca_status,
    f.validation_status
FROM gold.fact_corporate_actions f
JOIN gold.dim_event_types e
    ON f.event_type_key = e.event_type_key
LEFT JOIN gold.dim_companies c
    ON f.company_key = c.company_key
LEFT JOIN gold.dim_securities s
    ON f.security_key = s.security_key
WHERE e.event_type_standard = 'Split'
AND f.validation_status = 'Valid'

GO

-- ===============================================================================
-- 4. Merger Analysis View
-- ===============================================================================

IF OBJECT_ID('gold.vw_merger_analysis', 'V') IS NOT NULL
    DROP VIEW gold.vw_merger_analysis;
GO

CREATE OR ALTER VIEW gold.vw_merger_analysis AS
SELECT
    f.corporate_action_id,
    c.company_name,
    s.ticker,
    f.announcement_date,
    f.ex_date,
    f.record_date,
    f.payment_date,
    f.ca_status,
    f.validation_status
FROM gold.fact_corporate_actions f
JOIN gold.dim_event_types e
    ON f.event_type_key = e.event_type_key
LEFT JOIN gold.dim_companies c
    ON f.company_key = c.company_key
LEFT JOIN gold.dim_securities s
    ON f.security_key = s.security_key
WHERE e.event_type_standard = 'Merger'
AND f.validation_status = 'Valid';

GO

-- ===============================================================================
-- 5. Data Quality Summary View
-- ===============================================================================

IF OBJECT_ID('gold.vw_data_quality_summary', 'V') IS NOT NULL
    DROP VIEW gold.vw_data_quality_summary;
GO

CREATE OR ALTER VIEW gold.vw_data_quality_summary AS
SELECT
    validation_status,
    validation_message,
    COUNT(*) AS record_count
FROM gold.fact_corporate_actions
GROUP BY
    validation_status,
    validation_message;
GO

-- ===============================================================================
-- Validations
-- ===============================================================================
/*

SELECT * FROM gold.vw_executive_summary;
SELECT * FROM gold.vw_dividend_analysis;
SELECT * FROM gold.vw_split_analysis;
SELECT * FROM gold.vw_merger_analysis;
SELECT * FROM gold.vw_data_quality_summary;

*/
