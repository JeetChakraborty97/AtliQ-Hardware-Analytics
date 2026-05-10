# 																		AtliQ Hardware Reports (Project) P2

/* Task 10: Forecast Accuracy for all customers for a fiscal year 2021
Description Given:
	As a product owner, I need an aggregate forecast accuracy report for all the customers for a given
fiscal year (as of now I need FY 2021 but in future I would require others) so that I can track the accuracy
of the forecast we make for these customers.

The report should have the following fields:
1. Cutomer Code, Name, Market
2. Total Sold Quantity
3. Total Forecast Quantity
4. Net Error
5. Absolute Error
6. Forecast Accuracy %
*/

# Let's check the latest forecast date and sales date
SELECT
	MAX(date) AS latest_forecast_date
FROM fact_forecast_monthly;

SELECT
	MAX(date) AS latest_sales_date
FROM fact_sales_monthly;

-- The latest forecast date is 2022-02-01
-- Where as the latest sales date is 2021-12-01
-- So forecast table has more records than sales table

# Let's create a helper table 
CREATE TABLE fact_act_est
(
	SELECT
		s.date AS date,
		s.fiscal_year AS fiscal_year,
		s.product_code AS product_code,
		s.customer_code AS customer_code,
		s.sold_quantity AS sold_quantity,
		f.forecast_quantity AS forecast_quantity
	FROM fact_sales_monthly AS s
	LEFT JOIN fact_forecast_monthly AS f
		USING(date, customer_code, product_code)
	UNION   
	SELECT
		f.date AS date,
		f.fiscal_year AS fiscal_year,
		f.product_code AS product_code,
		f.customer_code AS customer_code,
		s.sold_quantity AS sold_quantity,
		f.forecast_quantity AS forecast_quantity
	FROM fact_forecast_monthly AS f
	LEFT JOIN fact_sales_monthly AS s
		USING(date, customer_code, product_code)
);

-- Made some table modifications:
ALTER TABLE `gdb0041`.`fact_act_est` 
DROP COLUMN `fiscal_year`,
CHANGE COLUMN `customer_code` `customer_code` INT NOT NULL DEFAULT '0' ,
CHANGE COLUMN `sold_quantity` `sold_quantity` INT NULL DEFAULT NULL ,
ADD PRIMARY KEY (`date`, `product_code`, `customer_code`);

-- Made fiscal_year as a generated column:
ALTER TABLE `gdb0041`.`fact_act_est` 
ADD COLUMN `fiscal_year` YEAR GENERATED ALWAYS AS (YEAR((`date` + INTERVAL 4 MONTH))) VIRTUAL AFTER `date`;

-- Let's check the table:
SELECT * FROM gdb0041.fact_act_est;

-- Let's replace null with 0 (hypothetical business decision)
UPDATE fact_act_est
SET sold_quantity = 0
WHERE
	sold_quantity IS NULL;
    
UPDATE fact_act_est
SET forecast_quantity = 0
WHERE
	forecast_quantity IS NULL;
    
-- Let's create net error & absolute error along with the percentage
SELECT
	*,
    (forecast_quantity - sold_quantity) AS net_error,
    ROUND((forecast_quantity - sold_quantity) * 100 / forecast_quantity, 2) AS net_error_pct,
    ABS(forecast_quantity - sold_quantity) AS abs_error,
    ROUND(ABS(forecast_quantity - sold_quantity) * 100 / forecast_quantity, 2) AS abs_error_pct
FROM fact_act_est;

-- Let's aggregate the entire thing at customer_code level
WITH ft_1 AS
(
	SELECT
		customer_code,
		SUM(sold_quantity) AS total_sold_qty,
		SUM(forecast_quantity) AS total_forecast_qty,
		SUM((forecast_quantity - sold_quantity)) AS net_error,
		ROUND(SUM((forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity), 2) AS net_error_pct,
		SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,
		ROUND(SUM(ABS(forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity), 2) AS abs_error_pct
	FROM fact_act_est AS s
	WHERE
		s.fiscal_year = 2021
	GROUP BY
		customer_code
)
SELECT
	*,
    (100 - abs_error_pct) AS forecast_accuracy
FROM ft_1
ORDER BY
	forecast_accuracy ASC;
-- Some abs_error_pct are going above 100 and the forecast_accuracy is becoming negative as result
-- Whenever it goes beyond 100 the forecast_accuracy should be 0

-- Updated Query:
WITH ft_1 AS
(
	SELECT
		customer_code,
		SUM(sold_quantity) AS total_sold_qty,
		SUM(forecast_quantity) AS total_forecast_qty,
		SUM((forecast_quantity - sold_quantity)) AS net_error,
		ROUND(SUM((forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity), 2) AS net_error_pct,
		SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,
		ROUND(SUM(ABS(forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity), 2) AS abs_error_pct
	FROM fact_act_est AS s
	WHERE
		s.fiscal_year = 2021 
	GROUP BY
		customer_code
)
SELECT
	f.*,
    c.customer,
    c.market,
    
    IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy
FROM ft_1 AS f
INNER JOIN
	dim_customer AS c
	USING(customer_code)
ORDER BY
	forecast_accuracy ASC;
    
# Now let's create the stored procedure:
USE `gdb0041`;
DROP procedure IF EXISTS `get_forecast_accuracy_for_customers_in_a_given_fy`;

DELIMITER $$
USE `gdb0041`$$
CREATE PROCEDURE `get_forecast_accuracy_for_customers_in_a_given_fy` (
	in_fiscal_year INT
)
BEGIN
	WITH ft_1 AS
	(
		SELECT
			customer_code,
			SUM(sold_quantity) AS total_sold_qty,
			SUM(forecast_quantity) AS total_forecast_qty,
			SUM((forecast_quantity - sold_quantity)) AS net_error,
			ROUND(SUM((forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity), 2) AS net_error_pct,
			SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,
			ROUND(SUM(ABS(forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity), 2) AS abs_error_pct
		FROM fact_act_est AS s
		WHERE
			s.fiscal_year = in_fiscal_year 
		GROUP BY
			customer_code
	)
	SELECT
		f.*,
		c.customer,
		c.market,
		
		IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy
	FROM ft_1 AS f
	INNER JOIN
		dim_customer AS c
		USING(customer_code)
	ORDER BY
		forecast_accuracy DESC;
END$$

DELIMITER ;

																					-- END --