/*
===============================================
DDL SCRIPT: CREATE GOLD LAYER
===============================================

Purpose of the script:
  This script creates views in the 'gold' schema. The gold layer
  represents the final dimension and fact tables in star schema.
  
Usage:
	The views can be directly queried for analytics and reporting.
*/

===============================================
Create Dimension View: gold.dim_customers
===============================================
IF OBJECT_ID ('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key, -- Surrogate Key
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	li.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		 ELSE COALESCE(ai.gen, 'n/a')
	END AS gender,
	ai.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ai
ON ci.cst_key = ai.cid
LEFT JOIN silver.erp_loc_a101 li
ON ci.cst_key = li.cid;
GO

===============================================
Create Dimension View: gold.dim_products
===============================================
IF OBJECT_ID ('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY pinfo.prd_start_dt, pinfo.prd_key) AS product_key,
	pinfo.prd_id AS product_id,
	pinfo.prd_key AS product_number,
	pinfo.prd_nm AS product_name,
	pinfo.cat_id AS category_id,
	pcat.cat AS category,
	pcat.subcat AS subcategory,
	pcat.maintenance AS maintenance,
	pinfo.prd_cost AS cost,
	pinfo.prd_line AS product_line,
	pinfo.prd_start_dt AS start_date
FROM silver.crm_prd_info pinfo
LEFT JOIN silver.erp_px_cat_g1v2 pcat 
ON pinfo.cat_id = pcat.id
WHERE prd_end_dt IS NULL;
GO

===============================================
Create Fact View: gold.fact_sales
===============================================
IF OBJECT_ID ('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
	sls_ord_num AS order_number,
	dc.customer_key,
	dp.product_key,
	sls_order_dt AS order_date,
	sls_ship_dt AS shipping_date,
	sls_due_dt AS due_date,
	sls_sales AS sales_amount,
	sls_quantity AS quantity,
	sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customers dc
ON dc.customer_id = sd.sls_cust_id
LEFT JOIN gold.dim_products dp
ON dp.product_number = sd.sls_prd_key;
GO
