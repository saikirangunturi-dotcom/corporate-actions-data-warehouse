/*
===============================================================================
Quality Checks: Gold Layer Tables and Final Reporting Views
===============================================================================
Script Purpose:
    This script performs quality checks for the Gold layer of the Corporate
    Actions Data Warehouse project.

    It validates:
    - Row count reconciliation between Silver and Gold.
    - Primary key uniqueness.
    - Mandatory column completeness.
    - Referential integrity between fact and dimension tables.
    - Date key mappings.
    - Event-specific business rules.
    - Final reporting views.
    - Data quality exception view output.
    - Lifecycle tracking fields and event timelines.

Usage Notes:
    - Run this script after executing gold.load_gold.
    - Expected result for most exception queries: 0 rows.
    - If any query returns rows, review and correct the source/silver/gold load logic.

===============================================================================
*/

USE CorporateActions; -- Change database name if required
GO


/*=============================================================================
  1. ROW COUNT VALIDATION: SILVER VS GOLD TABLES
=============================================================================*/

-- Compare Silver master tables with Gold dimension/fact tables.
SELECT
    'companies' AS table_name,
    (SELECT COUNT(*) FROM silver.mdv_companies) AS silver_count,
    (SELECT COUNT(*) FROM gold.dim_companies_tbl) AS gold_count

UNION ALL

SELECT
    'securities',
    (SELECT COUNT(*) FROM silver.mdv_securities),
    (SELECT COUNT(*) FROM gold.dim_securities_tbl)

UNION ALL

SELECT
    'event_types',
    (SELECT COUNT(*) FROM silver.mdv_event_types),
    (SELECT COUNT(*) FROM gold.dim_event_types_tbl)

UNION ALL

SELECT
    'dates',
    (SELECT COUNT(*) FROM silver.mdv_dates),
    (SELECT COUNT(*) FROM gold.dim_dates_tbl)

UNION ALL

SELECT
    'corporate_actions',
    (SELECT COUNT(*) FROM silver.mdv_corporate_actions),
    (SELECT COUNT(*) FROM gold.fact_corporate_actions_tbl);
GO


/*=============================================================================
  2. BASIC GOLD TABLE HEALTH CHECKS
=============================================================================*/

-- Total records available in Gold fact table.
SELECT
    COUNT(*) AS total_gold_corporate_action_rows
FROM gold.fact_corporate_actions_tbl;
GO

-- Corporate action count by event type.
SELECT
    et.event_name,
    COUNT(*) AS total_count
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
GROUP BY
    et.event_name
ORDER BY
    et.event_name;
GO

-- Corporate action count by status.
SELECT
    f.ca_status,
    COUNT(*) AS total_count
FROM gold.fact_corporate_actions_tbl f
GROUP BY
    f.ca_status
ORDER BY
    f.ca_status;
GO

-- Sample Gold fact records for manual review.
SELECT TOP (20)
    *
FROM gold.fact_corporate_actions_tbl
ORDER BY
    action_id;
GO


/*=============================================================================
  3. PRIMARY KEY DUPLICATE CHECKS
=============================================================================*/

-- Duplicate company surrogate keys should not exist.
SELECT
    company_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_companies_tbl
GROUP BY
    company_key
HAVING COUNT(*) > 1;
GO

-- Duplicate security surrogate keys should not exist.
SELECT
    security_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_securities_tbl
GROUP BY
    security_key
HAVING COUNT(*) > 1;
GO

-- Duplicate event type surrogate keys should not exist.
SELECT
    event_type_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_event_types_tbl
GROUP BY
    event_type_key
HAVING COUNT(*) > 1;
GO

-- Duplicate date keys should not exist.
SELECT
    date_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_dates_tbl
GROUP BY
    date_key
HAVING COUNT(*) > 1;
GO

-- Duplicate action IDs should not exist in the fact table.
SELECT
    action_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_corporate_actions_tbl
GROUP BY
    action_id
HAVING COUNT(*) > 1;
GO


