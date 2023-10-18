/*
Mint Classics Company Case Study

Mint Classics Company is hoping to close one of their storage facilities. They want
suggestions and recommendations for reorganizing or reducing inventory, while still maintaining timely
service to their customers.

Now that I am familiar with the data and somewhat familiar with Mint Classics’ business processes,
I will start to isolate the data that specifically relates to the business problem I'm addressing.
*/
USE mintclassics;

-- Where are items stored?
/* 
  I'll be using an inner join to combine the warehouses table
with the products table.  I will calculate the total number of
items, products, and product lines held at each warehouse as a 
subquery of the products table.  The result will be joined to the
warehouses table on the warehouse code column. 
*/
SELECT * FROM warehouses;
SELECT * FROM products;


SELECT 
    w.warehouseName,
    w.warehousePctCap,
    p.itemsInStock,
    p.productCodes,
    p.productLines
FROM
    warehouses w
        INNER JOIN
    (SELECT 
        warehouseCode,
        SUM(quantityinStock) AS itemsInStock,
        COUNT(productCode) AS productCodes,
        COUNT(DISTINCT productLine) AS productLines
    FROM
        products
    GROUP BY warehouseCode) AS p ON p.warehouseCode = w.warehouseCode
ORDER BY p.itemsInStock;

/* 
  The South warehouse initially appears to be the best candidate for closing.
It has the least amount of total inventory(79,380), its also has the smallest
capacity available(75% full).  There is more than enough space at the West 
warehouse, which is running at half capacity, room for @120k items.  The North
and East warehouses have 28% and 33% available space as well.
*/

-- How are inventory numbers related to sales figures?
/*
  I will first build my base working table by joining the orderdetails,
products, and warehouses tables together with a left join.  I will calculate 
the total quantity in stock, the number of orders, the quantity ordered, and
the total sale price by each warehouse.  Create a CTE with the base working 
table and the results from the previous query then I will join the two tables.
*/

-- Working table
SELECT 
    warehouseName,
    warehousePctCap,
    SUM(quantityOrdered) AS itemsOrdered,
    SUM(lineTotal) AS totalSales
FROM
    (SELECT 
        o.orderNumber,
            o.productCode,
            p.warehouseCode,
            w.warehouseName,
            w.warehousePctCap,
            o.quantityOrdered,
            o.priceEach,
            (o.quantityOrdered * o.priceEach) AS lineTotal
    FROM
        orderdetails o
    LEFT JOIN products p ON o.productCode = p.productCode
    LEFT JOIN warehouses w ON p.warehouseCode = w.warehouseCode) AS wrk_table
GROUP BY warehouseName, warehousePctCap;

-- Create the CTE using the previous 2 queries
WITH wareprod_tbl  AS
(SELECT
    w.warehouseCode,
    w.warehouseName,
    w.warehousePctCap,
    p.itemsInStock,
    p.productCnt,
    p.productLineCnt
FROM
    warehouses w
        INNER JOIN
    (SELECT 
        warehouseCode,
        SUM(quantityinStock) AS itemsInStock,
        COUNT(productCode) AS productCnt,
        COUNT(DISTINCT productLine) AS productLineCnt
    FROM
        products
    GROUP BY warehouseCode) AS p ON p.warehouseCode = w.warehouseCode
ORDER BY p.itemsInStock),
wrkord_tbl AS
(SELECT
    warehouseCode,
    warehouseName,
    warehousePctCap,
    SUM(quantityOrdered) AS itemsOrdered,
    SUM(lineTotal) AS totalSales
FROM
    (SELECT 
        o.orderNumber,
            o.productCode,
            p.warehouseCode,
            w.warehouseName,
            w.warehousePctCap,
            o.quantityOrdered,
            o.priceEach,
            (o.quantityOrdered * o.priceEach) AS lineTotal
    FROM
        orderdetails o
    LEFT JOIN products p ON o.productCode = p.productCode
    LEFT JOIN warehouses w ON p.warehouseCode = w.warehouseCode) AS wrk_table
GROUP BY warehouseCode, warehouseName, warehousePctCap)
SELECT
    wp.warehouseName,
    wp.warehousePctCap,
    ROUND((wp.itemsInStock / (wp.warehousePctCap / 100)), 0) AS warehouseCap,
    (ROUND((wp.itemsInStock / (wp.warehousePctCap / 100)), 0) - wp.itemsInStock) AS freeSpace,
    wp.itemsInStock,
    wo.itemsOrdered,
    wo.totalSales,
    ROUND((wo.totalSales / 9604190.61), 2) AS pctTotalSales
FROM wareprod_tbl wp
        LEFT JOIN
	 wrkord_tbl wo ON wp.warehouseCode = wo.warehouseCode
ORDER BY wo.totalSales DESC;

/*
  The South warehouse still appears to be the prime candidate for closing.
It has the least storage capacity(105,840), currently holds the least number
of items in stock(79,380), filled the least number of orders(22,351), and 
only accounts for 20% of total sales.

Warehouses with more items filled more orders and accounted for more sales.
*/

