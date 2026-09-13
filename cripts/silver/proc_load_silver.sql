--CUSTOMER
INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)

SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE 
		WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
		WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
		ELSE 'n/a'
	END AS cst_marital_status,	
	CASE 
		WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
		WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
		ELSE 'n/a'
	END AS cst_gndr,
	cst_create_date
FROM(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	) AS t
WHERE flag_last=1;


--PRODUCT
INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)

SELECT 
	prd_id,
	REPLACE(SUBSTRING (prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
	TRIM(prd_nm) AS prd_nm,
	CAST(COALESCE(prd_cost,0) AS INT) prd_cost,
	CASE UPPER(TRIM(prd_line)) 
		WHEN 'M' THEN 'Mountain'
		WHEN 'R' THEN 'Road'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		ELSE 'n/a'
	END AS prd_line,
	prd_start_dt,
	CASE 
		WHEN crm_prd_info.prd_end_dt < prd_start_dt 
		THEN LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt ASC) - 1 
		--возвращаем оригинальную дату окончания, если оверлаппинга нет
		ELSE bronze.crm_prd_info.prd_end_dt
		END AS prd_end_dt
FROM bronze.crm_prd_info;

--SALES DETAILS
INSERT INTO silver.crm_sales_details( 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dT,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)

SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	-- чем LENGTH(CAST(sls_ship_dt AS VARCHAR)!=8 я использовал FLOOR(LOG(sls_order_dt))+1!=8 т.к. быстрее
	CASE WHEN sls_order_dt=0 OR FLOOR(LOG(sls_order_dt))+1!=8 THEN NULL
	 	 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt,
	CASE WHEN sls_ship_dt=0 OR FLOOR(LOG(sls_ship_dt))+1!=8 THEN NULL
	 	 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	CASE WHEN sls_due_dt=0 OR FLOOR(LOG(sls_due_dt))+1!=8 THEN NULL
	 	 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales!=sls_quantity*ABS(sls_price) THEN sls_quantity*sls_price
		 ELSE sls_sales
	END AS sls_sales,
	sls_quantity,
	CASE WHEN sls_price<0 THEN ABS(sls_price) 
		 WHEN sls_price IS NULL OR sls_price=0 THEN sls_sales/sls_quantity
		 ELSE sls_price
	END AS sls_price
FROM bronze.crm_sales_details
;
