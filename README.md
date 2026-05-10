# **AtliQ Hardware Analytics**

<img width="1672" height="941" alt="Project Cover Image" src="https://github.com/user-attachments/assets/5bf3510a-f5bb-4267-bd2e-286044e3602c" />

# Overview

**AtliQ Hardware Analytics** is a SQL-based data analytics project built using MySQL where I solved business problems for a fictional company, **AtliQ Hardware**, which manufactures and sells computer and electronic hardware products. Through this project, I analysed business data, wrote analytical SQL queries, and generated insights to support data-driven decision-making. I worked on this project during my Bootcamp at Codebasics, and it simulates the responsibilities of a Data Analyst by addressing real-world business scenarios such as sales analysis, product performance tracking, customer insights, revenue trends, and operational reporting.

Using SQL, I transformed raw business data into meaningful insights that support data-driven decision-making. Throughout the project, I used analytical queries, aggregations, joins, subqueries, CTEs, and business logic implementations to solve multiple scenario-based business problems.

# Scenerio & Problem Statement

As a Data Analyst at **AtliQ Hardware**, I get various tasks from the product owner/product manager. I have solved these business problems using MySQL.

*I will discuss each task in detail, along with my approach and the queries I have written to solve the task.*

# Tech Stack

* SQL
* MySQL
* Microsoft Excel
* Jira (Tasks were provided in Jira in the Bootcamp)

# Default Tables

* **dim_customer**
* **dim_product**
* **fact_forecast_monthly**
* **fact_freight_cost**
* **fact_gross_price**
* **fact_manufacturing_cost**
* **fact_post_invoice_deductions**
* **fact_pre_invoice_deductions**
* **fact_sales_monthly**

# Project Tasks & My Solutions

## **Task 1: Croma India product-wise sales report for fiscal year 2021**

Descripton Given:

  As a Product Owner, I want to generate a report of individual product sales (aggregated on a monthly basis at the product code level) for Croma India customer for FY 2021 so that I can track individual product sales and run further product analysis on it in Excel.

The report should have the following fields:
* Month
* Product Name
* Variant
* Sold Quantity
* Gross Price Per Item
* Gross Price Total

### I want to know the customer code for Chroma India

```SQL
SELECT
	*
FROM dim_customer
WHERE 
	customer LIKE  "%croma%";
-- The customer code for Croma is 90002002
```

### Let's see the transaction for Croma India

```SQL
SELECT
	*
FROM fact_sales_monthly
WHERE
	customer_code = 90002002 AND
	YEAR(date) = 2021
ORDER BY
	date DESC;
-- product level aggregated sold quantity is already provided
-- Although the dates are in Calendar Date format, they need to be converted
-- FY for AtliQ Hardware starts from September, so I have to add +4 months to get the FY from Calendar Date
```

### Let's create Calendar Date

```SQL
SELECT
	*
FROM fact_sales_monthly
WHERE
	customer_code = 90002002 AND
	YEAR(DATE_ADD(date, INTERVAL 4 MONTH)) = 2021
ORDER BY
	date ASC;
```

### To make this repeatable, created a new User-Defined Function named "get-fiscal-year":

```SQL
USE `gdb0041`;
DROP function IF EXISTS `get_fiscal_year`;

DELIMITER $$
CREATE FUNCTION `get_fiscal_year` (
    calendar_date DATE
)
RETURNS INTEGER
DETERMINISTIC
BEGIN
    DECLARE fiscal_year INT;
    SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
    RETURN fiscal_year;
END$$

DELIMITER ;

-- Updated Query:

SELECT
	*
FROM fact_sales_monthly
WHERE
	customer_code = 90002002 AND
	get_fiscal_year(date) = 2021
ORDER BY
	date ASC;
```

### Now I need to get Product Name & Variants which are present in dim_product

```SQL
SELECT
	s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity
FROM fact_sales_monthly AS s
INNER JOIN dim_product AS p
	ON p.product_code = s.product_code
WHERE
	customer_code = 90002002 AND
	get_fiscal_year(date) = 2021
ORDER BY
	date ASC;
```

