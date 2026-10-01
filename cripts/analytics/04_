/*
===============================================================================
Анализ изменений во времени (Change over time analysis)
===============================================================================
Цель:
    - Отслеживание трендов, роста и изменений ключевых метрик с течением времени.
    - Проведение анализа временных рядов и выявление сезонности.
    - Измерение темпов роста или спада за определенные периоды.

Используемые функции SQL:
    - Функции даты: EXTRACT(), DATE_TRUNC(), TO_CHAR()
    - Агрегатные функции: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Анализ эффективности продаж во времени
-- Вариант 1: Использование базовых функций извлечения компонентов даты (EXTRACT)
SELECT
    EXTRACT(YEAR FROM order_date) AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY order_year, order_month;

-- Вариант 2: Использование усечения даты до месяца (DATE_TRUNC)
SELECT
    DATE_TRUNC('month', order_date) AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_date;

-- Вариант 3: Форматирование даты в строку (TO_CHAR)
SELECT
    TO_CHAR(order_date, 'YYYY-Mon') AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date, 'YYYY-Mon')
ORDER BY MIN(DATE_TRUNC('month', order_date));
