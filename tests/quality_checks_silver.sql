/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This stored performs various quality checks for data consistency, accuracy,
	and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date range validations.
    - Data consistency between related fields.

    Using Notes:
    - Run these checks after data loading Silver layer.
    - Investigate and resolve any discrepencies found during the checks.

===============================================================================
*/

USE CorporateActions; -- Change database name if required
GO

/*=============================================================================
  1. ROW COUNT VALIDATION: BRONZE VS SILVER
=============================================================================*/

SELECT
    'companies' AS table_name,
    (SELECT COUNT(*) FROM bronze.mdv_companies) AS bronze_count,
    (SELECT COUNT(*) FROM silver.mdv_companies) AS silver_count

UNION ALL

SELECT
    'securities',
    (SELECT COUNT(*) FROM bronze.mdv_securities),
    (SELECT COUNT(*) FROM silver.mdv_securities)

UNION ALL

SELECT
    'event_types',
    (SELECT COUNT(*) FROM bronze.mdv_event_types),
    (SELECT COUNT(*) FROM silver.mdv_event_types)

UNION ALL

SELECT
    'corporate_actions',
    (SELECT COUNT(*) FROM bronze.mdv_corporate_actions),
    (SELECT COUNT(*) FROM silver.mdv_corporate_actions)

UNION ALL

SELECT
    'dividends',
    (SELECT COUNT(*) FROM bronze.mdv_dividends),
    (SELECT COUNT(*) FROM silver.mdv_dividends)

UNION ALL

SELECT
    'splits',
    (SELECT COUNT(*) FROM bronze.mdv_splits),
    (SELECT COUNT(*) FROM silver.mdv_splits)

UNION ALL

SELECT
    'mergers',
    (SELECT COUNT(*) FROM bronze.mdv_mergers),
    (SELECT COUNT(*) FROM silver.mdv_mergers)

UNION ALL

SELECT
    'dates',
    (SELECT COUNT(*) FROM bronze.mdv_dates),
    (SELECT COUNT(*) FROM silver.mdv_dates);
GO


/*=============================================================================
  2. BASIC SILVER TABLE HEALTH CHECKS
=============================================================================*/

-- Total corporate action records available in Silver.
SELECT
    COUNT(*) AS total_corporate_action_rows
FROM silver.mdv_corporate_actions;
GO

-- Corporate action count by event type.
SELECT
    et.event_name,
    COUNT(*) AS total_count
FROM silver.mdv_corporate_actions ca
JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
GROUP BY
    et.event_name
ORDER BY
    et.event_name;
GO

-- Corporate action count by status.
SELECT
    ca.ca_status,
    COUNT(*) AS total_count
FROM silver.mdv_corporate_actions ca
GROUP BY
    ca.ca_status
ORDER BY
    ca.ca_status;
GO

-- Sample corporate action records for manual review.
SELECT TOP (20)
    *
FROM silver.mdv_corporate_actions
ORDER BY
    action_id;
GO


/*=============================================================================
  3. DUPLICATE CHECKS
=============================================================================*/

-- Duplicate company IDs should not exist.
SELECT
    company_id,
    COUNT(*) AS duplicate_count
FROM silver.mdv_companies
GROUP BY
    company_id
HAVING COUNT(*) > 1;
GO

-- Duplicate security IDs should not exist.
SELECT
    security_id,
    COUNT(*) AS duplicate_count
FROM silver.mdv_securities
GROUP BY
    security_id
HAVING COUNT(*) > 1;
GO

-- Duplicate corporate action IDs should not exist.
SELECT
    action_id,
    COUNT(*) AS duplicate_count
FROM silver.mdv_corporate_actions
GROUP BY
    action_id
HAVING COUNT(*) > 1;
GO


/*=============================================================================
  4. MANDATORY COLUMN NULL CHECKS
=============================================================================*/

-- Company mandatory columns must not be NULL.
SELECT
    *
FROM silver.mdv_companies
WHERE company_id IS NULL
   OR company_name IS NULL
   OR sector IS NULL
   OR country IS NULL;
GO

-- Security mandatory columns must not be NULL.
SELECT
    *