### Now I need to get Gross Price Per Item & Gross Price Total which are present in fact_gross_price

```SQL
SELECT
	s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    ROUND(g.gross_price, 2) AS gross_price,
    ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total
FROM fact_sales_monthly AS s
INNER JOIN dim_product AS p
	ON p.product_code = s.product_code
INNER JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
		g.fiscal_year = get_fiscal_year(s.date)
WHERE
	customer_code = 90002002 AND
	get_fiscal_year(date) = 2021
ORDER BY
	date ASC;
```

### Here is an excerpt of the result:

<img width="1323" height="366" alt="SS 1" src="https://github.com/user-attachments/assets/7939fd52-2cf8-40c0-ad77-91548aa7f857" />

## **Task 2: Gross monthly total sales report for Croma**

Descripton Given:

  As a Product Owner, I need to aggregate the monthly gross sales report for Croma India customer so that I can track how much sales this particular customer is generating for AtliQ and manage our relationships accordingly.

The report should have the following fields:
* Month
* Total gross sales amount to Croma India in this month

### My Query

```SQL
SELECT
	s.date,
    ROUND(SUM(g.gross_price * s.sold_quantity), 2) AS gross_price_total
FROM fact_sales_monthly AS s
INNER JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
		g.fiscal_year = get_fiscal_year(s.date)
WHERE
	customer_code = 90002002
GROUP BY
	s.date
ORDER BY
	s.date ASC;
```

### Here is an excerpt of the result:

<img width="1330" height="323" alt="SS 2" src="https://github.com/user-attachments/assets/35cca433-b451-47b4-940a-543412dd2284" />

## Task 3: **Yearly report for Croma India**

Description Given:

  Generate a yearly report for Croma India where there are two columns:
* Fiscal Year
* Total Gross Sales amount In that year from Croma

### My Query

```SQL
SELECT
	get_fiscal_year(date) AS fiscal_year,
    SUM(ROUND(sold_quantity*g.gross_price, 2)) AS yearly_gross_sales
FROM fact_sales_monthly AS s
INNER JOIN fact_gross_price AS g
	ON g.fiscal_year = get_fiscal_year(s.date) AND
		g.product_code = s.product_code
WHERE
	customer_code = 90002002
GROUP BY
	get_fiscal_year(date)
ORDER BY
	fiscal_year ASC;
```

### Here is the result:

<img width="1326" height="192" alt="SS 3" src="https://github.com/user-attachments/assets/ebca0f8b-ddaa-415f-9641-630fb10eb3cc" />

## Task 4: **Create a Stored Procedure for customer-level monthly gross sales report**

Description Given:

  As a data analyst, I want to create a stored procedure for customer-level monthly gross sales report so that I don't have to manually modify the query every time. The stored procedure can also be run by other users too (who have limited access to the database) and they can generate this report without having to involve the data analytics team.

The report should have the following columns:
* Month
* Total gross sales in that month from a given customer

### So, I created a stored procedure called "get_monthly_gross_sales_for_customer":

```SQL
USE `gdb0041`;
DROP procedure IF EXISTS `get_monthly_gross_sales_for_customer`;

DELIMITER $$
USE `gdb0041`$$
CREATE PROCEDURE `get_monthly_gross_sales_for_customer` (
	cust_code INT
)
BEGIN
	SELECT
		s.date,
		ROUND(SUM(g.gross_price * s.sold_quantity), 2) AS gross_price_total
	FROM fact_sales_monthly AS s
	INNER JOIN fact_gross_price AS g
		ON g.product_code = s.product_code AND
			g.fiscal_year = get_fiscal_year(s.date)
	WHERE
		customer_code = cust_code
	GROUP BY
		s.date
	ORDER BY
		s.date ASC;
END$$

DELIMITER ;

-- Updated Query:

CALL gdb0041.get_monthly_gross_sales_for_customer(90002002);
-- Now, I only have to call it and mention the customer_code in the parentheses.
-- And other team members can also use it.
```

### Here is an excerpt of the result:

<img width="1326" height="353" alt="SS 4" src="https://github.com/user-attachments/assets/61c64f6c-5989-4b9e-ae37-3c768bfdd4c1" />