/*=============================================================================
  4. BUSINESS KEY DUPLICATE CHECKS
=============================================================================*/

-- Duplicate company business IDs should not exist.
SELECT
    company_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_companies_tbl
GROUP BY
    company_id
HAVING COUNT(*) > 1;
GO

-- Duplicate security business IDs should not exist.
SELECT
    security_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_securities_tbl
GROUP BY
    security_id
HAVING COUNT(*) > 1;
GO

-- Duplicate ISINs should be reviewed. In some cases this may be valid, but normally
-- one active security should have one ISIN.
SELECT
    isin,
    COUNT(*) AS duplicate_count
FROM gold.dim_securities_tbl
WHERE isin IS NOT NULL
GROUP BY
    isin
HAVING COUNT(*) > 1;
GO

-- Duplicate event type business IDs should not exist.
SELECT
    event_type_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_event_types_tbl
GROUP BY
    event_type_id
HAVING COUNT(*) > 1;
GO

-- Duplicate calendar dates should not exist.
SELECT
    calendar_date,
    COUNT(*) AS duplicate_count
FROM gold.dim_dates_tbl
GROUP BY
    calendar_date
HAVING COUNT(*) > 1;
GO


/*=============================================================================
  5. MANDATORY COLUMN NULL CHECKS
=============================================================================*/

-- Company dimension mandatory columns must not be NULL.
SELECT
    *
FROM gold.dim_companies_tbl
WHERE company_key IS NULL
   OR company_id IS NULL
   OR company_name IS NULL
   OR sector IS NULL
   OR country IS NULL;
GO

-- Security dimension mandatory columns must not be NULL.
SELECT
    *
FROM gold.dim_securities_tbl
WHERE security_key IS NULL
   OR security_id IS NULL
   OR ticker IS NULL
   OR isin IS NULL;
GO

-- Event type dimension mandatory columns must not be NULL.
SELECT
    *
FROM gold.dim_event_types_tbl
WHERE event_type_key IS NULL
   OR event_type_id IS NULL
   OR event_name IS NULL;
GO

-- Date dimension mandatory columns must not be NULL.
SELECT
    *
FROM gold.dim_dates_tbl
WHERE date_key IS NULL
   OR calendar_date IS NULL
   OR day_number IS NULL
   OR month_number IS NULL
   OR quarter_number IS NULL
   OR year_number IS NULL;
GO

-- Fact table mandatory columns must not be NULL.
SELECT
    *
FROM gold.fact_corporate_actions_tbl
WHERE action_id IS NULL
   OR company_key IS NULL
   OR security_key IS NULL
   OR event_type_key IS NULL
   OR announcement_date_key IS NULL;
GO


/*=============================================================================
  6. REFERENTIAL INTEGRITY CHECKS: FACT TO DIMENSIONS
=============================================================================*/

-- Fact company_key should always map to a valid company dimension record.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_companies_tbl c
    ON f.company_key = c.company_key
WHERE c.company_key IS NULL;
GO

-- Fact security_key should always map to a valid security dimension record.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_securities_tbl s
    ON f.security_key = s.security_key
WHERE s.security_key IS NULL;
GO

-- Fact event_type_key should always map to a valid event type dimension record.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_type_key IS NULL;
GO

-- Fact announcement_date_key should always map to a valid date dimension record.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_dates_tbl d
    ON f.announcement_date_key = d.date_key
WHERE d.date_key IS NULL;
GO

-- Fact ex_date_key should map to date dimension when it is available.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_dates_tbl d
    ON f.ex_date_key = d.date_key
WHERE f.ex_date_key IS NOT NULL
  AND d.date_key IS NULL;
GO

-- Fact record_date_key should map to date dimension when it is available.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_dates_tbl d
    ON f.record_date_key = d.date_key
WHERE f.record_date_key IS NOT NULL
  AND d.date_key IS NULL;
GO

-- Fact payment_date_key should map to date dimension when it is available.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_dates_tbl d
    ON f.payment_date_key = d.date_key
