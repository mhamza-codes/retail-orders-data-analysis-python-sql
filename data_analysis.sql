--CREATE TABLE df_orders(
--	order_id INT PRIMARY KEY,
--	order_date DATE,
--	ship_mode VARCHAR(20),
--	segment VARCHAR(20),
--	country VARCHAR(20),
--	city VARCHAR(20),
--	state VARCHAR(20),
--	postal_code VARCHAR(20),
--	region VARCHAR(20),
--	category VARCHAR(20),
--	sub_category VARCHAR(20),
--	product_id VARCHAR(50),
--	quantity INT,
--	discount DECIMAL(7,2),
--	sales_price DECIMAL(7,2),
--	profit DECIMAL(7,2)
--);

SELECT * FROM df_orders;


-- top 10 highest revenue generating products
SELECT TOP 10 product_id, SUM(sales_price) AS total_sales
FROM df_orders
GROUP BY product_id
ORDER BY total_sales DESC;


-- top 5 highest selling products in each region
WITH products_sales_per_region AS (
	SELECT region, product_id, SUM(sales_price) AS total_sales
	FROM df_orders
	GROUP BY region, product_id
	)

SELECT  region, product_id, total_sales
FROM (SELECT *, ROW_NUMBER() OVER(PARTITION BY region ORDER BY total_sales DESC) AS RN
	FROM products_sales_per_region) AS r_num
WHERE RN <= 5;


-- month over month growth comparison for 2022 & 2023 sales eg: jan 2022 vs jan 2023
WITH year_2022 AS (
	SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month, SUM(sales_price) AS total_sales
	FROM df_orders
	WHERE YEAR(order_date) = 2022
	GROUP BY YEAR(order_date), MONTH(order_date)
	),
year_2023 AS (
	SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month, SUM(sales_price) AS total_sales
	FROM df_orders
	WHERE YEAR(order_date) = 2023
	GROUP BY YEAR(order_date), MONTH(order_date)
	)

SELECT y_22.order_month, y_22.total_sales AS sales_22, y_23.total_sales AS sales_23
FROM year_2022 AS y_22 
	JOIN year_2023 AS y_23
	ON y_22.order_month = y_23.order_month
ORDER BY y_22.order_month;


-- for each category which month had highest sales
WITH cte AS (
	SELECT category, FORMAT(order_date, 'yyyyMM') AS order_year_month, SUM(sales_price) AS sales 
	FROM df_orders
	GROUP BY category, FORMAT(order_date, 'yyyyMM')
	)

SELECT category, order_year_month, sales
FROM (SELECT *, ROW_NUMBER() OVER(PARTITION BY category ORDER BY sales DESC) AS RN
	FROM cte) AS r_num
WHERE RN = 1;


-- which sub category had highest growth by profit in 2023 compare to 2022
WITH year_2022 AS (
	SELECT sub_category, YEAR(order_date) AS order_year, SUM(sales_price) AS total_sales
	FROM df_orders
	WHERE YEAR(order_date) = 2022
	GROUP BY sub_category, YEAR(order_date)
	),
year_2023 AS (
	SELECT sub_category, YEAR(order_date) AS order_year, SUM(sales_price) AS total_sales
	FROM df_orders
	WHERE YEAR(order_date) = 2023
	GROUP BY sub_category, YEAR(order_date)
	),
cte1 AS (
	SELECT y_22.sub_category, y_22.total_sales AS sales_2022, y_23.total_sales AS sales_2023
	FROM year_2022 AS y_22 
	JOIN year_2023 AS y_23
	ON y_22.sub_category = y_23.sub_category
	)

SELECT TOP 1 *, (sales_2023-sales_2022)*100/sales_2022 AS percent_growth
FROM cte1
ORDER BY (sales_2023-sales_2022)*100/sales_2022 DESC;