## Task 5: **Create a Stored Procedure for market badge**

Description Given:

Create a stored procedure that can determine the market badge based on the following logic:

If the total sold quantity > 5 million, that market is considered Gold; else it is Silver.

The input shall be:
* Market
* Fiscal Year

Output shall be:
* Market Badge

### fact_sales_monthly table has sold_quantity column and customer_code column.
### dim_customer table has customer_code and market columns.
### So the solution would be to JOIN fact_sales_monthly & dim_customer and perform GROUP BY on the market.

### So, I created this stored procedure called "get_market_badge":

```SQL
USE `gdb0041`;
DROP procedure IF EXISTS `get_market_badge`;

DELIMITER $$
USE `gdb0041`$$
CREATE PROCEDURE `get_market_badge` (
	IN in_market VARCHAR(50),
    IN in_fiscal_year YEAR,
    OUT out_badge VARCHAR(50)
)
BEGIN
	DECLARE
		total_sold_qty INT DEFAULT 0;
    
    # Set defaul market to be India
    IF in_market = "" THEN
		SET in_market = "India";
	END IF;
    
    # Set defaul fiscal year to be 2020
    IF in_fiscal_year = "" THEN
		SET in_fiscal_year = 2020;
	END IF;
    
    # Retrieve total sold qty for a given market + fiscal year
	SELECT
		SUM(s.sold_quantity) INTO total_sold_qty
	FROM fact_sales_monthly AS s
	INNER JOIN dim_customer AS c
		ON s.customer_code = c.customer_code
	WHERE 
		get_fiscal_year(s.date) = in_fiscal_year AND
		c.market = in_market
	GROUP BY
		c.market;
	
    # Determine market badge
    IF total_sold_qty > 5000000 THEN
		SET out_badge = "Gold";
	ELSE
		SET out_badge = "Silver";
	END IF;
END$$

DELIMITER ;

-- I have set the default market and fiscal year value to be India and 2020 in case any user forgets one.

-- Updated Query:

set @out_badge = '0';
call gdb0041.get_market_badge('India', 2021, @out_badge);
select @out_badge;
```

## Task 6: **Top markets, products and customers for a given financial year**

Description Given:

  As a product owner, I want a report of the top market, products and customers by net sales (in millions) for a given financial year so that I can have a holistic view of our financial performance and can take appropriate actions to address any potential issues.

We will probably need a stored procedure for this as we may need this report going forward as well.

* Report for top markets.
* Report for top products.
* Report for top customers.

### First, I need to get the pre_invoice_deductions

```SQL
SELECT
	s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    ROUND(g.gross_price, 2) AS gross_price,
    ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly AS s
INNER JOIN dim_product AS p
	ON p.product_code = s.product_code
INNER JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
		g.fiscal_year = get_fiscal_year(s.date)
INNER JOIN fact_pre_invoice_deductions AS pre
	ON pre.customer_code = s.customer_code AND
		pre.fiscal_year = get_fiscal_year(s.date)
WHERE
	get_fiscal_year(date) = 2021
ORDER BY
	date ASC;
```

### The Query takes time to load.
### After using EXPLAIN ANALYZE, the issue seems to be coming from repetitive use of get_fiscal_year on rows
### Created a new dim_date table to establish mapping:

```SQL
CREATE TABLE `gdb0041`.`dim_date` (
  `calendar_date` DATE NOT NULL,
  `fiscal_year` YEAR GENERATED ALWAYS AS (YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH))) VIRTUAL,
  PRIMARY KEY (`calendar_date`));

-- Created a .csv file on Excel to import the necessary dates.
-- Imported the data into the dim_date table

-- Updated Query:

SELECT
	s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    ROUND(g.gross_price, 2) AS gross_price,
    ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly AS s
INNER JOIN dim_product AS p
	ON p.product_code = s.product_code
INNER JOIN dim_date AS dt
	ON dt.calendar_date = s.date
INNER JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
		g.fiscal_year = dt.fiscal_year
INNER JOIN fact_pre_invoice_deductions AS pre
	ON pre.customer_code = s.customer_code AND
		pre.fiscal_year = dt.fiscal_year
WHERE
	dt.fiscal_year = 2021
ORDER BY
	date ASC;

-- Reduced more than 1 sec in the Duration of the query.
```

