/*
===============================================================================
Исследование показателей (Ключевые метрики) / Measures Exploration (Key Metrics)
===============================================================================
Цель:
    - Вычислить агрегированные метрики (например, суммы, средние значения) для быстрого анализа.
    - Выявить общие тенденции или обнаружить аномалии.

Использованные функции SQL:
    - COUNT(), SUM(), AVG()
===============================================================================
*/

SELECT 'Total Sales' AS measure_name, ROUND(SUM(sales_amount)::numeric, 2) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', ROUND(SUM(quantity)::numeric, 2) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', ROUND(AVG(price)::numeric, 2) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number)::numeric FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name)::numeric FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key)::numeric FROM gold.dim_customers;