FROM silver.mdv_securities
WHERE security_id IS NULL
   OR ticker IS NULL
   OR isin IS NULL
   OR company_id IS NULL;
GO

-- Corporate action mandatory columns must not be NULL.
SELECT
    *
FROM silver.mdv_corporate_actions
WHERE action_id IS NULL
   OR company_id IS NULL
   OR security_id IS NULL
   OR event_type_id IS NULL;
GO


/*=============================================================================
  5. REFERENTIAL INTEGRITY CHECKS
=============================================================================*/

-- Securities should always map to a valid company.
SELECT
    s.*
FROM silver.mdv_securities s
LEFT JOIN silver.mdv_companies c
    ON s.company_id = c.company_id
WHERE c.company_id IS NULL;
GO

-- Corporate actions should always map to a valid company.
SELECT
    ca.*
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_companies c
    ON ca.company_id = c.company_id
WHERE c.company_id IS NULL;
GO

-- Corporate actions should always map to a valid security.
SELECT
    ca.*
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_securities s
    ON ca.security_id = s.security_id
WHERE s.security_id IS NULL;
GO

-- Corporate actions should always map to a valid event type.
SELECT
    ca.*
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
WHERE et.event_type_id IS NULL;
GO


/*=============================================================================
  6. REJECTED BRONZE CORPORATE ACTION RECORDS
=============================================================================*/

-- Bronze corporate action records that did not load into Silver.
SELECT
    b.*
FROM bronze.mdv_corporate_actions b
LEFT JOIN silver.mdv_corporate_actions s
    ON TRY_CONVERT(INT, b.action_id) = s.action_id
WHERE s.action_id IS NULL;
GO


/*=============================================================================
  7. EVENT-SPECIFIC COMPLETENESS CHECKS
=============================================================================*/

-- Dividend events must have matching records in silver.mdv_dividends.
SELECT
    ca.*
FROM silver.mdv_corporate_actions ca
JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
LEFT JOIN silver.mdv_dividends d
    ON ca.action_id = d.action_id
WHERE et.event_name = 'Dividend'
  AND d.action_id IS NULL;
GO

-- Split events must have matching records in silver.mdv_splits.
SELECT
    ca.*
FROM silver.mdv_corporate_actions ca
JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
LEFT JOIN silver.mdv_splits s
    ON ca.action_id = s.action_id
WHERE et.event_name = 'Split'
  AND s.action_id IS NULL;
GO

-- Merger events must have matching records in silver.mdv_mergers.
SELECT
    ca.*
FROM silver.mdv_corporate_actions ca
JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
LEFT JOIN silver.mdv_mergers m
    ON ca.action_id = m.action_id
WHERE et.event_name = 'Merger'
  AND m.action_id IS NULL;
GO


/*=============================================================================
  8. WRONG EVENT-SPECIFIC DATA CHECKS
=============================================================================*/

-- Dividend table should contain only Dividend events.
SELECT
    d.action_id,
    et.event_name
FROM silver.mdv_dividends d
JOIN silver.mdv_corporate_actions ca
    ON d.action_id = ca.action_id
JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
WHERE et.event_name <> 'Dividend';
GO

-- Split table should contain only Split events.
SELECT
    s.action_id,
    et.event_name
FROM silver.mdv_splits s
JOIN silver.mdv_corporate_actions ca
    ON s.action_id = ca.action_id
JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
WHERE et.event_name <> 'Split';
GO

-- Merger table should contain only Merger events.
SELECT
    m.action_id,
    et.event_name
FROM silver.mdv_mergers m
JOIN silver.mdv_corporate_actions ca
    ON m.action_id = ca.action_id
JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
WHERE et.event_name <> 'Merger';
GO


/*=============================================================================
  9. DIVIDEND DETAIL VALIDATIONS
=============================================================================*/

-- Dividend amount should be available and greater than zero.
SELECT
    *
FROM silver.mdv_dividends
WHERE dividend_amount IS NULL
   OR dividend_amount <= 0;
GO

-- Dividend currency should not be NULL or blank.
SELECT
    *
FROM silver.mdv_dividends
WHERE NULLIF(TRIM(currency), '') IS NULL;
GO

