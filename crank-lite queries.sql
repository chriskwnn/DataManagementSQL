--QUERY 1: How has monthly sales changed comparing data from this year with last year?

SELECT
t1.month AS Month, t1.Total_Sales,
((t1.Total_Sales - t2.Total_Sales)/t2.Total_Sales)*100 AS Growth_From_Last_Year_PERCENT

FROM
(
    SELECT
    MONTH(invoice.datetime) AS Month,
    SUM(invoice_line.price) AS Total_Sales
    FROM invoice_line INNER JOIN invoice ON invoice_line.invoice_id = invoice.id
    WHERE invoice.datetime BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY month
) AS t1
INNER JOIN
(
    SELECT
    MONTH(invoice.datetime) AS Month,
    SUM(invoice_line.price) AS Total_Sales
    FROM invoice_line INNER JOIN invoice ON invoice_line.invoice_id = invoice.id
    WHERE invoice.datetime BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY month
) AS t2
ON t1.Month = t2.Month

--Query 2: How has the demand for each product changed overtime?

SELECT
t2.Product_ID,
t2.Product_Container_Type,
t2.Current_Month AS Month,
t2.quantity AS Quantity_Sold,
t1.quantity_Last_Month AS Quantity_Sold_Last_Month,
((t2.quantity - t1.quantity_Last_Month)/t1.quantity_Last_Month)*100 AS Growth_In_Quantity_Sold_From_Last_Month_PERCENT

FROM(
  SELECT
  product.id AS Product_ID,
  product.container_type AS Product_Container_Type,
  invoice.datetime AS datetime,
  MONTH(invoice.datetime) AS Current_Month,
  sum(invoice_line.quantity) AS quantity
  FROM ((((product INNER JOIN invoice_line ON product.id = invoice_line.product_id)
  INNER JOIN invoice ON invoice.id = invoice_line.invoice_id)
  INNER JOIN delivery ON delivery.id = invoice.delivery_id)
  INNER JOIN deliv_sched ON deliv_sched.delivery_id = delivery.id)
  INNER JOIN customer ON customer.id = deliv_sched.customer_id
  WHERE invoice.datetime BETWEEN '2021-01-01' AND '2021-12-31'
  GROUP BY Product_ID, Current_Month
) AS t2
LEFT JOIN
(
  SELECT
  product_id,
  MONTH(DATE_ADD(invoice.datetime, INTERVAL 1 MONTH)) AS Last_Month,
  sum(invoice_line.quantity) AS quantity_Last_Month
  FROM ((((product INNER JOIN invoice_line ON product.id = invoice_line.product_id)
    INNER JOIN invoice ON invoice.id = invoice_line.invoice_id)
    INNER JOIN delivery ON delivery.id = invoice.delivery_id)
    INNER JOIN deliv_sched ON deliv_sched.delivery_id = delivery.id)
    INNER JOIN customer ON customer.id = deliv_sched.customer_id
    WHERE invoice.datetime BETWEEN '2021-01-01' AND '2021-11-31'
    GROUP BY product.id, Last_Month
) AS t1
ON Current_Month = Last_Month AND t1.product_id = t2.product_id
ORDER BY t2.Product_ID, t2.Current_Month

--OLD Query 2: How has each customer’s monthly order quantity for cases changed overtime?
--Needed to change this question because randomly generated data did not have customers ordering at regular intervals

SELECT
t2.Customer_ID,
t2.Customer_Name,
t2.Product_ID,
t2.Product_Container_Type,
t2.Current_Month AS Month,
t2.quantity,
t1.quantity_Last_Month,
((t2.quantity - t1.quantity_Last_Month)/t1.quantity_Last_Month)*100 AS Growth_In_Quantity_Sold_From_Last_Month_PERCENT

FROM(
  SELECT customer.id AS Customer_ID,
  customer.name AS Customer_Name,
  product.id AS Product_ID,
  product.container_type AS Product_Container_Type,
  invoice.datetime AS datetime,
  MONTH(invoice.datetime) AS Current_Month,
  sum(invoice_line.quantity) AS quantity
  FROM ((((product INNER JOIN invoice_line ON product.id = invoice_line.product_id)
  INNER JOIN invoice ON invoice.id = invoice_line.invoice_id)
  INNER JOIN delivery ON delivery.id = invoice.delivery_id)
  INNER JOIN deliv_sched ON deliv_sched.delivery_id = delivery.id)
  INNER JOIN customer ON customer.id = deliv_sched.customer_id
  GROUP BY Customer_ID, Product_ID, Current_Month
) AS t2
LEFT JOIN
(
  SELECT
  customer.id AS Customer_ID,
  product_id,
  MONTH(DATE_ADD(invoice.datetime, INTERVAL 1 MONTH)) AS Last_Month,
  sum(invoice_line.quantity) AS quantity_Last_Month
  FROM ((((product INNER JOIN invoice_line ON product.id = invoice_line.product_id)
    INNER JOIN invoice ON invoice.id = invoice_line.invoice_id)
    INNER JOIN delivery ON delivery.id = invoice.delivery_id)
    INNER JOIN deliv_sched ON deliv_sched.delivery_id = delivery.id)
    INNER JOIN customer ON customer.id = deliv_sched.customer_id
    GROUP BY customer.id, product.id, Last_Month
) AS t1
ON t1.Customer_ID = t2.Customer_ID AND Current_Month = Last_Month AND t1.product_id = t2.product_id
WHERE (t2.datetime BETWEEN '2021-01-01' AND '2021-12-31') AND t2.Product_ID = 1
ORDER BY t2.Customer_ID, t2.Product_ID, t2.Current_Month

--Query 3:	Who are the best performing sales staff?
SELECT employee.id,
employee.first,
employee.last,
sum(invoice_line.price) AS Total_Sales
FROM ((employee INNER JOIN employee_invoice ON employee.id = employee_invoice.employee_id)
INNER JOIN invoice ON invoice.id = employee_invoice.invoice_id)
INNER JOIN invoice_line ON invoice.id = invoice_line.invoice_id
GROUP BY employee_id
ORDER BY Total_Sales DESC