WHERE f.payment_date_key IS NOT NULL
  AND d.date_key IS NULL;
GO


/*=============================================================================
  7. RECONCILIATION: SILVER CORPORATE ACTIONS VS GOLD FACT
=============================================================================*/

-- Silver corporate actions that did not load into Gold fact.
SELECT
    s.*
FROM silver.mdv_corporate_actions s
LEFT JOIN gold.fact_corporate_actions_tbl f
    ON s.action_id = f.action_id
WHERE f.action_id IS NULL;
GO

-- Gold fact records that are not available in Silver corporate actions.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN silver.mdv_corporate_actions s
    ON f.action_id = s.action_id
WHERE s.action_id IS NULL;
GO


/*=============================================================================
  8. EVENT-SPECIFIC FACT VALIDATIONS
=============================================================================*/

-- Dividend events must have dividend_amount.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Dividend'
  AND f.dividend_amount IS NULL;
GO

-- Dividend events should not have split_ratio.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Dividend'
  AND f.split_ratio IS NOT NULL;
GO

-- Split events must have split_ratio.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Split'
  AND f.split_ratio IS NULL
  AND EXISTS (
      SELECT 1
      FROM silver.mdv_splits sp
      WHERE sp.action_id = f.action_id
  );
GO

-- Split events should not have dividend_amount.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Split'
  AND f.dividend_amount IS NOT NULL;
GO

-- Merger events should not have dividend_amount or split_ratio.
SELECT
    f.*
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Merger'
  AND (
        f.dividend_amount IS NOT NULL
        OR f.split_ratio IS NOT NULL
      );
GO


/*=============================================================================
  9. DATE AND LIFECYCLE TRACKING VALIDATIONS
=============================================================================*/

-- Business date sequence validation.
-- Expected lifecycle: announcement_date <= ex_date <= record_date <= payment_date.
SELECT
    f.action_id,
    da.calendar_date AS announcement_date,
    de.calendar_date AS ex_date,
    dr.calendar_date AS record_date,
    dp.calendar_date AS payment_date,
    f.ca_status
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_dates_tbl da
    ON f.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates_tbl de
    ON f.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates_tbl dr
    ON f.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates_tbl dp
    ON f.payment_date_key = dp.date_key
WHERE da.calendar_date > de.calendar_date
   OR de.calendar_date > dr.calendar_date
   OR dr.calendar_date > dp.calendar_date;
GO

-- Announcement date should be available for lifecycle tracking.
SELECT
    *
FROM gold.fact_corporate_actions_tbl
WHERE announcement_date_key IS NULL;
GO

-- Review records where status is missing or unknown.
SELECT
    *
FROM gold.fact_corporate_actions_tbl
WHERE ca_status IS NULL
   OR UPPER(ca_status) = 'UNKNOWN';
GO

-- Status should be part of the approved status list.
-- Change list if your source uses different status values.
SELECT
    *
FROM gold.fact_corporate_actions_tbl
WHERE UPPER(ca_status) NOT IN (
    'ANNOUNCED',
    'UPDATED',
    'COMPLETED',
    'CANCELLED',
    'UNKNOWN'
);
GO


/*=============================================================================
  10. FINAL REPORTING VIEW EXISTENCE CHECKS
=============================================================================*/

-- Confirm all final reporting views exist.
SELECT
    v.name AS view_name
FROM sys.views v
JOIN sys.schemas s
    ON v.schema_id = s.schema_id
WHERE s.name = 'gold'
  AND v.name IN (
        'vw_final_dividend_analysis',
        'vw_final_split_analysis',
        'vw_final_merger_analysis',
        'vw_final_corporate_action_summary',
        'vw_final_monthly_ca_trend',
        'vw_final_dividend_kpi',
        'vw_final_data_quality_exceptions'
  )
ORDER BY
    v.name;
GO


/*=============================================================================
  11. FINAL REPORTING VIEW COUNT CHECKS
=============================================================================*/