-- Bronze dividend data quality summary before/after conversion.
SELECT
    COUNT(*) AS total_bronze_dividend_rows,

    SUM(CASE
            WHEN TRY_CONVERT(INT, d.action_id) IS NULL
            THEN 1 ELSE 0
        END) AS invalid_action_id,

    SUM(CASE
            WHEN TRY_CONVERT(DECIMAL(18, 2), NULLIF(TRIM(d.dividend_amount), '')) IS NULL
            THEN 1 ELSE 0
        END) AS missing_or_invalid_dividend_amount,

    SUM(CASE
            WHEN NULLIF(TRIM(d.currency), '') IS NULL
            THEN 1 ELSE 0
        END) AS missing_currency,

    SUM(CASE
            WHEN TRY_CONVERT(INT, d.action_id) IS NOT NULL
             AND TRY_CONVERT(DECIMAL(18, 2), NULLIF(TRIM(d.dividend_amount), '')) IS NOT NULL
             AND NULLIF(TRIM(d.currency), '') IS NOT NULL
            THEN 1 ELSE 0
        END) AS valid_rows_for_insert
FROM bronze.mdv_dividends d;
GO

-- Expected valid dividend rows based on matching Dividend events in Silver.
SELECT
    COUNT(*) AS expected_valid_dividend_rows
FROM bronze.mdv_dividends d
INNER JOIN silver.mdv_corporate_actions ca
    ON TRY_CONVERT(INT, d.action_id) = ca.action_id
INNER JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
WHERE et.event_name = 'Dividend'
  AND TRY_CONVERT(INT, d.action_id) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18, 2), NULLIF(TRIM(d.dividend_amount), '')) IS NOT NULL
  AND NULLIF(TRIM(d.currency), '') IS NOT NULL;
GO


/*=============================================================================
  10. SPLIT DETAIL VALIDATIONS
=============================================================================*/

-- Split ratio should be available and should contain ':' format, for example 2:1.
SELECT
    *
FROM silver.mdv_splits
WHERE split_ratio IS NULL
   OR split_ratio NOT LIKE '%:%';
GO

-- Missing split details from Silver.
SELECT
    COUNT(*) AS total_split_events,
    SUM(CASE WHEN s.action_id IS NOT NULL THEN 1 ELSE 0 END) AS matched_split_details,
    SUM(CASE WHEN s.action_id IS NULL THEN 1 ELSE 0 END) AS missing_split_details,
    SUM(CASE WHEN NULLIF(TRIM(s.split_ratio), '') IS NULL THEN 1 ELSE 0 END) AS missing_or_invalid_split_ratio
FROM silver.mdv_corporate_actions ca
LEFT JOIN bronze.mdv_splits s
    ON ca.action_id = TRY_CONVERT(INT, s.action_id)
WHERE ca.event_type = 'Split';
GO


/*=============================================================================
  11. MERGER DETAIL VALIDATIONS
=============================================================================*/

-- Target and acquirer company should be available and should not be the same.
SELECT
    *
FROM silver.mdv_mergers
WHERE target_company IS NULL
   OR acquirer_company IS NULL
   OR target_company = acquirer_company;
GO

-- Missing merger details from Silver.
SELECT
    COUNT(*) AS total_merger_events,
    SUM(CASE WHEN m.action_id IS NOT NULL THEN 1 ELSE 0 END) AS matched_merger_details,
    SUM(CASE WHEN m.action_id IS NULL THEN 1 ELSE 0 END) AS missing_merger_details,
    SUM(CASE WHEN NULLIF(TRIM(m.target_company), '') IS NULL THEN 1 ELSE 0 END) AS missing_target_company,
    SUM(CASE WHEN NULLIF(TRIM(m.acquirer_company), '') IS NULL THEN 1 ELSE 0 END) AS missing_acquirer_company
FROM silver.mdv_corporate_actions ca
LEFT JOIN bronze.mdv_mergers m
    ON ca.action_id = TRY_CONVERT(INT, m.action_id)
WHERE ca.event_type = 'Merger';
GO


/*=============================================================================
  12. STATUS VALIDATION
=============================================================================*/

-- Review all distinct status values available in Silver.
SELECT DISTINCT
    ca_status
FROM silver.mdv_corporate_actions
ORDER BY
    ca_status;
GO

