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
			company_id,
			CASE	UPPER(TRIM(company_name))
					WHEN 'TCS' THEN 'Tata Consultancy Services Limited'
					WHEN 'INFY' THEN 'Infosys Limited'
					WHEN 'RELIANCE' THEN 'Reliance Industries Limited'
					WHEN 'HDFCBANK' THEN 'HDFC Bank Limited'
					WHEN 'ICICIBANK' THEN 'ICICI Bank Limited'
					WHEN 'WIPRO' THEN 'Wipro Limited'
					WHEN 'SBIN' THEN 'State Bank of India Limited'
					WHEN 'AXISBANK' THEN 'Axis Bank Limited'
					ELSE 'n/a'
			END company_name,   -- Normalize company names to readable format
			sector,
			country
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
			security_id,
			ticker,
			isin,
			company_id
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
			event_type_id,
			event_name
		FROM bronze.mdv_event_types
		WHERE event_type_id IS NOT NULL;
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
				TRY_CAST(action_id AS INT) AS action_id,
				UPPER(TRIM(ticker)) AS ticker,

				CASE
					WHEN event_type IN ('DIV', 'Dividend', 'Cash Dividend') THEN 'Dividend'
					WHEN event_type IN ('Split', 'Stock Split') THEN 'Split'
					WHEN event_type = 'MERGER' THEN 'Merger'
					ELSE 'n/a'
				END AS event_type,

				TRY_CONVERT(DATE, NULLIF(TRIM(announcement_date), ''), 105) AS announcement_date,
				TRY_CONVERT(DATE, NULLIF(TRIM(ex_date), ''), 105) AS ex_date,
				TRY_CONVERT(DATE, NULLIF(TRIM(record_date), ''), 105) AS record_date,
				TRY_CONVERT(DATE, NULLIF(TRIM(payment_date), ''), 105) AS payment_date,
				TRY_CAST(NULLIF(TRIM(dividend_amount), '') AS DECIMAL(10,2)) AS dividend_amount,

				CASE
					WHEN split_ratio LIKE '%:%'
							THEN CONCAT(TRY_CONVERT(INT, LEFT(split_ratio, CHARINDEX(':', split_ratio) - 1)),
								':',
								TRY_CONVERT(INT, RIGHT(split_ratio, LEN(split_ratio) - CHARINDEX(':', split_ratio))
								))
					ELSE NULL
				END AS split_ratio,

				CASE
					WHEN status IS NULL OR TRIM(REPLACE(REPLACE(status, CHAR(13), ''), CHAR(10), '')) = '' THEN 'UNKNOWN'
					ELSE UPPER(TRIM(REPLACE(REPLACE(status, CHAR(13), ''), CHAR(10), '')))
				END AS ca_status
				FROM bronze.mdv_corporate_actions
				WHERE TRY_CAST(action_id AS INT) IS NOT NULL
				AND TRY_CAST(action_id AS INT) > 0
		),
		mapped_corporate_actions AS
		(
			SELECT
			ca.*,
			c.company_id,
			c.company_name,
			s.security_id,
			s.ticker AS master_ticker,
			et.event_type_id
		FROM bronze2silver_corporate_actions ca
		INNER JOIN silver.mdv_securities s
		ON ca.ticker = s.ticker
		INNER JOIN silver.mdv_companies c
		ON s.company_id = c.company_id
		INNER JOIN silver.mdv_event_types et
		ON ca.event_type = et.event_name
		)
		INSERT INTO silver.mdv_corporate_actions
		(
			action_id,
			company_id,
			security_id,
			event_type_id,
			company_name,
			ticker,
			event_type,
			announcement_date,
			ex_date,
			record_date,
			payment_date,
			dividend_amount,
			split_ratio,
			ca_status
		)
		SELECT DISTINCT
			action_id,
			company_id,
			security_id,
			event_type_id,
			company_name,
			ticker,
			event_type,
			announcement_date,
			ex_date,
			record_date,
			payment_date,

			CASE
				WHEN event_type = 'Dividend' THEN dividend_amount
				ELSE NULL
			END AS dividend_amount,

			CASE
				WHEN event_type = 'Split' THEN split_ratio
				ELSE NULL
			END AS split_ratio,

			ca_status
		FROM mapped_corporate_actions
		WHERE action_id IS NOT NULL
			AND company_id IS NOT NULL
			AND security_id IS NOT NULL
			AND event_type_id IS NOT NULL
			AND event_type IN ('Dividend', 'Split', 'Merger')
			/* Date validations */
			AND (announcement_date IS NULL OR ex_date IS NULL OR ex_date >= announcement_date)
			AND (announcement_date IS NULL OR record_date IS NULL OR record_date >= announcement_date)
			AND (announcement_date IS NULL OR payment_date IS NULL OR payment_date >= announcement_date)
			AND (ex_date IS NULL OR record_date IS NULL OR record_date >= ex_date)
			AND (ex_date IS NULL OR payment_date IS NULL OR payment_date >= ex_date)
			AND (record_date IS NULL OR payment_date IS NULL OR payment_date >= record_date)
			/* Event-specific validations */
			AND (event_type <> 'Dividend' OR dividend_amount IS NOT NULL)
			AND (event_type <> 'Split' OR split_ratio IS NOT NULL)
			AND NOT (event_type = 'Dividend' AND split_ratio IS NOT NULL)
			AND NOT (event_type = 'Split' AND dividend_amount IS NOT NULL);

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
			TRY_CONVERT(INT, d.action_id) AS action_id,
			TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(d.dividend_amount), '')) AS dividend_amount,
			UPPER(TRIM(d.currency)) AS currency
			FROM bronze.mdv_dividends d
			INNER JOIN silver.mdv_corporate_actions ca
			ON TRY_CONVERT(INT, d.action_id) = ca.action_id
			INNER JOIN silver.mdv_event_types et
			ON ca.event_type_id = et.event_type_id
			WHERE et.event_name = 'Dividend'
			AND TRY_CONVERT(INT, d.action_id) IS NOT NULL
			AND TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(d.dividend_amount), '')) IS NOT NULL
			AND NULLIF(TRIM(d.currency), '') IS NOT NULL;

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
				TRY_CONVERT(INT, s.action_id) AS action_id,
				NULLIF(TRIM(s.split_ratio), '') AS split_ratio
		FROM bronze.mdv_splits s
		INNER JOIN silver.mdv_corporate_actions ca
		ON TRY_CONVERT(INT, s.action_id) = ca.action_id
		INNER JOIN silver.mdv_event_types et
		ON ca.event_type_id = et.event_type_id
		WHERE et.event_name = 'Split'
		AND TRY_CONVERT(INT, s.action_id) IS NOT NULL
		AND NULLIF(TRIM(s.split_ratio), '') IS NOT NULL;

	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading mergers data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_mergers';
		TRUNCATE TABLE silver.mdv_mergers;
		PRINT '>> Inserting Data Into: silver.mdv_mergers';
		INSERT INTO silver.mdv_mergers (
				action_id,
				target_company,
				acquirer_company
			)
		SELECT DISTINCT
				TRY_CONVERT(INT, m.action_id) AS action_id,
				UPPER(TRIM(m.target_company)) AS target_company,
				UPPER(TRIM(m.acquirer_company)) AS acquirer_company
		FROM bronze.mdv_mergers m
		INNER JOIN silver.mdv_corporate_actions ca
		ON TRY_CONVERT(INT, m.action_id) = ca.action_id
		INNER JOIN silver.mdv_event_types et
		ON ca.event_type_id = et.event_type_id
		WHERE et.event_name = 'Merger'
		AND TRY_CONVERT(INT, m.action_id) IS NOT NULL
		AND NULLIF(TRIM(m.target_company), '') IS NOT NULL
		AND NULLIF(TRIM(m.acquirer_company), '') IS NOT NULL
		AND UPPER(TRIM(m.target_company)) <> UPPER(TRIM(m.acquirer_company));

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading dates data
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.mdv_dates';
		TRUNCATE TABLE silver.mdv_dates;
		PRINT '>> Inserting Data Into: silver.mdv_dates';
		INSERT INTO silver.mdv_dates (
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
			TRY_CONVERT(DATE, NULLIF(TRIM(full_date), ''), 105) AS full_date,
			day,
			day_name,
			day_of_week,
			week_of_year,
			month,
			month_name,
			quarter,
			year,
			is_weekend
			FROM bronze.mdv_dates
			WHERE TRY_CONVERT(DATE, NULLIF(TRIM(full_date), ''), 105) IS NOT NULL;
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

--Execution of silver layer--

EXEC silver.load_silver
