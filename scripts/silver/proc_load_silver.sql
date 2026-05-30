/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
	populate the 'silver' schema tables from the 'bronze' schema. 
    Actions Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading Corporate Actions Data Warehouse Tables';
		PRINT '------------------------------------------------';

		-- Loading companies data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_companies';
		TRUNCATE TABLE silver.mdv_companies;
		PRINT '>> Inserting Data Into: silver.mdv_companies';
		INSERT INTO silver.mdv_companies (
			company_id,
			company_name,
			sector,
			country
		)
		SELECT DISTINCT
			TRIM(company_id) AS company_id,
			UPPER(TRIM(company_name)) AS company_name,
			TRIM(sector) AS sector,
			TRIM(country) AS country
			FROM bronze.mdv_companies
			WHERE company_id IS NOT NULL;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading securities data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_securities';
		TRUNCATE TABLE silver.mdv_securities;
		PRINT '>> Inserting Data Into: silver.mdv_securities';
		INSERT INTO silver.mdv_securities (
			security_id,
			ticker,
			isin,
			company_id
		)
		SELECT DISTINCT
			TRIM(security_id) AS security_id,
			TRIM(ticker) AS ticker,
			TRIM(isin) AS isin,
			TRIM(company_id) AS company_id
		FROM bronze.mdv_securities
		WHERE security_id IS NOT NULL
			AND company_id IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading event types data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_event_types';
		TRUNCATE TABLE silver.mdv_event_types;
		PRINT '>> Inserting Data Into: silver.mdv_event_types';
		INSERT INTO silver.mdv_event_types (
			event_type_id,
			event_name
		)
		SELECT
			TRIM(event_type_id) AS event_type_id,
			TRIM(event_name) AS event_name
		FROM bronze.mdv_event_types
		WHERE event_type_id IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		-- Loading dates data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_dates';
		TRUNCATE TABLE silver.mdv_dates;
		PRINT '>> Inserting Data Into: silver.mdv_dates';
		WITH cleaned_dates AS
			(
				SELECT
					
					COALESCE(
						TRY_CONVERT(DATE, NULLIF(TRIM(full_date), ''), 105), -- dd-mm-yyyy
						TRY_CONVERT(DATE, NULLIF(TRIM(full_date), ''), 23),  -- yyyy-mm-dd
						TRY_CONVERT(DATE, NULLIF(TRIM(full_date), ''), 103), -- dd/mm/yyyy
						TRY_CONVERT(DATE, NULLIF(TRIM(full_date), ''), 111)  -- yyyy/mm/dd
						) AS full_date,
					TRY_CAST(day AS INT) AS day,
					TRIM(day_name) AS day_name,
					TRY_CAST(day_of_week AS INT) AS day_of_week,
					TRY_CAST(week_of_year AS INT) AS week_of_year,
					TRY_CAST(month AS INT) AS month,
					TRIM(month_name) AS month_name,
					TRY_CAST(quarter AS INT) AS quarter,
					TRY_CAST(year AS INT) AS year,

					CASE
						WHEN day_of_week IN (6,7) THEN 'Y'
						WHEN day_of_week BETWEEN 1 AND 5 THEN 'N'
						ELSE 'UNKNOWN'
					END AS is_weekend
				FROM bronze.mdv_dates
			)
			INSERT INTO silver.mdv_dates
			(
				full_date,
				day,
				day_name,
				day_of_week,
				week_of_year,
				month,
				month_name,
				quarter,
				year,
				is_weekend
			)
			SELECT DISTINCT
				full_date,
				day,
				day_name,
				day_of_week,
				week_of_year,
				month,
				month_name,
				quarter,
				year,
				is_weekend
			FROM cleaned_dates
			WHERE full_date IS NOT NULL;

	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		-- Loading dividends data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_dividends';
		TRUNCATE TABLE silver.mdv_dividends;
		PRINT '>> Inserting Data Into: silver.mdv_dividends';
			INSERT INTO silver.mdv_dividends (
					action_id,
					dividend_amount,
					currency			
			)
			SELECT DISTINCT
				TRY_CONVERT(INT, TRIM(action_id)) AS action_id,
				TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(dividend_amount), '')) AS dividend_amount,
				'INR' AS currency
				FROM bronze.mdv_dividends
				WHERE TRY_CONVERT(INT, TRIM(action_id)) IS NOT NULL
				AND TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(dividend_amount), '')) IS NOT NULL;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading splits data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_splits';
		TRUNCATE TABLE silver.mdv_splits;
		PRINT '>> Inserting Data Into: silver.mdv_splits';
		INSERT INTO silver.mdv_splits (
				action_id,
				split_ratio
			)
		SELECT DISTINCT
				TRY_CONVERT(INT, TRIM(action_id)) AS action_id,
				REPLACE(REPLACE(TRIM(split_ratio), '02:01', '2:1'), '05:01', '5:1') AS split_ratio
		FROM bronze.mdv_splits
		WHERE TRY_CONVERT(INT, TRIM(action_id)) IS NOT NULL
		AND NULLIF(TRIM(split_ratio), '') IS NOT NULL;

	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading mergers data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_mergers';
		TRUNCATE TABLE silver.mdv_mergers;
		PRINT '>> Inserting Data Into: silver.mdv_mergers';
		WITH merger_dedup AS
		(
		SELECT
        TRY_CONVERT(INT, TRIM(action_id)) AS action_id,
        UPPER(TRIM(target_company)) AS target_company,
        UPPER(TRIM(acquirer_company)) AS acquirer_company,
        ROW_NUMBER() OVER (
            PARTITION BY
                UPPER(TRIM(target_company)),
                UPPER(TRIM(acquirer_company))
            ORDER BY TRY_CONVERT(INT, TRIM(action_id))
        ) AS rn
		FROM bronze.mdv_mergers
		WHERE TRY_CONVERT(INT, TRIM(action_id)) IS NOT NULL
		AND NULLIF(TRIM(target_company), '') IS NOT NULL
		AND NULLIF(TRIM(acquirer_company), '') IS NOT NULL
		AND UPPER(TRIM(target_company)) <> UPPER(TRIM(acquirer_company))
		)
		INSERT INTO silver.mdv_mergers (
			action_id,
			target_company,
			acquirer_company
		)
		SELECT
			action_id,
			target_company,
			acquirer_company
		FROM merger_dedup
		WHERE rn = 1;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading corporate actions data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_corporate_actions';
		TRUNCATE TABLE silver.mdv_corporate_actions;
		PRINT '>> Inserting Data Into: silver.mdv_corporate_actions';
		WITH bronze2silver_corporate_actions AS
		(
			SELECT
				ca.*,
				TRY_CONVERT(INT, TRIM(ca.action_id)) AS clean_action_id,
				UPPER(TRIM(ca.company_name)) AS clean_company_name,
				UPPER(TRIM(ca.ticker)) AS clean_ticker,
				UPPER(TRIM(ca.event_type)) AS clean_event_type_raw,
				TRY_CONVERT(DATE, NULLIF(TRIM(ca.announcement_date), ''), 105) AS clean_announcement_date,
				TRY_CONVERT(DATE, NULLIF(TRIM(ca.ex_date), ''), 105) AS clean_ex_date,
				TRY_CONVERT(DATE, NULLIF(TRIM(ca.record_date), ''), 105) AS clean_record_date,
				TRY_CONVERT(DATE, NULLIF(TRIM(ca.payment_date), ''), 105) AS clean_payment_date

			FROM bronze.mdv_corporate_actions ca
			),
			mapped_corporate_actions AS
			(
				SELECT
					ca.*,
					c.company_name AS master_company_name,

					CASE
						WHEN clean_event_type_raw IN ('DIV', 'DIVIDEND', 'CASH DIVIDEND') THEN 'Dividend'
						WHEN clean_event_type_raw IN ('SPLIT', 'STOCK SPLIT') THEN 'Split'
						WHEN clean_event_type_raw IN ('MERGER', 'M&A', 'MERGERS') THEN 'Merger'
						ELSE 'Invalid'
					END AS event_type_standard,

					CASE
						WHEN clean_action_id IS NULL THEN 1
						ELSE 0
					END AS is_action_id_missing,

					CASE
						WHEN clean_event_type_raw NOT IN
						(
							'DIV', 'DIVIDEND', 'CASH DIVIDEND',
							'SPLIT', 'STOCK SPLIT',
							'MERGER', 'M&A', 'MERGERS'
						)
						THEN 1
						ELSE 0
					END AS is_event_type_invalid,

					CASE
						WHEN s.ticker IS NULL THEN 1
						ELSE 0
					END AS is_company_ticker_mismatch,

					CASE
						WHEN clean_ex_date < clean_announcement_date
						OR clean_record_date < clean_ex_date
						OR clean_payment_date < clean_record_date
						THEN 1 
						ELSE 0
					END AS is_date_sequence_invalid,

					CASE
						WHEN clean_announcement_date IS NULL
						OR clean_ex_date IS NULL
						OR clean_record_date IS NULL
						OR clean_payment_date IS NULL
						THEN 1
						ELSE 0
					END AS is_mandatory_date_missing
				FROM bronze2silver_corporate_actions ca
				LEFT JOIN silver.mdv_companies c
				    ON ca.clean_company_name = UPPER(TRIM(c.company_name))
				LEFT JOIN silver.mdv_securities s
					ON c.company_id = s.company_id
					AND ca.clean_ticker = UPPER(TRIM(s.ticker))
				)

				INSERT INTO silver.mdv_corporate_actions
				(
					action_id,
					company_name,
					ticker,
					master_company_name,
					event_type_raw,
					event_type_standard,
					announcement_date,
					ex_date,
					record_date,
					payment_date,
					dividend_amount,
					split_ratio,
					ca_status,
					is_action_id_missing,
					is_event_type_invalid,
					is_company_ticker_mismatch,
					is_date_sequence_invalid,
					is_mandatory_date_missing,
					validation_status,
					validation_message
				)
				SELECT DISTINCT
					clean_action_id,
					clean_company_name,
					clean_ticker,
					master_company_name,
					clean_event_type_raw,
					event_type_standard,
					clean_announcement_date,
					clean_ex_date,
					clean_record_date,
					clean_payment_date,

					TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(dividend_amount), '')) AS dividend_amount,
			
					CASE
						WHEN NULLIF(TRIM(split_ratio), '') IS NULL THEN NULL
						ELSE REPLACE(REPLACE(TRIM(split_ratio), '02:01', '2:1'), '05:01', '5:1')
					END AS split_ratio,

					CASE
						WHEN NULLIF(TRIM(status), '') IS NULL THEN NULL
						ELSE UPPER(LEFT(TRIM(status),1))
							+ LOWER(SUBSTRING(TRIM(status),2,LEN(TRIM(status))))
					END AS ca_status,

					is_action_id_missing,
					is_event_type_invalid,
					is_company_ticker_mismatch,
					is_date_sequence_invalid,
					is_mandatory_date_missing,

					CASE
						WHEN is_action_id_missing = 1 THEN 'Invalid'
						WHEN is_event_type_invalid = 1 THEN 'Invalid'
						WHEN is_company_ticker_mismatch = 1 THEN 'Invalid'
						WHEN is_date_sequence_invalid = 1 THEN 'Invalid'
						WHEN is_mandatory_date_missing = 1 THEN 'Warning'
						ELSE 'Valid'
					END AS validation_status,

					CASE
						WHEN is_action_id_missing = 1 THEN 'Invalid action id'
						WHEN is_event_type_invalid = 1 THEN 'Invalid event type'
						WHEN is_company_ticker_mismatch = 1 THEN 'Company and ticker mismatch'
						WHEN is_date_sequence_invalid = 1 THEN 'Invalid date sequence'
						WHEN is_mandatory_date_missing = 1 THEN 'Mandatory date missing'
						ELSE 'Valid record'
					END AS validation_message
				FROM mapped_corporate_actions;
				
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