-- Status should be part of the approved status list.
SELECT
    *
FROM silver.mdv_corporate_actions
WHERE ca_status NOT IN (
    'Announced',
    'Updated',
    'Completed',
    'Cancelled',
    'Unknown'
);
GO


/*=============================================================================
  13. DATE VALIDATIONS
=============================================================================*/

-- Business date sequence validation.
-- Expected flow: announcement_date <= ex_date <= record_date <= payment_date.
SELECT
    *
FROM silver.mdv_corporate_actions
WHERE announcement_date > ex_date
   OR ex_date > record_date
   OR record_date > payment_date;
GO

-- Invalid Bronze announcement dates based on DD-MM-YYYY style conversion.
SELECT
    *
FROM bronze.mdv_corporate_actions
WHERE TRY_CONVERT(DATE, announcement_date, 105) IS NULL
  AND announcement_date IS NOT NULL;
GO

-- Corporate action dates should exist in silver.mdv_dates.
SELECT
    'announcement_date' AS date_column,
    ca.announcement_date AS missing_date
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_dates d
    ON ca.announcement_date = d.full_date
WHERE ca.announcement_date IS NOT NULL
  AND d.full_date IS NULL

UNION ALL

SELECT
    'ex_date',
    ca.ex_date
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_dates d
    ON ca.ex_date = d.full_date
WHERE ca.ex_date IS NOT NULL
  AND d.full_date IS NULL

UNION ALL

SELECT
    'record_date',
    ca.record_date
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_dates d
    ON ca.record_date = d.full_date
WHERE ca.record_date IS NOT NULL
  AND d.full_date IS NULL

UNION ALL

SELECT
    'payment_date',
    ca.payment_date
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_dates d
    ON ca.payment_date = d.full_date
WHERE ca.payment_date IS NOT NULL
  AND d.full_date IS NULL;
GO


/*=============================================================================
  14. SILVER HEALTH CHECK SUMMARY
=============================================================================*/

SELECT
    'Missing Company Mapping' AS check_name,
    COUNT(*) AS issue_count
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_companies c
    ON ca.company_id = c.company_id
WHERE c.company_id IS NULL

UNION ALL

SELECT
    'Missing Security Mapping',
    COUNT(*)
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_securities s
    ON ca.security_id = s.security_id
WHERE s.security_id IS NULL

UNION ALL

SELECT
    'Missing Event Type Mapping',
    COUNT(*)
FROM silver.mdv_corporate_actions ca
LEFT JOIN silver.mdv_event_types et
    ON ca.event_type_id = et.event_type_id
WHERE et.event_type_id IS NULL

UNION ALL

SELECT
    'Duplicate Corporate Actions',
    COUNT(*)
FROM (
    SELECT
        action_id
    FROM silver.mdv_corporate_actions
    GROUP BY
        action_id
    HAVING COUNT(*) > 1
) duplicate_actions

UNION ALL

SELECT
    'Invalid Dividend Amounts',
    COUNT(*)
FROM silver.mdv_dividends
WHERE dividend_amount IS NULL
   OR dividend_amount <= 0

UNION ALL

SELECT
    'Missing Dividend Currency',
    COUNT(*)
FROM silver.mdv_dividends
WHERE NULLIF(TRIM(currency), '') IS NULL

UNION ALL

SELECT
    'Invalid Split Ratios',
    COUNT(*)
FROM silver.mdv_splits
WHERE split_ratio IS NULL
   OR split_ratio NOT LIKE '%:%'

UNION ALL

SELECT
    'Invalid Merger Records',
    COUNT(*)
FROM silver.mdv_mergers
WHERE target_company IS NULL
   OR acquirer_company IS NULL
   OR target_company = acquirer_company

UNION ALL

SELECT
    'Invalid Status Values',
    COUNT(*)
FROM silver.mdv_corporate_actions
WHERE ca_status NOT IN (
    'Announced',
    'Updated',
    'Completed',
    'Cancelled',
    'Unknown'
)

UNION ALL

SELECT
    'Invalid Date Sequence',
    COUNT(*)
FROM silver.mdv_corporate_actions
WHERE announcement_date > ex_date
   OR ex_date > record_date
   OR record_date > payment_date;
GO
