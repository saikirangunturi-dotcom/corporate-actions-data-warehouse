----Validations Gold Layer----

SELECT COUNT(*) AS total_records
FROM gold.fact_corporate_actions;

SELECT
    validation_status,
    COUNT(*) AS record_count
FROM gold.fact_corporate_actions
GROUP BY validation_status;

SELECT
    e.event_type_standard,
    COUNT(*) AS Total_Valid_Events
FROM gold.fact_corporate_actions f
LEFT JOIN gold.dim_event_types e
    ON f.event_type_key = e.event_type_key
WHERE f.validation_status = 'Valid'
GROUP BY e.event_type_standard;

SELECT
    e.event_type_standard,
    COUNT(*) AS Total_Invalid_Events
FROM gold.fact_corporate_actions f
LEFT JOIN gold.dim_event_types e
    ON f.event_type_key = e.event_type_key
WHERE f.validation_status = 'Invalid'
GROUP BY e.event_type_standard;

SELECT
    e.event_type_standard,
    COUNT(*) AS Total_Warning_Events
FROM gold.fact_corporate_actions f
LEFT JOIN gold.dim_event_types e
    ON f.event_type_key = e.event_type_key
WHERE f.validation_status = 'Warning'
GROUP BY e.event_type_standard;

---Validate reporting views--

SELECT * FROM gold.vw_executive_summary;
SELECT * FROM gold.vw_data_quality_summary;

SELECT COUNT(*) AS dividend_records FROM gold.vw_dividend_analysis;
SELECT COUNT(*) AS split_records FROM gold.vw_split_analysis;
SELECT COUNT(*) AS merger_records FROM gold.vw_merger_analysis;