### Also added fiscal_year column in the fact_sales_monthly table for easier querying:

```SQL
ALTER TABLE `gdb0041`.`fact_sales_monthly` 
ADD COLUMN `fiscal_year` YEAR GENERATED ALWAYS AS (YEAR(DATE_ADD('date', INTERVAL 4 MONTH))) VIRTUAL AFTER `date`,
DROP PRIMARY KEY,
ADD PRIMARY KEY (`date`, `product_code`, `customer_code`);
;

-- Updated Query:

SELECT
	s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    ROUND(g.gross_price, 2) AS gross_price,
    ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly AS s
INNER JOIN dim_product AS p
	ON p.product_code = s.product_code
INNER JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
		g.fiscal_year = s.fiscal_year
INNER JOIN fact_pre_invoice_deductions AS pre
	ON pre.customer_code = s.customer_code AND
		pre.fiscal_year = s.fiscal_year
WHERE
	s.fiscal_year = 2021
ORDER BY
	date ASC;
    
-- Reduced more than 3 sec in the Duration of the query.
```

### Now I need to get net invoice sales.

```SQL
-- Updated Query:

WITH cte_1 AS
	(SELECT
		s.date,
		s.product_code,
		p.product,
		p.variant,
		s.sold_quantity,
		ROUND(g.gross_price, 2) AS gross_price,
		ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total,
		pre.pre_invoice_discount_pct
	FROM fact_sales_monthly AS s
	INNER JOIN dim_product AS p
		ON p.product_code = s.product_code
	INNER JOIN fact_gross_price AS g
		ON g.product_code = s.product_code AND
			g.fiscal_year = s.fiscal_year
	INNER JOIN fact_pre_invoice_deductions AS pre
		ON pre.customer_code = s.customer_code AND
			pre.fiscal_year = s.fiscal_year
	WHERE
		s.fiscal_year = 2021
	ORDER BY
		date ASC)
SELECT
	*,
    (gross_price_total - gross_price_total * pre_invoice_discount_pct) AS net_invoice_sales
						-- Used CTE as a derived field like 'gross_price_total' can't be used in the same query.
FROM cte_1;
```

### Realising this will get bigger and bigger, I created a view called "sales_preinv_discount":

```SQL
USE `gdb0041`;
CREATE  OR REPLACE VIEW `sales_preinv_discount` AS
	SELECT
		s.date,
        s.fiscal_year,
        s.customer_code,
        c.market,
		s.product_code,
		p.product,
		p.variant,
		s.sold_quantity,
		ROUND(g.gross_price, 2) AS gross_price,
		ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total,
		pre.pre_invoice_discount_pct
	FROM fact_sales_monthly AS s
    INNER JOIN dim_customer AS c
		ON s.customer_code = c.customer_code
	INNER JOIN dim_product AS p
		ON p.product_code = s.product_code
	INNER JOIN fact_gross_price AS g
		ON g.product_code = s.product_code AND
			g.fiscal_year = s.fiscal_year
	INNER JOIN fact_pre_invoice_deductions AS pre
		ON pre.customer_code = s.customer_code AND
			pre.fiscal_year = s.fiscal_year
	ORDER BY
		date ASC;

-- Updated Query:

SELECT
	*,
    ROUND(((1 - pre_invoice_discount_pct) * gross_price_total), 2) AS net_invoice_sales
FROM sales_preinv_discount;
```

### Now I need to get the net sales.
### So I created another view called 'sales_postinv_discount':

