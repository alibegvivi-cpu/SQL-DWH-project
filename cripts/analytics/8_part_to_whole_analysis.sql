/*
===============================================================================
Анализ "Часть от целого" (Part-to-Whole)
===============================================================================
Цель:
    - Сравнение эффективности или метрик по различным разрезам (измерениям) или периодам.
    - Оценка различий между категориями.
    - Полезно для А/Б-тестирования или сравнения регионов.

Используемые функции SQL:
    - SUM(), AVG(): Агрегирование значений для сравнения.
    - Оконные функции: SUM() OVER() для расчета общих итогов.
===============================================================================
*/

-- Какие категории вносят наибольший вклад в общий объем продаж?
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    ROUND((CAST(total_sales AS NUMERIC) / SUM(total_sales) OVER ()) * 100, 2) AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;
