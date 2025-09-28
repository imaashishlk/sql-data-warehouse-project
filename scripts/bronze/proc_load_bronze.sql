/*
===============================================
STORED PROCEDURE: LOAD BRONZE LAYER (SOURCE -> BRONZE)
===============================================

Purpose of the script:
  This script loads tables with data in the 'bronze' schema with CSV files.
  Following actions are performed:
    1) Truncating the tables such that it is empty before loading data.
    2) BULK INSERT is performed to load data quickly and efficiently.

Parameters: None
  The stored procedure do not accept any parameters / arguments and does not return
  any value.

Usage Example:
  EXEC bronze.load_bronze;

WARNING:
  Running this script would truncate the tables already present in the 'bronze' schema. 
  Please consider checking it beforehand to eliminate potential data loss. 
  Proceed with caution.
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		-- Logging in the start timestamp
		SET @batch_start_time = GETDATE();

		PRINT '================================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '================================';

		PRINT '--------------------------------';
		PRINT 'LOADING CRM TABLES';
		PRINT '--------------------------------';

		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\aashish\Documents\Data Warehouse Course\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\aashish\Documents\Data Warehouse Course\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\aashish\Documents\Data Warehouse Course\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\aashish\Documents\Data Warehouse Course\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\aashish\Documents\Data Warehouse Course\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\aashish\Documents\Data Warehouse Course\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		-- Logging the script end timestamp
		SET @batch_end_time = GETDATE();

		PRINT '================================';
		PRINT 'LOADING BRONZE LAYER COMPLETED';
		PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '================================';
	
	END TRY
	BEGIN CATCH
		PRINT '================================';
		PRINT 'ERROR WHILE PREPARING BRONZE LAYER';
		PRINT 'Error Message ' + ERROR_MESSAGE();
		PRINT 'Error Number ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '================================';
	END CATCH
END