```SQL
USE `gdb0041`;
CREATE  OR REPLACE VIEW `sales_postinv_discount` AS
	SELECT
		s.date,
        s.fiscal_year,
        s.customer_code,
        s.market,
        s.product_code,
        s.product,
        s.variant,
        s.sold_quantity,
        s.gross_price_total,
        s.pre_invoice_discount_pct,
		ROUND((s.gross_price_total - s.pre_invoice_discount_pct * s.gross_price_total), 2) AS net_invoice_sales,
		(po.discounts_pct + po.other_deductions_pct) AS post_invoice_discount_pct
	FROM sales_preinv_discount AS s
	INNER JOIN fact_post_invoice_deductions AS po
		ON po.product_code = s.product_code AND
			po.customer_code = s.customer_code AND
            po.date = s.date;

-- Updated Query:

SELECT
	*,
    ROUND(((1 - post_invoice_discount_pct) * net_invoice_sales), 2) AS net_sales
FROM sales_postinv_discount;
```

### For convenience, created another view called 'net_sales':

```SQL
USE `gdb0041`;
CREATE  OR REPLACE VIEW `net_sales` AS
	SELECT
		*,
		ROUND(((1 - post_invoice_discount_pct) * net_invoice_sales), 2) AS net_sales
	FROM sales_postinv_discount;
```

### For convenience, I also wanted to create a view for gross sales.
### It should have the following columns:
* date
* fiscal_year
* customer_code
* customer
* market
* product_code
* product
* variant
* sold_quanity
* gross_price_per_item
* gross_price_total

```SQL
USE `gdb0041`;
CREATE  OR REPLACE VIEW `gross_sales` AS
	SELECT
		s.date,
        s.fiscal_year,
        s.customer_code,
        c.customer,
        c.market,
        s.product_code,
        p.product,
        p.variant,
        s.sold_quantity,
        g.gross_price AS gross_price_per_item,
        ROUND((s.sold_quantity * g.gross_price), 2) AS gross_price_total
	FROM fact_sales_monthly AS s
    INNER JOIN dim_product AS p
		ON s.product_code = p.product_code
	INNER JOIN dim_customer AS c
		ON s.customer_code = c.customer_code
	INNER JOIN fact_gross_price AS g
		ON g.fiscal_year = s.fiscal_year AND
			g.product_code = s.product_code;
```

### Now let's create the market report

```SQL
SELECT
	market,
    ROUND((SUM(net_sales)/1000000), 2) AS net_sales_mln
FROM net_sales
WHERE
	fiscal_year = 2021
GROUP BY
	market
ORDER BY
	net_sales_mln DESC
LIMIT 5;
```

### Here is the result (for convenience, I have limited the results to the top 5):

<img width="1324" height="155" alt="SS 5" src="https://github.com/user-attachments/assets/f11a4def-c768-4dfa-b559-539e3c0df34a" />

### Now, let's create the stored procedure:

```SQL
USE `gdb0041`;
DROP procedure IF EXISTS `get_top_n_markets_by_net_sales`;

DELIMITER $$
USE `gdb0041`$$
CREATE PROCEDURE `get_top_n_markets_by_net_sales` (
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN
	SELECT
		market,
		ROUND((SUM(net_sales)/1000000), 2) AS net_sales_mln
	FROM net_sales
	WHERE
		fiscal_year = in_fiscal_year
	GROUP BY
		market
	ORDER BY
		net_sales_mln DESC
	LIMIT in_top_n;
END$$

DELIMITER ;

-- I have kept fiscal_year and top_n as variable for flexibility.
```

### Now let's create the customer report

```SQL
SELECT
	c.customer,
    ROUND((SUM(net_sales)/1000000), 2) AS net_sales_mln
FROM net_sales AS ns
INNER JOIN dim_customer AS c
	ON c.customer_code = ns.customer_code
WHERE
	fiscal_year = 2021
GROUP BY
	c.customer
ORDER BY
	net_sales_mln DESC
LIMIT 5;
```

### Here is the result (for convenience, I have limited the results to the top 5):

<img width="1328" height="161" alt="SS 6" src="https://github.com/user-attachments/assets/890f0a9d-bcbf-40af-8395-bc6ccfc3824f" />

### Now, let's create the stored procedure:

