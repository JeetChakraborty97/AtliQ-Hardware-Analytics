# 																		AtliQ Hardware Reports (Project)

/* Task 1: Croma India product-wise sales report for fiscal year 2021
Descripton Given:
	As a Product Owner, I want to generate a report of individual product sales (aggregated on a monthly basis at the product code level)
for Croma India customer for FY 2021 so that I can track individual product sales and run further product analysis on it in Excel.

The report should have following fields:
1. Month
2. Product Name
3. Variant
4. Sold Quantity
5. Gross Price Per Item
6. Gross Price Total
*/

# I want to know the customer code for Chroma India
SELECT
	*
FROM dim_customer
WHERE 
	customer LIKE  "%croma%";
-- The customer code for Croma is 90002002

# Lets see the transaction for Croma India
SELECT
	*
FROM fact_sales_monthly
WHERE
	customer_code = 90002002 AND
	YEAR(date) = 2021
ORDER BY
	date DESC;
-- product level aggregated sold quantity is alreqady provided
-- Although the dates are in Calendar Date format; They need to be converted
-- FY for AtliQ Hardware starts on September so I have to add +4 months to get the FY from Calender Date
SELECT
	*
FROM fact_sales_monthly
WHERE
	customer_code = 90002002 AND
	YEAR(DATE_ADD(date, INTERVAL 4 MONTH)) = 2021
ORDER BY
	date ASC;
-- To make this repeatable, created a new User-Difined Function named "get-fiscal-year":
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

# Now I need to get Product Name & Variants which are present in dim_product
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

# Now I need to get Gross Price Per Item & Gross Price Total which are present in fact_gross_price
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
    
/* Task 2: Gross monthly total sales report for Croma
Descripton Given:
	As a Product Owner, I need to aggregate monthly gross sales report for Croma India customer
so that I can track how much sales this particular customer is generating for AtliQ and manage our relationships accordingly.

The report should have following fields:
1. Month
2. Total gross sales amount to Croma India in this month
*/

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


/* Task 3: Generate a yearly report for Croma India where there are two columns
1. Fiscal Year
2. Total Gross Sales amount In that year from Croma
*/

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

/* Task 4: Create a Stored Procedure for customer-level monthly gross sales report
Description:
	As a data analyst, I want to create a stored procedure for customer-level monthly gross sales report
so that I don't have to manually modify the query every time. The stored procedure can also be run by other
users too (who have limited access to database) and they can generate this report without having to involve
the data analytics team.

The report should have the following columns:
1. Month
2. Total gross sales in that month from a given customer
*/

-- So, I created a stored procedure called "get_monthly_gross_sales_for_customer":
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

/* Task 5: Create a Stored Procedure for market badge
Description Given:
	Create a stored procedure that can determine the market badge based on the following logic:
If total sold quantity > 5 million that market is considered Gold else it is Silver.

The input shall be:
1. Market
2. Fiscal Year

Output shall be:
Market Badge
*/

# fact_sales_monthly table has sold_quantity column and customer_code column.
# dim_customer table has customer_code and market columns.
# So the solution would be to JOIN fact_sales_monthly & dim_customer and perform GROUP BY on the market.

-- So, I created this stored procedure called "get_market_badge":
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

/* Task 6: Top markets, products and customers for a given financial year
Description Given:
	As a product owner, I want a report of top market, products and customers by net sales (in millions) for a given financial year
so that I can have a holistic view of our financial performance and can take appropriate actions to address any potential
issues.

We will probably need stored procedure for this as we may need this report going forward as well.

1. Report for top markets.
2. Report for top products.
3. Report for top customers.
*/

# First, I need to get the pre_invoice_deductions
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

# The Query takes time to load.
-- After using EXPLAIN ANALYZE, the issue seems to be coming from repetative use of get_fiscal_year on rows
-- Created a new dim_date table to establish mapping:
CREATE TABLE `gdb0041`.`dim_date` (
  `calendar_date` DATE NOT NULL,
  `fiscal_year` YEAR GENERATED ALWAYS AS (YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH))) VIRTUAL,
  PRIMARY KEY (`calendar_date`));

-- Created a .csv file on Excel to import the necessary dates.
-- Imported the data in dim_date table

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

-- Also added fiscal_year column in fact_sales_monthly table for more ease of querying:
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
    
-- -- Reduced more than 3 sec in the Duration of the query.

# Now I need to get net invoice sales.
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
						-- Used CTE as derived field like 'gross_price_total' can't be used in the same query.
FROM cte_1;

-- Realising this will get bigger and bigger, I creatd a view called "sales_preinv_discount":
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

# Now I need to get the net sales.
-- So I created another view called 'sales_postinv_discount':
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

-- For convinience, created another view called 'net_sales':
USE `gdb0041`;
CREATE  OR REPLACE VIEW `net_sales` AS
	SELECT
		*,
		ROUND(((1 - post_invoice_discount_pct) * net_invoice_sales), 2) AS net_sales
	FROM sales_postinv_discount;

/* For convinience I also wanted to create a view for gross sales.
	It should have the following columns:
1. date
2. fiscal_year
3. customer_code
4. customer
5. market
6. product_code
7. product
8. variant
9. sold_quanity
10. gross_price_per_item
11. gross_price_total
*/

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
            
# Now let's create the market report
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

-- Now, let's create the stored procedure:
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

# Now let's create the customer report
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

-- Now, let's create the stored procedure:
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

# Now let's create the prooduct report
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

-- Now, let's create the stored procedure:
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

/* Task 7: Net sales % share global
Description Given:
	As a product owner, I want to see a bar chart report for FY 2021 for top 10 market by % of net sales.
*/																					
                                                                                                                                                                        
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

/* Task 8: Net sales share % by region 
Description Given:
	As a product owner, I want to see region wise (APAC, EU, LTAM etc) % net sales breakdown
by customers in a respective region so that I can perform my regional analysis on financial performance
of the company.

The end result should be bar charts for FY 2021.
Also, build a re-usable asset we can use to conduct this analysis for any financial year. 
*/                                                                                   
                                                                                    
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
-- Kept till top 10 for each report, except for LATAM report which one had 3 customers.

/* Task 9: Get top n products in each division by their quality sold
Description Given:
	Write a stored procedure for getting top n products in each division by their quantity sold in a given financial year.
*/

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
    
-- Now, let's create a stored procedure for it:
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
















                                                                                    
                                                                                    
                                                                                    -- End --