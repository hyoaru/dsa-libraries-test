-- USING SASP NORTHWIND NORMALIZED DATABASE

-- Aggregation functions
-- -- Total orders
SELECT
    COUNT(od.order_id) AS total_orders
FROM
    order_details AS od;

-- -- Sum of sales
SELECT
    SUM(od.unit_price) AS sum_of_sales
FROM
    order_details AS od;

-- -- Average of discount given
SELECT
    AVG(od.discount) AS average_discount
FROM
    order_details AS od;

-- -- Max quantity where prod_id is equal to 11
SELECT
    MAX(od.quantity) AS max_quantity
FROM
    order_details AS od
WHERE
    prod_id IN(11);

-- -- Min quantity where prod_id is not 11
SELECT
    MIN(od.quantity) AS min_quantity
FROM
    order_details AS od
WHERE
    od.prod_id NOT IN(11)
    AND od.prod_id IS NOT NULL;

-- -- Grouping by category on count of products per category
SELECT
    cat.category_id,
    cat.category_name,
    COUNT(prod.prod_id)
FROM
    products AS prod
INNER JOIN 
    categories AS cat
    ON prod.category_id = cat.category_id
GROUP BY
    1
ORDER BY
    1;

-- -- Grouping by id and category on count of stock per product
SELECT
    prod.prod_id,
    cat.category_name,
    prod.prod_name,
    SUM(prod.units_in_stock) AS stock
FROM
    products AS prod
    INNER JOIN categories AS cat ON prod.category_id = cat.category_id
GROUP BY
    1,
    2
ORDER BY
    2 ASC;

-- Complex query on averages of employee territories
SELECT
    terr.territory_id,
    emp_sales.employee_surname,
    terr.territory_description,
    AVG(emp_sales.total_order) AS average_sales
FROM(
    SELECT
        os.emp_id AS employee_id,
        emp.last_name AS employee_surname,
        emp.title AS employee_title,
        od.unit_price * od.quantity AS total_order
        -- *
    FROM
        order_details AS od
    INNER JOIN
        orders AS os
        ON od.order_id = os.order_id
    INNER JOIN
        employees AS emp
        ON os.emp_id = emp.emp_id
) AS emp_sales
INNER JOIN
    employee_territories AS emp_terr
    ON emp_sales.employee_id = emp_terr.emp_id
INNER JOIN
    territories AS terr
    ON emp_terr.territory_id = terr.territory_id
GROUP BY 1,2
ORDER BY 2 ASC;

-- Non recursive common table expression version of averages of territories
WITH
    CTE_Order_Details (order_id, employee_id, unit_price, unit_quantity, order_total) AS (
        SELECT
            od.order_id,
            os.emp_id,
            od.unit_price,
            od.quantity,
            od.unit_price * od.quantity AS order_total
        FROM
            order_details AS od
            INNER JOIN orders AS os ON od.order_id = os.order_id
    ),
    CTE_Employee_Territory_Details (employee_id, employee_surname, employee_title, territory_id, territory_description) AS (
        SELECT 
            emp.emp_id,
            emp.last_name,
            emp.title,
            emp_terr.territory_id,
            terr.territory_description
        FROM
            employees AS emp
            INNER JOIN employee_territories AS emp_terr ON emp.emp_id = emp_terr.emp_id 
            INNER JOIN territories AS terr ON emp_terr.territory_id = terr.territory_id
    )
SELECT
    OD.order_id,
    ETD.territory_id,
    ETD.territory_description,
    OD.order_total,
    AVG(order_total) OVER (PARTITION BY ETD.territory_id) AS territory_order_total_average
FROM 
    CTE_Order_Details AS OD
    INNER JOIN CTE_Employee_Territory_Details AS ETD ON OD.employee_id = ETD.employee_id
ORDER BY 2 DESC;

-- Recursive CTE example
WITH RECURSIVE CTE AS (
    SELECT 1 AS n -- anchor member
    UNION ALL
    SELECT n + 1 -- recursive member
        FROM CTE
        WHERE n < 5 -- terminator
)
SELECT n -- invocation
FROM CTE;
