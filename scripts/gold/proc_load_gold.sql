/*
===============================================================================
Stored Procedure: Load Gold Layer (Silver -> Gold)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
	populate the 'gold' schema tables from the 'silver' tables. 
    Actions Performed:
    - Truncates gold tables.
    - Inserts transformed and cleansed data from silver tables into gold tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC gold.load_gold;
===============================================================================
*/

CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Gold Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading Corporate Actions Data Warehouse Tables';
		PRINT '------------------------------------------------';

		-- Loading companies dimension data
        
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_companies';
		TRUNCATE TABLE gold.dim_companies;
		PRINT '>> Inserting Data Into: gold.dim_companies';
		
		INSERT INTO gold.dim_companies
		(
			company_id,
			company_name,
			sector,
			country
		)
		SELECT DISTINCT
			company_id,
			company_name,
			sector,
			country
		FROM silver.mdv_companies;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading securities dimension data
        
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_securities';
		TRUNCATE TABLE gold.dim_securities;
		PRINT '>> Inserting Data Into: gold.dim_securities';
		
		INSERT INTO gold.dim_securities
		(
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
		FROM silver.mdv_securities;
		
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading event types dimension data

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_event_types';
		TRUNCATE TABLE gold.dim_event_types;
		PRINT '>> Inserting Data Into: gold.dim_event_types';
		
		INSERT INTO gold.dim_event_types
		(
			event_type_standard
		)
		SELECT DISTINCT
			event_type_standard
		FROM silver.mdv_corporate_actions
		WHERE event_type_standard <> 'Invalid';

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading dates dimension data

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_dates';
		TRUNCATE TABLE gold.dim_dates;
		PRINT '>> Inserting Data Into: gold.dim_dates';
		
		INSERT INTO gold.dim_dates
		(
			calendar_date,
			day_number,
			day_name,
			day_of_week,
			week_number,
			month_number,
			month_name,
			quarter_number,
			year_number,
			is_weekend
		)
		SELECT DISTINCT
			full_date as calendar_date,
			day AS day_number,
			day_name,
			day_of_week,
			week_of_year AS week_number,
			month AS month_number,
			month_name,
			quarter AS quarter_number,
			year AS year_number,
			is_weekend
		FROM silver.mdv_dates;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading corporate actions fact data

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.fact_corporate_actions';
		TRUNCATE TABLE gold.fact_corporate_actions;
		PRINT '>> Inserting Data Into: gold.fact_corporate_actions';

		INSERT INTO gold.fact_corporate_actions
		(
			action_id,
			company_key,
			security_key,
			event_type_key,
			announcement_date,
			ex_date,
			record_date,
			payment_date,
			dividend_amount,
			currency,
			split_ratio,
			target_company,
			acquirer_company,
			ca_status,
			is_action_id_missing,
			is_event_type_invalid,
			is_company_ticker_mismatch,
			is_date_sequence_invalid,
			is_mandatory_date_missing,
			validation_status,
			validation_message
		)
		SELECT
			ca.action_id,
			dc.company_key,
			ds.security_key,
			det.event_type_key,
			ca.announcement_date,
			ca.ex_date,
			ca.record_date,
			ca.payment_date,
			COALESCE(d.dividend_amount, ca.dividend_amount) AS dividend_amount,
			COALESCE(d.currency, 'INR') AS currency,
			COALESCE(sp.split_ratio, ca.split_ratio) AS split_ratio,
			m.target_company,
			m.acquirer_company,
			ca.ca_status,
			ca.is_action_id_missing,
			ca.is_event_type_invalid,
			ca.is_company_ticker_mismatch,
			ca.is_date_sequence_invalid,
			ca.is_mandatory_date_missing,
			ca.validation_status,
			ca.validation_message
		FROM silver.mdv_corporate_actions ca
		LEFT JOIN gold.dim_companies dc
			ON ca.master_company_name = dc.company_name
		LEFT JOIN gold.dim_securities ds
			ON ca.ticker = ds.ticker
		LEFT JOIN gold.dim_event_types det
			ON ca.event_type_standard = det.event_type_standard
		LEFT JOIN silver.mdv_dividends d
			ON ca.action_id = d.action_id
		LEFT JOIN silver.mdv_splits sp
		ON ca.action_id = sp.action_id
		LEFT JOIN silver.mdv_mergers m
			ON ca.action_id = m.action_id;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Gold Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING GOLD LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
