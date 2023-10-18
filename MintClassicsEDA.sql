/*
Mint Classics Company Case Study

Mint Classics Company is hoping to close one of their storage facilities. They want
suggestions and recommendations for reorganizing or reducing inventory, while still maintaining timely
service to their customers.

Upon importing the database, I need to inspect the data tables.  I will be paying close attention
to the customers, orderdetails, orders, products, and warehouses tables.  These seem to house the 
relevant data to complete the project.
*/

USE mintclassics;
/* 
  As part of my initial inspection of the database I will run some basic queries
to get used to the structure of the tables and their data.  This will include
checking for missing and duplicated values and running the count and sum functions
on specific columns.
*/

-- Explore the tables 
/* customers */
SELECT * FROM customers LIMIT 20;

-- Are there any duplicate customer names?
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT customerName) AS num_customers
FROM
    customers;
-- Of the 122 customers, there are no duplicate records.
    
-- How many countries are represented in the table and which ones?
SELECT 
    COUNT(DISTINCT country) AS total_countries
FROM
    customers;
-- There are 27 different countries in the dataset.
    
SELECT 
    country,
    COUNT(country) AS total_cnt,
    ROUND((COUNT(country) / 122) * 100, 2) AS perc_of_customers
FROM
    customers
GROUP BY country
ORDER BY total_cnt DESC , country;

/* The majority of customers are located in the United States(29.51%). 
The USA, Germany, and France account for 50.01% of all customers.
*/

-- Check for null values

SELECT 
    COUNT(*) AS missing_emp_no
FROM
    customers
WHERE
    salesRepEmployeeNumber IS NULL;
-- There 22 records with no sales rep employee number

/* Employees */
SELECT * FROM employees;

-- Check for NULL values
SELECT * FROM employees WHERE reportsTo IS NULL;
SELECT * FROM employees WHERE officeCode IS NULL;
SELECT * FROM employees WHERE jobTitle IS NULL;
SELECT * FROM employees WHERE employeeNumber IS NULL;

/* offices */
SELECT * FROM offices;

-- How many offices are there?
SELECT COUNT(officeCode) as total_offices FROM offices;
-- There are 7 total offices worldwide.

-- What countries do we have offices in and how many?
SELECT 
    country, COUNT(country) AS num_offices
FROM
    offices
GROUP BY country
ORDER BY num_offices DESC;
-- The USA has the most offices at 3, no other place has more than 1.

/* orderdetails */
SELECT * FROM orderdetails;

-- Check for NULL values
SELECT 
    *
FROM
    orderdetails
WHERE
    orderNumber IS NULL
        OR productCode IS NULL;

-- Are there any orders where there is a negative or 0 price?
SELECT 
    *
FROM
    orderdetails
WHERE
    priceEach <= 0;

-- How many orders, line items, and products are present?
SELECT 
    COUNT(DISTINCT orderNumber) AS total_orders,
    COUNT(orderNumber) AS total_line_items,
    COUNT(DISTINCT productCode) AS total_distinct_products_ordered
FROM
    orderdetails;
    
/* orders */
SELECT * FROM orders;

-- How many orders were placed?
SELECT COUNT(orderNumber) AS num_orders FROM orders;

-- What percentage of orders have been shipped?
SELECT 
    status,
    COUNT(orderNumber) AS num_orders,
    ROUND((COUNT(orderNumber) / 326) * 100, 2) AS perc_of_orders
FROM
    orders
GROUP BY status
ORDER BY num_orders DESC;
-- 92.94% of orders have been shipped.

-- Check for null values
SELECT * FROM orders WHERE customerNumber IS NULL;

/* payments */
SELECT * FROM payments;

/*
 How much has each customer spent?
 How many orders has each customer made?
*/
SELECT 
    customerNumber,
    COUNT(checkNumber) AS num_payments,
    SUM(amount) AS total_spent
FROM
    payments
GROUP BY customerNumber
ORDER BY total_spent DESC , num_payments DESC;

/*
 How many total distinct customers have we had?
 What are the total sales?
*/
SELECT
    COUNT(DISTINCT customerNumber) AS num_customers,
    SUM(amount) AS total_sales
FROM
    payments;

-- Check for NULL values and payments less than or equal to zero.
SELECT 
    *
FROM
    payments
WHERE
    customerNumber IS NULL
        OR checkNumber IS NULL
        OR paymentDate IS NULL
        OR amount <= 0;
        
/* productlines */
SELECT * FROM productlines;

-- Verify that there are only 7 product lines
SELECT COUNT(*) AS num_records FROM productlines;

/* products */
SELECT * FROM products;

-- How many products do we carry?
SELECT COUNT(*) AS num_records FROM products;
-- We carry 110 products across our warehouses.

/*
 How many products are available for each product line?
 What percentage of products does each product line account for?
*/
SELECT 
    productLine,
    COUNT(productCode) AS num_products,
    ROUND((COUNT(productCode) / 110) * 100, 2) AS perc_of_products
FROM
    products
GROUP BY productLine
ORDER BY num_products DESC;
-- Classic and Vintage cars account for 56.37% of our products.

-- How many product lines and products are held at each warehouse?
SELECT 
    warehouseCode,
    COUNT(DISTINCT productLine) AS num_prod_lines,
    COUNT(productCode) AS num_prods
FROM
    products
GROUP BY warehouseCode
ORDER BY num_prods DESC , num_prod_lines DESC;

/* warehouses */
SELECT * FROM warehouses;