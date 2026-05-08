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