```SQL
USE `gdb0041`;
DROP procedure IF EXISTS `get_top_n_customers_by_net_sales`;

DELIMITER $$
USE `gdb0041`$$
CREATE PROCEDURE `get_top_n_customers_by_net_sales` (
	in_market VARCHAR(50),
    in_fiscal_year INT,
    in_top_n INT
)
BEGIN
	SELECT
		c.customer,
		ROUND((SUM(net_sales)/1000000), 2) AS net_sales_mln
	FROM net_sales AS ns
	INNER JOIN dim_customer AS c
		ON c.customer_code = ns.customer_code
	WHERE
		fiscal_year = in_fiscal_year AND
		s.market = in_market
	GROUP BY
		c.customer
	ORDER BY
		net_sales_mln DESC
	LIMIT in_top_n;
END$$

DELIMITER ;

-- Also added market as an input parameter.
```

### Now let's create the product report

```SQL
SELECT
	p.product,
    ROUND((SUM(net_sales)/1000000), 2) AS net_sales_mln
FROM net_sales AS ns
INNER JOIN dim_product AS p
	ON p.product_code = ns.product_code
WHERE
	fiscal_year = 2021
GROUP BY
	p.product
ORDER BY
	net_sales_mln DESC
LIMIT 5;
```

### Here is the result (for convenience, I have limited the results to the top 5):

<img width="1326" height="160" alt="SS 7" src="https://github.com/user-attachments/assets/70798fb1-fee5-47b4-99e7-007f8887e2e6" />

### Now, let's create the stored procedure:

```SQL
USE `gdb0041`;
DROP procedure IF EXISTS `get_top_n_products_by_net_sales`;

DELIMITER $$
USE `gdb0041`$$
CREATE PROCEDURE `get_top_n_products_by_net_sales` (
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN
	SELECT
		p.product,
		ROUND((SUM(net_sales)/1000000), 2) AS net_sales_mln
	FROM net_sales AS ns
	INNER JOIN dim_product AS p
		ON p.product_code = ns.product_code
	WHERE
		fiscal_year = in_fiscal_year
	GROUP BY
		p.product
	ORDER BY
		net_sales_mln DESC
	LIMIT in_top_n;
END$$

DELIMITER ;
```

## **Task 7: Net sales % share global**

Description Given:

  As a product owner, I want to see a bar chart report for FY 2021 for the top 10 markets by % of net sales.

### My Query

```SQL
WITH cte_2 AS (
    SELECT
        c.customer,
        ROUND(SUM(ns.net_sales) / 1000000, 2) AS net_sales_mln
    FROM net_sales AS ns
    INNER JOIN dim_customer AS c
        ON c.customer_code = ns.customer_code
    WHERE
		fiscal_year = 2021
    GROUP BY
		c.customer
)
SELECT
    *,
    ROUND(net_sales_mln * 100 / SUM(net_sales_mln) OVER(), 2) AS pct
FROM cte_2
ORDER BY
	net_sales_mln DESC;

-- Exported the result in .csv and made the report in Excel.
```

### Here is an excerpt of the exported table in Excel:

<img width="1311" height="685" alt="SS 8" src="https://github.com/user-attachments/assets/e1e97330-9bad-4eeb-ace0-c3246bc162c5" />

### Here is the bar chart report:

<img width="779" height="622" alt="AtliQ_Hardware_customer_market_share_pct_global_bar_chart_report" src="https://github.com/user-attachments/assets/e8722295-8767-45f5-9f6b-2100fd6f4d36" />

## **Task 8: Net sales share % by region**

Description Given:

  As a product owner, I want to see region-wise (APAC, EU, LTAM, etc.) % net sales breakdown by customers in a respective region, so that I can perform my regional analysis on financial performance of the company.

The end result should be bar charts for FY 2021.

Also, build a reusable asset we can use to conduct this analysis for any financial year.

### My Query

