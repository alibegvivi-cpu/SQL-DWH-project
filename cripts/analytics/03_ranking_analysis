/*
===============================================================================
Ранжирование данных (Ranking Analysis)
===============================================================================
Цель:
    - Ранжировать элементы (например, продукты, клиенты) на основе эффективности или других метрик.
    - Выявить лидеров (лучших) и отстающих.

Использованные функции SQL:
    - Оконные функции ранжирования: RANK(), DENSE_RANK(), ROW_NUMBER()
    - Конструкции ограничения и группировки: LIMIT (вместо TOP), GROUP BY, ORDER BY
===============================================================================
*/

-- Какие 5 продуктов приносят наибольшую выручку?
-- Простое ранжирование
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Сложное, но гибкое ранжирование с использованием оконных функций
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.product_name
) AS ranked_products
WHERE rank_products <= 5;

-- Каковы 5 худших продуктов по объему продаж (выручке)?
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue
LIMIT 5;

-- Найти топ-10 клиентов, которые принесли наибольшую выручку
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 3 клиента с наименьшим количеством оформленных заказов
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders
LIMIT 3;
