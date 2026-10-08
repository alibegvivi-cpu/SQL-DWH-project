/*
===============================================================================
Анализ эффективности (Год к году YoY, Месяц к месяцу MoM)
===============================================================================
Цель:
    - Измерение эффективности продуктов, клиентов или регионов во времени.
    - Бенчмаркинг и выявление наиболее эффективных объектов.
    - Отслеживание ежегодных трендов и темпов роста.

Используемые функции SQL:
    - LAG(): Доступ к данным из предыдущих строк окна.
    - AVG() OVER(): Вычисление средних значений внутри секций (партиций).
    - CASE: Реализация условной логики для анализа трендов.
===============================================================================
*/

/* Анализ ежегодной эффективности продуктов путем сравнения их продаж 
с историческими средними продажами конкретного продукта и показателями предыдущего года */
WITH yearly_product_sales AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date) AS order_year, -- Адаптировано под PostgreSQL
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY 
        EXTRACT(YEAR FROM f.order_date), -- Адаптировано под PostgreSQL
        p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
    -- Анализ "Год к году" (Year-over-Year)
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;
