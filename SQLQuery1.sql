drop table df_orders;

create table df_orders (
		[order_id] int primary key,
		[order_date] date,
		[ship_mode] varchar(20),
		[segment] varchar(20),
		[country] varchar(20),
		[city] varchar(20),
		[state] varchar(20),
		[postal_code] varchar(20),
		[region] varchar(20),
		[category] varchar(20),
		[sub_category] varchar(20),
		[product_id] varchar(50),
		[quantity] int,
		[discount] decimal(7,2),
		[sale_price] decimal(7,2),
		[profit] decimal(7,2))

SELECT * FROM df_orders


SELECT product_id, SUM(sale_price) as sales
FROM df_orders
GROUP BY product_id, region
ORDER BY region, sales DESC


with cte AS (
SELECT region, product_id, SUM(sale_price) as sales
FROM df_orders
GROUP BY region, product_id)
SELECT * FROM (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales DESC) as rn
FROM cte) A
WHERE rn<=5;

with cte as (
SELECT YEAR(order_date) as order_year, MONTH(order_date) as order_month,
SUM(sale_price) as sales
FROM df_orders
GROUP BY YEAR(order_date), MONTH(order_date)
--ORDER BY YEAR(order_date), MONTH(order_date)
)
SELECT order_month,
SUM(CASE WHEN order_year=2022 THEN sales ELSE 0 END) as sales_2022,
SUM(CASE WHEN order_year=2023 THEN sales ELSE 0 END) as sales_2023
FROM cte
GROUP BY order_month


with cte as (
SELECT category, FORMAT(order_date, 'yyyyMM') as order_year_month, 
SUM(sale_price) AS sales
FROM df_orders
GROUP BY category, FORMAT(order_date, 'yyyyMM')
)
SELECT * FROM (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY category ORDER BY sales DESC) as rn
FROM cte) A
WHERE rn=1;

with cte as (
SELECT sub_category, YEAR(order_date) AS order_year, MONTH(order_date) as order_month,
SUM(sale_price) AS sales
FROM df_orders
GROUP BY sub_category, YEAR(order_date), MONTH(order_date)
)
, cte2 as ( 
SELECT sub_category,
SUM(CASE WHEN order_year=2022 THEN sales ELSE 0 END) AS sales_2022,
SUM(CASE WHEN order_year=2023 THEN sales ELSE 0 END) AS sales_2023
FROM cte
GROUP BY sub_category
) 
SELECT top 1 *,
(sales_2023-sales_2022)
FROM cte2
ORDER BY (sales_2023-sales_2022);



-- Profit margin % by category and sub category( find low-margin, high-revenue areas)
SELECT category, sub_category,
SUM(sale_price) as sales,
SUM(profit) as profit,
ROUND(SUM(profit)*100.0 / SUM(sale_price), 2) as margin_profit
FROM df_orders
GROUP BY category, sub_category
ORDER BY category, margin_profit

-- Does discount % impact profit margin?
SELECT DISTINCT discount,
COUNT(*) as orders,
SUM(sale_price) as sales,
SUM(profit) as profit,
ROUND(SUM(profit)*100.0 / NULLIF(SUM(sale_price),0), 2) as margin_profit 
FROM df_orders
GROUP BY discount
ORDER BY discount

-- Profit and margin by region and state
SELECT region,
SUM(sale_price) as sales,
SUM(profit) as profit,
ROUND(SUM(profit)*100.0 / SUM(sale_price), 2) as margin_profit
FROM df_orders
GROUP BY region
ORDER BY profit DESC

SELECT TOP 5 state,
SUM(sale_price) as sales,
SUM(profit) as profit
FROM df_orders
GROUP BY state
ORDER BY profit ASC


-- Profitability by customer segment
SELECT segment,
SUM(sale_price) as sales,
SUM(profit) as profit,
ROUND(SUM(profit)*100.0 / SUM(sale_price), 2) as margin_profit
FROM df_orders
GROUP BY segment
ORDER BY profit DESC

-- YoY profit growth by categorym 2022 vs 2023
WITH cte as(
SELECT category, YEAR(order_date) as order_year,
SUM(profit) as profit
FROM df_orders
GROUP BY category, YEAR(order_date)
)
SELECT category,
SUM(CASE WHEN order_year=2022 THEN profit ELSE 0 END) as profit_2022,
SUM(CASE WHEN order_year=2023 THEN profit ELSE 0 END) as profit_2023,
ROUND((SUM(CASE WHEN order_year=2023 THEN profit ELSE 0 END) 
       - 
	   SUM(CASE WHEN order_year=2022 THEN profit ELSE 0 END))
*100.0 / NULLIF(SUM(CASE WHEN order_year=2022 THEN profit ELSE 0 END),0), 2) as growth_pct
FROM cte
GROUP BY category
ORDER BY growth_pct DESC