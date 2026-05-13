/*
===============================================================================
Stored Procedure: Load Gold Layer (Gold Views -> Gold)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
	populate the 'gold' schema tables from the 'gold' views. 
    Actions Performed:
    - Truncates gold tables.
    - Inserts transformed and cleansed data from gold views into gold tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC gold.load_gold;
===============================================================================
*/

USE CorporateActions
GO

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
		PRINT '>> Truncating Table: gold.dim_companies_tbl';
		TRUNCATE TABLE gold.dim_companies_tbl;
		PRINT '>> Inserting Data Into: gold.dim_companies_tbl';
		
		INSERT INTO gold.dim_companies_tbl (
			company_key,
			company_id,
			company_name,
			sector,
			country
		)
		SELECT
			company_key,
			company_id,
			company_name,
			sector,
			country
		FROM gold.dim_companies;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading securities dimension data
        
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_securities_tbl';
		TRUNCATE TABLE gold.dim_securities_tbl;
		PRINT '>> Inserting Data Into: gold.dim_securities_tbl';
		
		INSERT INTO gold.dim_securities_tbl (
			security_key,
			security_id,
			ticker,
			isin
		)
		SELECT
			security_key,
			security_id,
			ticker,
			isin
		FROM gold.dim_securities;
		
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading event types dimension data

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_event_types_tbl';
		TRUNCATE TABLE gold.dim_event_types_tbl;
		PRINT '>> Inserting Data Into: gold.dim_event_types_tbl';
		
		INSERT INTO gold.dim_event_types_tbl (
			event_type_key,
			event_type_id,
			event_name
		)
		SELECT
			event_type_key,
			event_type_id,
			event_name
		FROM gold.dim_event_types;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading dates dimension data

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_dates_tbl';
		TRUNCATE TABLE gold.dim_dates_tbl;
		PRINT '>> Inserting Data Into: gold.dim_dates_tbl';
		
		INSERT INTO gold.dim_dates_tbl
		(
			date_key,
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
		SELECT
			date_key,
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
		FROM gold.dim_dates;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading corporate actions fact data

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.fact_corporate_actions_tbl';
		TRUNCATE TABLE gold.fact_corporate_actions_tbl;
		PRINT '>> Inserting Data Into: gold.fact_corporate_actions_tbl';

		INSERT INTO gold.fact_corporate_actions_tbl
		(
			action_id,
			company_key,
			security_key,
			event_type_key,
			announcement_date_key,
			ex_date_key,
			record_date_key,
			payment_date_key,
			currency,
			dividend_amount,
			split_ratio,
			ca_status
		)
		SELECT
			f.action_id,
			f.company_key,
			f.security_key,
			f.event_type_key,
			f.announcement_date_key,
			f.ex_date_key,
			f.record_date_key,
			f.payment_date_key,
			d.currency,
			f.dividend_amount,
			s.split_ratio,
			f.ca_status
		FROM gold.fact_corporate_actions f
		LEFT JOIN silver.mdv_dividends d
		ON f.action_id = d.action_id
		LEFT JOIN silver.mdv_splits s
		ON f.action_id = s.action_id;

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
