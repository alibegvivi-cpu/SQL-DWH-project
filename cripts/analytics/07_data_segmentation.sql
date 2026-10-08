/*
===============================================================================
Анализ сегментации данных
===============================================================================
Цель:
    - Группировка данных по смысловым категориям для получения целевых инсайтов.
    - Сегментация клиентов, категоризация продуктов или региональный анализ.

Используемые функции SQL:
    - CASE: Определение пользовательской логики сегментации.
    - GROUP BY: Группировка данных по созданным сегментам.
===============================================================================
*/

/* Сегментация продуктов по ценовым диапазонам (себестоимости) и
подсчет количества продуктов, попадающих в каждый сегмент */
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;


/* Группировка клиентов по трем сегментам на основе их покупательского поведения:
	- VIP: Клиенты с историей покупок от 12 месяцев и расходами более €5,000.
	- Regular: Клиенты с историей покупок от 12 месяцев, но расходами €5,000 или менее.
	- New: Клиенты, чья история покупок («продолжительность жизни») менее 12 месяцев.
А также подсчет общего количества клиентов в каждой группе.
*/
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,
        -- Адаптация под Postgres: разница между датами в месяцах
        (EXTRACT(YEAR FROM age(MAX(f.order_date), MIN(f.order_date))) * 12 + 
         EXTRACT(MONTH FROM age(MAX(f.order_date), MIN(f.order_date)))) AS lifespan
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT 
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT 
        customer_key, -- Добавлено (в исходном коде колонка была пропущена для подзапроса)
        CASE 
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) AS segmented_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;
