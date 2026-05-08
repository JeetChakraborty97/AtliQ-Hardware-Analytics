# AtliQ Hardware Analytics

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

## Task 1: Croma India product-wise sales report for fiscal year 2021

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

## Gross monthly total sales report for Croma





