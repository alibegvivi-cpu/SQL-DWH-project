/*
===============================================================================
Отчет по продуктам (Product Report)
===============================================================================
Цель:
    - Этот отчет объединяет ключевые метрики продуктов и особенности их продаж.

Основные задачи:
    1. Сбор базовых полей, таких как название продукта, категория, подкатегория и себестоимость.
    2. Сегментация продуктов по выручке для выявления лидеров продаж (High-Performers), среднеранговых (Mid-Range) или аутсайдеров (Low-Performers).
    3. Агрегация метрик на уровне продукта:
       - всего заказов
       - общий объем продаж
       - общее количество проданного товара
       - количество уникальных клиентов
       - продолжительность продаж продукта (lifespan в месяцах)
    4. Расчет ключевых бизнес-KPI:
       - давность продаж (recency — месяцев с последней продажи)
       - средняя выручка от заказа (AOR)
       - средняя ежемесячная выручка
===============================================================================
*/

-- =============================================================================
-- Создание отчета: gold.report_products
-- =============================================================================
CREATE OR REPLACE VIEW gold.report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Базовый запрос: Извлечение основных колонок из fact_sales и dim_products
---------------------------------------------------------------------------*/
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL  -- учитываем только корректные даты продаж
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Агрегация по продуктам: Суммирование ключевых метрик на уровне каждого продукта
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    -- разница между датами в месяцах
    (EXTRACT(YEAR FROM age(MAX(order_date), MIN(order_date))) * 12 + 
     EXTRACT(MONTH FROM age(MAX(order_date), MIN(order_date)))) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS NUMERIC) / NULLIF(quantity, 0)), 1) AS avg_selling_price
FROM base_query
GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Финальный запрос: Объединение всех результатов по продуктам в единый вывод
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
    -- сколько месяцев прошло с даты последней продажи
	(EXTRACT(YEAR FROM age(CURRENT_DATE, last_sale_date)) * 12 + 
     EXTRACT(MONTH FROM age(CURRENT_DATE, last_sale_date))) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Средняя выручка от заказа (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE CAST(total_sales AS NUMERIC) / total_orders
	END AS avg_order_revenue,

	-- Средняя ежемесячная выручк
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE CAST(total_sales AS NUMERIC) / lifespan
	END AS avg_monthly_revenue
FROM product_aggregations;
