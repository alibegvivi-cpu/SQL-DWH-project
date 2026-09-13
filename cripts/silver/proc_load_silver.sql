CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE 
    -- Объявляем переменные для точного замера времени
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_batch_start_time TIMESTAMP;
    v_batch_end_time TIMESTAMP;
    
    v_error_msg TEXT;
    v_error_code TEXT;
BEGIN
    BEGIN
        v_batch_start_time := clock_timestamp(); -- Засекаем общее время
        
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ЗАГРУЗКА СЕРЕБРЯНОГО СЛОЯ';
        RAISE NOTICE '================================================';

        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE 'Загрузка таблиц CRM';
        RAISE NOTICE '------------------------------------------------';

        --1. Таблица customer info
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        RAISE NOTICE '>> Импорт данных в: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info(
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

        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки crm_cust_info: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';


        --2. Таблица crm_prd_info
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        RAISE NOTICE '>> Импорт данных в: silver.crm_prd_info';
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

        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки crm_prd_info: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';


        --3. Таблица crm_sales_details
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        RAISE NOTICE '>> Импорт данных в: silver.crm_sales_details';
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
        FROM bronze.crm_sales_details;

        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки crm_sales_details: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';


        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE 'Загрузка таблиц ERP';
        RAISE NOTICE '------------------------------------------------';

        --4. Таблица erp_cust_az12
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        RAISE NOTICE '>> Импорт данных в: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT 
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
                 ELSE cid
            END AS cid,
            CASE WHEN bdate>CURRENT_DATE THEN NULL
            ELSE bdate
            END AS bdate,
            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
                 ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;

        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки erp_cust_az12: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';


        --5. Таблица erp_loc_a101
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        RAISE NOTICE '>> Импорт данных в: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101(
        cid,
        cntry
        )
        SELECT 
        REPLACE(cid,'-','') AS cid,
        CASE WHEN cntry IS NULL OR TRIM(cntry)='' THEN 'n/a' 
             WHEN cntry='US' OR cntry='USA' THEN 'United States'
             WHEN cntry='DE' THEN 'Germany' 
             ELSE TRIM(cntry)
        END AS cntry
        FROM bronze.erp_loc_a101;

        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки erp_loc_a101: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';


        --6. Таблица erp_px_cat_g1v2
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        RAISE NOTICE '>> Импорт данных в: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2( 
        id,
        cat,
        subcat,
        maintenance
        )
        SELECT 
        id,
        cat,
        subcat,
        maintenance
        FROM bronze.erp_px_cat_g1v2;

        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки erp_px_cat_g1v2: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';


        v_batch_end_time := clock_timestamp();
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'Загрузка Серебряного слоя успешно завершена';
        RAISE NOTICE '   - Общее время выполнения: % сек.', ROUND(EXTRACT(EPOCH FROM (v_batch_end_time - v_batch_start_time)), 3);
        RAISE NOTICE '==========================================';

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT, v_error_code = RETURNED_SQLSTATE;
        
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ПРОИЗОШЛА ОШИБКА ПРИ ЗАГРУЗКЕ СЕРЕБРЯНОГО СЛОЯ';
        RAISE NOTICE 'Текст ошибки: %', v_error_msg;
        RAISE NOTICE 'Код ошибки (SQLSTATE): %', v_error_code;
        RAISE NOTICE '==========================================';
    END;
END;
$$;
