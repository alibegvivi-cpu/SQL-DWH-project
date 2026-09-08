
CREATE OR REPLACE PROCEDURE bronze.load_bronze()
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
        RAISE NOTICE 'ЗАГРУЗКА БРОНЗОВОГО СЛОЯ';
        RAISE NOTICE '================================================';

        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE 'Загрузка таблиц CRM';
        RAISE NOTICE '------------------------------------------------';

        -- 1. Таблица crm_cust_info
        v_start_time := clock_timestamp(); -- Засекаем время для этой таблицы
        RAISE NOTICE '>> Очистка таблицы: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;
        
        RAISE NOTICE '>> Импорт данных в: bronze.crm_cust_info';
        COPY bronze.crm_cust_info
        FROM 'D:\sql\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
        
        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';

        -- 2. Таблица crm_prd_info
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        RAISE NOTICE '>> Импорт данных в: bronze.crm_prd_info';
        COPY bronze.crm_prd_info
        FROM 'D:\sql\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
        
        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';

        -- 3. Таблица crm_sales_details
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        
        RAISE NOTICE '>> Импорт данных в: bronze.crm_sales_details';
        COPY bronze.crm_sales_details
        FROM 'D:\sql\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
        
        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';

        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE 'Загрузка таблиц ERP';
        RAISE NOTICE '------------------------------------------------';
        
        -- 4. Таблица erp_loc_a101
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;
        
        RAISE NOTICE '>> Импорт данных в: bronze.erp_loc_a101';
        COPY bronze.erp_loc_a101
        FROM 'D:\sql\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
        
        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';

        -- 5. Таблица erp_cust_az12
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        
        RAISE NOTICE '>> Импорт данных в: bronze.erp_cust_az12';
        COPY bronze.erp_cust_az12
        FROM 'D:\sql\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
        
        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';

        -- 6. Таблица erp_px_cat_g1v2
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Очистка таблицы: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        
        RAISE NOTICE '>> Импорт данных в: bronze.erp_px_cat_g1v2';
        COPY bronze.erp_px_cat_g1v2
        FROM 'D:\sql\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
        
        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Время загрузки: % сек.', ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 3);
        RAISE NOTICE '>> -------------';

        v_batch_end_time := clock_timestamp();
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'Загрузка Бронзового слоя успешно завершена';
        RAISE NOTICE '   - Общее время выполнения: % сек.', ROUND(EXTRACT(EPOCH FROM (v_batch_end_time - v_batch_start_time)), 3);
        RAISE NOTICE '==========================================';

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT, v_error_code = RETURNED_SQLSTATE;
        
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ПРОИЗОШЛА ОШИБКА ПРИ ЗАГРУЗКЕ БРОНЗОВОГО СЛОЯ';
        RAISE NOTICE 'Текст ошибки: %', v_error_msg;
        RAISE NOTICE 'Код ошибки (SQLSTATE): %', v_error_code;
        RAISE NOTICE '==========================================';
    END;
END;
$$;