-- Dividend view count should match Dividend event count in Gold fact.
SELECT
    'Dividend View vs Fact' AS check_name,
    (SELECT COUNT(*)
     FROM gold.vw_final_dividend_analysis) AS view_count,
    (SELECT COUNT(*)
     FROM gold.fact_corporate_actions_tbl f
     JOIN gold.dim_event_types_tbl et
        ON f.event_type_key = et.event_type_key
     WHERE et.event_name = 'Dividend'
     AND f.currency IS NOT NULL
     AND f.dividend_amount IS NOT NULL) AS fact_count;
GO

-- Split view count should match Split event count in Gold fact.
SELECT
    'Split View vs Fact' AS check_name,
    (SELECT COUNT(*)
     FROM gold.vw_final_split_analysis) AS view_count,
    (SELECT COUNT(*)
     FROM gold.fact_corporate_actions_tbl f
     JOIN gold.dim_event_types_tbl et
        ON f.event_type_key = et.event_type_key
     WHERE et.event_name = 'Split'
     AND f.split_ratio IS NOT NULL) AS fact_count;
GO

-- Merger view count should match Merger event count in Gold fact.
SELECT
    'Merger View vs Fact' AS check_name,
    (SELECT COUNT(*)
     FROM gold.vw_final_merger_analysis) AS view_count,
    (SELECT COUNT(*)
     FROM gold.fact_corporate_actions_tbl f
     JOIN gold.dim_event_types_tbl et
        ON f.event_type_key = et.event_type_key
     INNER JOIN silver.mdv_mergers m
        ON f.action_id = m.action_id
     WHERE et.event_name = 'Merger') AS fact_count;
GO


/*=============================================================================
  12. FINAL REPORTING VIEW NULL CHECKS
=============================================================================*/

-- Dividend final view should have important reporting fields.
SELECT
    *
FROM gold.vw_final_dividend_analysis
WHERE action_id IS NULL
   OR company_name IS NULL
   OR ticker IS NULL
   OR event_name IS NULL
   OR announcement_date IS NULL
   OR dividend_amount IS NULL;
GO

-- Split final view should have important reporting fields.
SELECT
    *
FROM gold.vw_final_split_analysis
WHERE action_id IS NULL
   OR company_name IS NULL
   OR ticker IS NULL
   OR event_name IS NULL
   OR announcement_date IS NULL
   OR split_ratio IS NULL;
GO

-- Merger final view should have important reporting fields.
SELECT
    *
FROM gold.vw_final_merger_analysis
WHERE action_id IS NULL
   OR company_name IS NULL
   OR ticker IS NULL
   OR event_name IS NULL
   OR announcement_date IS NULL;
GO


/*=============================================================================
  13. FINAL REPORTING VIEW DUPLICATE CHECKS
=============================================================================*/

-- Dividend view should not duplicate action_id.
SELECT
    action_id,
    COUNT(*) AS duplicate_count
FROM gold.vw_final_dividend_analysis
GROUP BY
    action_id
HAVING COUNT(*) > 1;
GO

-- Split view should not duplicate action_id.
SELECT
    action_id,
    COUNT(*) AS duplicate_count
FROM gold.vw_final_split_analysis
GROUP BY
    action_id
HAVING COUNT(*) > 1;
GO

-- Merger view should not duplicate action_id.
SELECT
    action_id,
    COUNT(*) AS duplicate_count
FROM gold.vw_final_merger_analysis
GROUP BY
    action_id
HAVING COUNT(*) > 1;
GO


/*=============================================================================
  14. SUMMARY AND KPI VIEW CHECKS
=============================================================================*/

-- Summary view should not return NULL event names.
SELECT
    *
FROM gold.vw_final_corporate_action_summary
WHERE event_name IS NULL;
GO

-- Monthly trend view should not return NULL year or month.
SELECT
    *
FROM gold.vw_final_monthly_ca_trend
WHERE year_number IS NULL
   OR month_number IS NULL
   OR event_name IS NULL;
