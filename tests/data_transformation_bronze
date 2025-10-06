/*
=====================================================
DATA TRANSFORMATION: Logics used in transforming data
=====================================================

Purpose of the script:
  These scripts were used in checking the quality of data and has been used to rectify
  existing data to be forwarded to the 'silver' schema.
*/

-- =======================================
--	CHECKING bronze.crm_prd_info		
-- =======================================

/* Checking if primary keys have duplicates */
SELECT prd_id, count(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING count(*) > 1;

/* Checking if the prd_nm should be trimmed or has spaces around */
SELECT prd_nm FROM bronze.crm_prd_info
WHERE TRIM(prd_nm) != prd_nm;

-- =======================================
--	CHECKING bronze.crm_cust_info		
-- =======================================

/* Removing duplicates */ 
SELECT 
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
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


/* Checking if cst_firstname needs trimming */
SELECT
(cst_firstname)
FROM 
bronze.crm_cust_info
WHERE TRIM(cst_firstname) != cst_firstname;

/* Checking if cst_lastname needs trimming */
SELECT
(cst_lastname)
FROM 
bronze.crm_cust_info
WHERE TRIM(cst_lastname) != cst_lastname;

/* Analyzing distinct data: cst_marital_status */
SELECT
DISTINCT cst_marital_status
FROM
bronze.crm_cust_info;

/* Rectifying the data: cst_marital_status */
SELECT 
CASE WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
	 WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
	 ELSE 'n/a'
END AS cst_marital_status
FROM
bronze.crm_cust_info;


/* Analyzing distinct data: cst_gndr */
SELECT
DISTINCT cst_gndr
FROM
bronze.crm_cust_info;

/* Rectifying the data: cst_gndr */
SELECT 
CASE WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
	 WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
	 ELSE 'n/a'
END AS cst_gndr
FROM
bronze.crm_cust_info;

-- =======================================
--	CHECKING bronze.erp_px_cat_g1v2	
-- =======================================

/* No used category CO_PD */
SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2 WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info);

/* Checking if cat need trimming */
SELECT cat FROM bronze.erp_px_cat_g1v2 WHERE cat != TRIM(cat);

/* Analyzing distinct data: maintenance */
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;


-- =======================================
--	CHECKING bronze.erp_loc_a101	
-- =======================================

/* Analyzing distinct data: erp_loc_a101 */
SELECT DISTINCT cid FROM bronze.erp_loc_a101 
WHERE cid NOT LIKE 'AW-%';

/* Analyzing distinct data: erp_loc_a101 */
SELECT DISTINCT cid FROM bronze.erp_loc_a101 
WHERE cid IS NULL;

/* Outcome: Looks like it is OK! It just needs removing an extra '-' from the middle of the string */
SELECT
REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101;

/* Analyzing the data against it's relation: erp_loc_a101 */
SELECT
REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info);


/* Checking the data: cntry */
-- Outcome: It seems like Germany = (DE, Germany), USA = (USA, United States, US), NULLs
-- Country Bracket = [Germany, United States, Australia, United Kingdom, Canada, France, n/a]
SELECT DISTINCT cntry FROM bronze.erp_loc_a101;

/* Fix to the cntry */
SELECT
DISTINCT
CASE WHEN cntry IN ('USA', 'United States', 'US') THEN 'United States'
	 WHEN cntry IN ('DE', 'Germany') THEN 'Germany'
	 WHEN cntry IS NULL OR cntry = '' THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101;

-- =======================================
--	CHECKING bronze.crm_sales_details	
-- =======================================

/* Searchibg for NULLS and negative values: sls_order_dt */
SELECT * FROM bronze.crm_sales_details WHERE sls_order_dt IS NULL OR sls_order_dt <= 0;

/* Searchibg for NULLS and negative values: sls_ship_dt */
SELECT * FROM bronze.crm_sales_details WHERE sls_ship_dt IS NULL OR sls_ship_dt <= 0;