-- Do the inventory counts seem appropriate for each item?
SELECT 
    pw.productName,
    pw.warehouseName,
    pw.itemsInStock,
    o.qtyOrdered,
    ROUND((o.qtyOrdered / (pw.itemsInStock + o.qtyOrdered)), 2) AS pctOrdered,
    (1 - ROUND((o.qtyOrdered / (pw.itemsInStock + o.qtyOrdered)), 2)) AS pctRemaining,
    o.totalSales,
    ROUND((o.totalSales / 9604190.61), 2) AS pctTotalSales,
    pw.buyPrice,
    ROUND((o.totalSales / o.qtyOrdered), 2) AS avgItemPrice,
    ROUND((((o.totalSales / o.qtyOrdered) / pw.buyPrice) - 1), 2) AS avgMarginPct
FROM
    (SELECT 
        p.productCode,
            p.productName,
            p.warehouseCode,
            w.warehouseName,
            SUM(p.quantityInStock) AS itemsInStock,
            p.buyPrice
    FROM
        products p
    LEFT JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    GROUP BY p.warehouseCode, p.productCode, p.productName, w.warehouseName, p.buyPrice) pw
        LEFT JOIN
    (SELECT 
        productCode,
            SUM(quantityOrdered) AS qtyOrdered,
            SUM((quantityOrdered * priceEach)) AS totalSales
    FROM
        orderdetails
    GROUP BY productCode) o ON pw.productCode = o.productCode
-- WHERE warehouseName = 'South'
ORDER BY totalSales DESC, pctOrdered DESC;
-- LIMIT 10;

/*
There are signs that current inventory management processes should be improved upon.
Ex. Adjusting par levels for products and discontinuing products that do not sell.

There are 4 products with 15% or less of their stock remaining in inventory.
There are 10 products with 45% or less of their stock remaining in inventory.
17 products have had 10% or less of their stock ordered.

Looking at the top 10 products by sales:
1 product has only 7% of stock remaining
1 product has 52% of stock remaining
8 products have 75% or more of their stock remaining

Looking at tthe top 10 products by quantity ordered:
1 product has 69% of its stock remaining
1 product has 75% of its stock remaining
8 products have 82% or more of their stock remaining
*/

-- How many customers are serviced by each warehouse?
/*
  I will need to start with the customer number from the orders table.  I only
  want to work with customers that have placed an order.  Next I will join the
  orderdetails, products, and warehouses tables with a left join.  From the resulting
  table, I can uncover which warehouse shipped products to customers that ordered and
  the number of customers serviced by each warehouse.  Since some customers may receive
  items from different warehouses, I want to find the percent of ordering customers have
  products shipped from each warehouse.
*/

SELECT * FROM orders;
SELECT COUNT(DISTINCT customerNumber) FROM orders;

SELECT 
    warehouseName,
    totalCustomers,
    ROUND((totalCustomers / 98), 2) AS customerPct
FROM
    (SELECT 
        warehouseName,
            COUNT(DISTINCT customerNumber) AS totalCustomers
    FROM
        (SELECT 
        o.customerNumber, w.warehouseName
    FROM
        orders o
    LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
    LEFT JOIN products p ON od.productCode = p.productCode
    LEFT JOIN warehouses w ON p.warehouseCode = w.warehouseCode) cust_ware
    GROUP BY warehouseName
    ORDER BY totalCustomers DESC) agg_tbl;
    
/*
  Lastly, I want to look at where, country wise, our customers are located.  This data
will be helpful in discovering how to best redistribute our products.  Merging the orders
and customers table with an inner join is the route I'll take.  I only want to look at 
customers who have placed an order.  For each country, I want to know how many customers
are located there and what is that percentage wise.
*/

SELECT 
    c.country,
    COUNT(DISTINCT o.customerNumber) AS customerCnt,
    ROUND((COUNT(DISTINCT o.customerNumber) / 98),
            2) AS customerPct
FROM
    orders o
        INNER JOIN
    customers c ON c.customerNumber = o.customerNumber
GROUP BY c.country
ORDER BY customerCnt DESC;

/*
  Less than 9% of our customers should be affected by closing the South warehouse.
Locating which products are more popular by location and ensuring there is a regular
supply at the 2 closest warehouse should keep shipping times close to current levels
if not improve them by having an efficient logistics process.

  The current warehousing process has various warehouses servicing the same customers.
Closing the South warehouse would affect 81 customers.  Properly redistributing our current
inventory to the remaining warehouses would have a minimal impact on shipping times.  The 
inventory par, minimum and maximum stock levels, levels should be implemented.  There are 
several products with over 60% of their inventory remaining while some of our best sellers 
have less than 20% left in stock.  The marketing and sales teams should be consulted to devise
a course of action to trim current stock levels, as we phase out products, and procurring 
more stock of the best selling products.
*/