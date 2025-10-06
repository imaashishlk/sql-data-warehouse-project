/*
===============================================
STORED PROCEDURE: LOAD SILVER LAYER (BRONZE -> SILVER)
===============================================

Purpose of the script:
  This script loads tables with data in the 'silver' schema with transformations in bronze layer.
  It performs the Extract, Transform and Load operations to populate the 'silver' schema tables.
  Following actions are performed:
    1) Truncating the tables such that it is empty before loading data.
    2) Transformations on bronze tables to load clean data.

Parameters: None
  The stored procedure do not accept any parameters / arguments and does not return
  any value.

Usage Example:
  EXEC silver.load_silver;

WARNING:
  Running this script would truncate the tables already present in the 'silver' schema. 
  Please consider checking it beforehand to eliminate potential data loss. 
  Proceed with caution.
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		-- Logging in the start timestamp
		SET @batch_start_time = GETDATE();

		PRINT '================================';
		PRINT 'LOADING SILVER LAYER';
		PRINT '================================';

		PRINT '--------------------------------';
		PRINT 'LOADING CRM TABLES';
		PRINT '--------------------------------';

		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;

		PRINT '>> Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname),
		TRIM(cst_lastname),
		CASE WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
			 WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
			 ELSE 'n/a'
		END AS cst_marital_status,
		CASE WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
			 WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
			 ELSE 'n/a'
		END AS cst_gndr,
		cst_create_date
		FROM 
		(
			SELECT cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS ranking
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		) 
		AS sq
		WHERE ranking = 1;

		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT '>> Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
		SELECT 
		prd_id,
		REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Aligning it with px_cat_g1v2
		SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Aligning it with sales_details
		prd_nm, 
		ISNULL(prd_cost, 0) AS prd_cost,
		CASE UPPER(TRIM(prd_line))
			 WHEN 'M' THEN 'Mountain'
			 WHEN 'R' THEN 'Road'
			 WHEN 'S' THEN 'Other Sales'
			 WHEN 'T' THEN 'Touring'
			 ELSE 'n/a'
		END AS prd_line,
		CAST(prd_start_dt AS DATE) AS prd_start_dt,
		CAST(LEAD(prd_start_dt - 1) OVER (PARTITION BY prd_key ORDER BY prd_start_dt ASC) AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info;

		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;

		PRINT '>> Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (sls_ord_num,sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
		SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			 ELSE CONVERT(DATE, CONVERT(NVARCHAR(50), sls_order_dt)) -- Converting int type to DATE
		END AS sls_order_dt,
		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			 ELSE CONVERT(DATE, CONVERT(NVARCHAR(50), sls_ship_dt)) -- Converting int type to DATE
		END AS sls_ship_dt,
		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			 ELSE CONVERT(DATE, CONVERT(NVARCHAR(50), sls_due_dt)) -- Converting int type to DATE
		END AS sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales <= 0 
			 THEN ABS(sls_price) * sls_quantity
			 ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <= 0 
			 THEN ABS(sls_sales) / sls_quantity
			 ELSE sls_price
		END AS sls_price
		FROM bronze.crm_sales_details;

		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;

		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
		SELECT
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
			 ELSE cid
		END AS cid,
		CASE WHEN bdate > GETDATE() THEN NULL
			 ELSE bdate
		END AS bdate,
		CASE WHEN gen IS NULL OR gen = '' THEN 'n/a'
			 WHEN gen = 'M' THEN 'Male'
			 WHEN gen = 'F' THEN 'Female'
			 ELSE TRIM(gen)
		END AS gen
		FROM bronze.erp_cust_az12;

		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;

		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (cid, cntry)
		SELECT
		REPLACE(cid, '-', '') AS cid,
		CASE WHEN TRIM(cntry) IN ('USA', 'US') THEN 'United States'
			 WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			 WHEN cntry IS NULL OR cntry = '' THEN 'n/a'
			 ELSE TRIM(cntry)
		END AS cntry
		FROM bronze.erp_loc_a101;

		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
		SELECT 
		id,
		cat,
		subcat,
		maintenance
		FROM bronze.erp_px_cat_g1v2;

		-- Logging the script end timestamp
		SET @batch_end_time = GETDATE();

		PRINT '================================';
		PRINT 'LOADING SILVER LAYER COMPLETED';
		PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '================================';
	
	END TRY
	BEGIN CATCH
		PRINT '================================';
		PRINT 'ERROR WHILE PREPARING SILVER LAYER';
		PRINT 'Error Message ' + ERROR_MESSAGE();
		PRINT 'Error Number ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '================================';
	END CATCH
END