/* Searchibg for NULLS and negative values: sls_due_dt */
SELECT * FROM bronze.crm_sales_details WHERE sls_due_dt IS NULL OR sls_due_dt <= 0;

/* Converting into date format: sls_ship_dt */
SELECT CONVERT(DATE, CONVERT(NVARCHAR(50), sls_ship_dt)) 
FROM bronze.crm_sales_details
ORDER BY sls_ship_dt DESC;

/* Converting into date format: sls_due_dt */
SELECT CONVERT(DATE, CONVERT(NVARCHAR(50), sls_due_dt)) 
FROM bronze.crm_sales_details
ORDER BY sls_due_dt DESC;

/* Identifying the problem: sls_order_dt */
-- Outcome: Has irregular date values and nulls
SELECT sls_order_dt 
FROM bronze.crm_sales_details
WHERE LEN(sls_order_dt) != 8 OR sls_order_dt <= 0 OR sls_order_dt IS NULL;

/* Checking the data: sls_ord_num */
SELECT sls_ord_num, count(*) AS freq
FROM 
bronze.crm_sales_details
GROUP BY sls_ord_num;

/* Analyzing the data against it's relation: sls_prd_key and prd_key of crm_prd_info */
SELECT * FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

/* Analyzing the data against it's relation: sls_cust_id and cst_id of crm_cust_info */
SELECT * FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

/* Checking the data: sls_sales */
SELECT sls_sales FROM bronze.crm_sales_details
WHERE sls_sales <= 0 OR sls_sales IS NULL;

/* Checking the data: sls_price */
SELECT 
sls_price, 
sls_quantity, 
sls_sales 
FROM bronze.crm_sales_details
WHERE sls_price <= 0 OR sls_price IS NULL OR sls_quantity <= 0 OR sls_quantity IS NULL OR sls_sales <= 0 OR sls_sales IS NULL;

/* Checking the data: sls_quantity */
-- Outcome: Good that sls_quantity is clean; Has grounds for quantity which helps to revive sls_price and sls_sales
SELECT sls_quantity
FROM bronze.crm_sales_details
WHERE sls_quantity <= 0 OR sls_quantity IS NULL;

/* Fixing the data: sls_price using sls_quantity */
SELECT
CASE WHEN sls_price IS NULL OR sls_price <= 0 
THEN ABS(sls_sales) / sls_quantity
ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_price <= 0 OR sls_price IS NULL;

/* Fixing the data: sls_sales using sls_quantity */
SELECT
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 
THEN ABS(sls_price) * sls_quantity
ELSE sls_sales
END AS sls_sales
FROM bronze.crm_sales_details
WHERE sls_price <= 0 OR sls_price IS NULL;

-- =======================================
--	CHECKING bronze.erp_cust_az12	
-- =======================================

/* Checking the data: cid */
SELECT cid
FROM bronze.erp_cust_az12
WHERE TRIM(cid) != cid OR cid IS NULL;

/* Checking the data: bdate */
SELECT bdate
FROM bronze.erp_cust_az12
WHERE bdate IS NULL;

/* Checking the data: bdate against current date */
-- Outcome: Found birth dates exceeding current date (bad data)
-- Action: Can be set to NULLs
SELECT bdate
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE();

/* Checking distinct data: gen */
-- Outcome: Seems like there are NULLS, abbreviated and non-abbreviated data although cardinality is less
-- Needs cure
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;

/* Fix to the gen */
SELECT DISTINCT
CASE WHEN gen IS NULL OR gen = '' THEN 'n/a'
	 WHEN gen = 'M' THEN 'Male'
	 WHEN gen = 'F' THEN 'Female'
	 ELSE gen
END AS gen
FROM bronze.erp_cust_az12;

/* Analyzing the data against it's relation: cid and cst_key of crm_cust_info */
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END AS cid
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)
;