```SQL
WITH cte_2 AS (
    SELECT
        c.customer,
        ROUND(SUM(ns.net_sales) / 1000000, 2) AS net_sales_mln
    FROM net_sales AS ns
    INNER JOIN dim_customer AS c
        ON c.customer_code = ns.customer_code
    WHERE
		fiscal_year = 2021
    GROUP BY
		c.customer
)
SELECT
    *,
    ROUND(net_sales_mln * 100 / SUM(net_sales_mln) OVER(), 2) AS pct
FROM cte_2
ORDER BY
	net_sales_mln DESC;

WITH cte_3 AS
(
	SELECT
        c.customer,
        c.region,
        ROUND(SUM(ns.net_sales) / 1000000, 2) AS net_sales_mln
    FROM net_sales AS ns
    INNER JOIN dim_customer AS c
        ON c.customer_code = ns.customer_code
    WHERE
		fiscal_year = 2021
    GROUP BY
		c.customer,
        c.region
)
SELECT
	*,
    ROUND(net_sales_mln * 100 / SUM(net_sales_mln) OVER (PARTITION BY region), 2) AS pct_share_region
FROM cte_3
ORDER BY
	region ASC,
    net_sales_mln DESC;

-- Exported the result in .csv and made the report in Excel.

-- Kept till top 10 for each report, except for the LATAM report, which had 3 customers.
```

### Here is an excerpt of the result:

<img width="1230" height="433" alt="SS 9" src="https://github.com/user-attachments/assets/7a0cf866-2cb4-4c1f-91cb-19566ee0972e" />

### Here is the APAC region report:

<img width="775" height="495" alt="APAC Report (AtliQ_Hardware_customer_region wise_share_pct)" src="https://github.com/user-attachments/assets/d75c6e7a-307b-445e-bc9e-99129b03f841" />

### Here is the EU region report:

<img width="772" height="493" alt="EU Report (AtliQ_Hardware_customer_region wise_share_pct)" src="https://github.com/user-attachments/assets/07fdd2ac-03f4-40ca-9068-0d2f232a75dc" />

### Here is the LATAM region report:

<img width="773" height="489" alt="LATAM Report (AtliQ_Hardware_customer_region wise_share_pct)" src="https://github.com/user-attachments/assets/fa00d263-7118-44f2-98e1-f89be7a120cd" />

### Here is the NA region report:

<img width="773" height="494" alt="NA Report (AtliQ_Hardware_customer_region wise_share_pct)" src="https://github.com/user-attachments/assets/9c47293b-8bd0-440e-a7c1-ec0446fb6da3" />

## **Task 9: Get top n products in each division by their quality sold**

Description Given:

  Write a stored procedure for getting the top n products in each division by their quantity sold in a given financial year.

### My Query

```SQL
WITH cte_1 AS
(
	SELECT
		p.division,
		p.product,
		SUM(sold_quantity) AS total_sold_quantity
	FROM fact_sales_monthly AS s
	INNER JOIN dim_product AS p
		ON p.product_code = s.product_code
	WHERE
		fiscal_year = 2021
	GROUP BY
		p.division,
		p.product
), 
cte_2 AS
(
	SELECT
		*,
		DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS drnk
	FROM cte_1
)
SELECT
	*
FROM cte_2
WHERE
	drnk <= 3;
```

### Here is the result (for testing, I have set the FY to 2021):

<img width="1215" height="263" alt="SS 10" src="https://github.com/user-attachments/assets/47f0ae49-9a98-467d-802b-80a9c293708a" />

### Now, let's create a stored procedure for it:

```SQL
USE `gdb0041`;
DROP procedure IF EXISTS `get_top_n_products_per_division_by_qty_sold`;

DELIMITER $$
USE `gdb0041`$$
CREATE PROCEDURE `get_top_n_products_per_division_by_qty_sold` (
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN
	WITH cte_1 AS
	(
		SELECT
			p.division,
			p.product,
			SUM(sold_quantity) AS total_sold_quantity
		FROM fact_sales_monthly AS s
		INNER JOIN dim_product AS p
			ON p.product_code = s.product_code
		WHERE
			fiscal_year = in_fiscal_year
		GROUP BY
			p.division,
			p.product
	), 
	cte_2 AS
	(
		SELECT
			*,
			DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS drnk
		FROM cte_1
	)
	SELECT
		*
	FROM cte_2
	WHERE
		drnk <= in_top_n;
END$$

DELIMITER ;
```

## **Task 10: **


