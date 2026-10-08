/*
===============================================================================
Отчет по клиентам (Customer Report)
===============================================================================
Цель:
    - Этот отчет объединяет ключевые метрики и особенности поведения клиентов.

Основные задачи:
    1. Сбор базовых полей, таких как имена, возраст и детали транзакций.
    2. Сегментация клиентов по категориям (VIP, Regular, New) и возрастным группам.
    3. Агрегация метрик на уровне клиента:
       - всего заказов
       - общий объем продаж
       - общее количество купленных товаров
       - всего уникальных продуктов
       - продолжительность «жизни» клиента (lifespan в месяцах)
    4. Расчет ключевых бизнес-KPI:
       - давность покупки (recency — месяцев с последнего заказа)
       - средний чек (AVO — Average Order Value)
       - средние ежемесячные траты
===============================================================================
*/

-- =============================================================================
-- Создание отчета: gold.report_customers
-- =============================================================================

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Базовый запрос: Извлечение основных колонок из таблиц
---------------------------------------------------------------------------*/
SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    -- Адаптация под Postgres: Расчет возраста клиента на текущую дату
    EXTRACT(YEAR FROM age(CURRENT_DATE, c.birthdate)) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
WHERE f.order_date IS NOT NULL
)

, customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Агрегация по клиентам: Суммирование ключевых метрик на уровне каждого клиента
---------------------------------------------------------------------------*/
SELECT 
    customer_key,
    customer_number,
    customer_name,
    age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    -- Расчет продолжительности жизни клиента в месяцах
    (EXTRACT(YEAR FROM age(MAX(order_date), MIN(order_date))) * 12 + 
     EXTRACT(MONTH FROM age(MAX(order_date), MIN(order_date)))) AS lifespan
FROM base_query
GROUP BY 
    customer_key,
    customer_number,
    customer_name,
    age
)
/*---------------------------------------------------------------------------
3) Финальный выбор: Расчет сегментов и бизнес-KPI
---------------------------------------------------------------------------*/
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE 
         WHEN age < 20 THEN 'Under 20'
         WHEN age BETWEEN 20 AND 29 THEN '20-29'
         WHEN age BETWEEN 30 AND 39 THEN '30-39'
         WHEN age BETWEEN 40 AND 49 THEN '40-49'
         ELSE '50 and above'
    END AS age_group,
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    -- Сколько месяцев прошло с даты последнего заказа (Recency)
    (EXTRACT(YEAR FROM age(CURRENT_DATE, last_order_date)) * 12 + 
     EXTRACT(MONTH FROM age(CURRENT_DATE, last_order_date))) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products, -- Добавлена пропущенная запятая
    lifespan,
    -- Расчет среднего чека (AOV) с защитой от деления на ноль
    CASE WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders
    END AS avg_order_value,
    -- Расчет средних ежемесячных трат
    CASE WHEN lifespan = 0 THEN total_sales
         ELSE total_sales / lifespan
    END AS avg_monthly_spend
FROM customer_aggregation;