GO

-- Dividend KPI view should not have negative dividend values.
SELECT
    *
FROM gold.vw_final_dividend_kpi
WHERE total_dividend_amount < 0
   OR avg_dividend_amount < 0
   OR max_dividend_amount < 0;
GO

-- Dividend KPI totals should match Dividend analysis view totals.
SELECT
    'Dividend KPI Total vs Dividend Analysis Total' AS check_name,
    (SELECT SUM(total_dividend_events)
     FROM gold.vw_final_dividend_kpi) AS kpi_total_events,
    (SELECT COUNT(*)
     FROM gold.vw_final_dividend_analysis) AS dividend_analysis_total_events;
GO


/*=============================================================================
  15. DATA QUALITY EXCEPTION VIEW CHECKS
=============================================================================*/

-- Review all data quality exceptions.
SELECT
    *
FROM gold.vw_final_data_quality_exceptions
ORDER BY
    exception_type,
    action_id;
GO

-- Exception summary by type.
SELECT
    exception_type,
    COUNT(*) AS issue_count
FROM gold.vw_final_data_quality_exceptions
GROUP BY
    exception_type
ORDER BY
    issue_count DESC;
GO


/*=============================================================================
  16. GOLD LAYER HEALTH CHECK SUMMARY
=============================================================================*/

SELECT
    'Missing Company Key Mapping' AS check_name,
    COUNT(*) AS issue_count
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_companies_tbl c
    ON f.company_key = c.company_key
WHERE c.company_key IS NULL

UNION ALL

SELECT
    'Missing Security Key Mapping',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_securities_tbl s
    ON f.security_key = s.security_key
WHERE s.security_key IS NULL

UNION ALL

SELECT
    'Missing Event Type Key Mapping',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_type_key IS NULL

UNION ALL

SELECT
    'Missing Announcement Date Key Mapping',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_dates_tbl d
    ON f.announcement_date_key = d.date_key
WHERE d.date_key IS NULL

UNION ALL

SELECT
    'Duplicate Fact Action IDs',
    COUNT(*)
FROM (
    SELECT
        action_id
    FROM gold.fact_corporate_actions_tbl
    GROUP BY
        action_id
    HAVING COUNT(*) > 1
) duplicate_actions

UNION ALL

SELECT
    'Dividend Missing Amount',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Dividend'
  AND f.dividend_amount IS NULL

UNION ALL

SELECT
    'Dividend Has Split Ratio',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Dividend'
  AND f.split_ratio IS NOT NULL

UNION ALL

SELECT
    'Split Missing Ratio',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Split'
  AND f.split_ratio IS NULL
  AND EXISTS (
      SELECT 1
      FROM silver.mdv_splits sp
      WHERE sp.action_id = f.action_id)

UNION ALL

SELECT
    'Split Has Dividend Amount',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
JOIN gold.dim_event_types_tbl et
    ON f.event_type_key = et.event_type_key
WHERE et.event_name = 'Split'
  AND f.dividend_amount IS NOT NULL

UNION ALL

SELECT
    'Invalid Date Sequence',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl f
LEFT JOIN gold.dim_dates_tbl da
    ON f.announcement_date_key = da.date_key
LEFT JOIN gold.dim_dates_tbl de
    ON f.ex_date_key = de.date_key
LEFT JOIN gold.dim_dates_tbl dr
    ON f.record_date_key = dr.date_key
LEFT JOIN gold.dim_dates_tbl dp
    ON f.payment_date_key = dp.date_key
WHERE da.calendar_date > de.calendar_date
   OR de.calendar_date > dr.calendar_date
   OR dr.calendar_date > dp.calendar_date

UNION ALL

SELECT
    'Invalid Status Values',
    COUNT(*)
FROM gold.fact_corporate_actions_tbl
WHERE UPPER(ca_status) NOT IN (
    'ANNOUNCED',
    'UPDATED',
    'COMPLETED',
    'CANCELLED',
    'UNKNOWN'
);
GO
