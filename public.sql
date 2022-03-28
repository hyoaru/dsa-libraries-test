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

-- -- Recursive CTE practical implementation
CREATE TABLE remployee(
    employee_id SERIAL NOT NULL,
    first_name VARCHAR(40),
    last_name VARCHAR(40),
    manager_id int NULL,
    PRIMARY KEY(employee_id)
);

DROP TABLE remployee;

SELECT * FROM remployee;

INSERT INTO remployee (first_name, last_name, manager_id) VALUES ('lorem', 'ipsum', NULL);
INSERT INTO remployee (first_name, last_name, manager_id) VALUES ('john', 'doe', 1);
INSERT INTO remployee (first_name, last_name, manager_id) VALUES ('jane', 'smith', 1);
INSERT INTO remployee (first_name, last_name, manager_id) VALUES ('mike', 'wazowski', 2);
INSERT INTO remployee (first_name, last_name, manager_id) VALUES ('what', 'thefuck', 4);
INSERT INTO remployee (first_name, last_name, manager_id) VALUES ('are', 'youdumb', 3);
INSERT INTO remployee (first_name, last_name, manager_id) VALUES ('yes', 'iam', 4);

WITH RECURSIVE CTE_Employee_Report (employee_id, first_name, last_name, manager_id, employee_level) AS (
    SELECT 
        r1.employee_id,
        r1.first_name,
        r1.last_name,
        r1.manager_id,
        1
    FROM
        remployee AS r1
    WHERE
        r1.manager_id IS NULL
    UNION ALL
    SELECT
        r2.employee_id,
        r2.first_name,
        r2.last_name,
        r2.manager_id,  
        cte.employee_level + 1
    FROM
        remployee AS r2
        INNER JOIN CTE_Employee_Report AS cte ON cte.employee_id = r2.manager_id
)
SELECT 
    employee_id,
    first_name,
    last_name,
    manager_id,
    (SELECT last_name FROM remployee WHERE CTE_Employee_Report.manager_id = employee_id) AS manager_last_name,
    employee_level
FROM
    CTE_Employee_Report
ORDER BY 6,4,1;

-- Calculating running total with window function
SELECT
    os.order_id,
    os.order_date,
    os.cust_id,
    os.freight,
    SUM(os.freight) OVER (PARTITION BY os.cust_id ORDER BY os.order_id) AS running_freight_total
FROM
    orders AS os;

-- Row number function on product
SELECT
    pd.prod_id,
    cs.category_name,
    pd.prod_name,
    pd.supp_id,
    pd.category_id,
    ROW_NUMBER () OVER (PARTITION BY pd.category_id ORDER BY pd.prod_id)
FROM
    products AS pd
    INNER JOIN categories AS cs ON pd.category_id = cs.category_id;


-- Pagination with row number function on products
SELECT 
    *
FROM (
    SELECT
        pd.prod_id,
        cs.category_name,
        pd.prod_name,
        pd.supp_id,
        pd.category_id,
        ROW_NUMBER () OVER (PARTITION BY pd.category_id ORDER BY pd.prod_id)
    FROM
        products AS pd
        INNER JOIN categories AS cs ON pd.category_id = cs.category_id
) AS x
WHERE ROW_NUMBER BETWEEN 8 AND 10;



-- Getting the nth highest or lowest 
SELECT
    p.prod_id,
    p.category_id,
    c.category_name,
    p.prod_name,
    p.unit_price
FROM
    products AS p
    INNER JOIN categories AS c ON p.category_id = c.category_id
WHERE
    unit_price = (
        SELECT
            unit_price
        FROM (
            SELECT
                unit_price,
                ROW_NUMBER() OVER (ORDER BY unit_price DESC) AS nth
            FROM(
                SELECT
                    DISTINCT unit_price
                FROM
                    products
            ) AS prices
        ) AS sorted_prices
        WHERE
            nth = 1
    )
ORDER BY 1,4,5;