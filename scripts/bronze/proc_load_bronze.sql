/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading Corporate Actions Data Warehouse Tables';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_companies';
		TRUNCATE TABLE bronze.mdv_companies;
		PRINT '>> Inserting Data Into: bronze.mdv_companies';
		BULK INSERT bronze.mdv_companies
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\companies.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_securities';
		TRUNCATE TABLE bronze.mdv_securities;
		PRINT '>> Inserting Data Into: bronze.mdv_securities';
		BULK INSERT bronze.mdv_securities
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\securities.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_event_types';
		TRUNCATE TABLE bronze.mdv_event_types;
		PRINT '>> Inserting Data Into: bronze.mdv_event_types';
		BULK INSERT bronze.mdv_event_types
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\event_types.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_corporate_actions';
		TRUNCATE TABLE bronze.mdv_corporate_actions;
		PRINT '>> Inserting Data Into: bronze.mdv_corporate_actions';
		BULK INSERT bronze.mdv_corporate_actions
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\corporate_actions.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_dividends';
		TRUNCATE TABLE bronze.mdv_dividends;
		PRINT '>> Inserting Data Into: bronze.mdv_dividends';
		BULK INSERT bronze.mdv_dividends
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\dividends.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_splits';
		TRUNCATE TABLE bronze.mdv_splits;
		PRINT '>> Inserting Data Into: bronze.mdv_splits';
		BULK INSERT bronze.mdv_splits
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\splits.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_mergers';
		TRUNCATE TABLE bronze.mdv_mergers;
		PRINT '>> Inserting Data Into: bronze.mdv_mergers';
		BULK INSERT bronze.mdv_mergers
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\mergers.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.mdv_dates';
		TRUNCATE TABLE bronze.mdv_dates;
		PRINT '>> Inserting Data Into: bronze.mdv_dates';
		BULK INSERT bronze.mdv_dates
		FROM 'C:\Users\HP\OneDrive\Desktop\SQL\Corporate Actions\Project\datasets\dates.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END

---Execute Bronze Layer Stored Procedure---

EXEC bronze.load_bronze

----Validate Row Counts----

SELECT 'companies' AS table_name, COUNT(*) AS row_count FROM bronze.mdv_companies
UNION ALL
SELECT 'securities', COUNT(*) FROM bronze.mdv_securities
UNION ALL
SELECT 'event_types', COUNT(*) FROM bronze.mdv_event_types
UNION ALL
SELECT 'corporate_actions', COUNT(*) FROM bronze.mdv_corporate_actions
UNION ALL
SELECT 'dividends', COUNT(*) FROM bronze.mdv_dividends
UNION ALL
SELECT 'splits', COUNT(*) FROM bronze.mdv_splits
UNION ALL
SELECT 'mergers', COUNT(*) FROM bronze.mdv_mergers
UNION ALL
SELECT 'dates', COUNT(*) FROM bronze.mdv_dates;
