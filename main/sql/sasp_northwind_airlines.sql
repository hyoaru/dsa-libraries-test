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

-- Ranking employee salary with rank function
SELECT
    e.emp_id,
    e.title,
    e.last_name,
    e.emp_curr_salary,
    RANK() OVER (ORDER BY e.emp_curr_salary DESC) AS rank
FROM
    employees AS e;

-- Difference between rank, dense_rank and row_number
SELECT
    p.prod_id,
    p.category_id,
    c.category_name,
    p.prod_name,
    p.unit_price,
    RANK() OVER (ORDER BY unit_price DESC) AS rank
FROM
    products AS p
    INNER JOIN categories AS c ON p.category_id = c.category_id;

SELECT
    p.prod_id,
    p.category_id,
    c.category_name,
    p.prod_name,
    p.unit_price,
    DENSE_RANK() OVER (ORDER BY unit_price DESC) AS rank
FROM
    products AS p
    INNER JOIN categories AS c ON p.category_id = c.category_id;

SELECT
    p.prod_id,
    p.category_id,
    c.category_name,
    p.prod_name,
    p.unit_price,
    ROW_NUMBER() OVER (ORDER BY unit_price DESC) AS rank
FROM
    products AS p
    INNER JOIN categories AS c ON p.category_id = c.category_id;

-- Finding nth ranked product in terms of unit_price
WITH 
    CTE AS (
        SELECT
            p.prod_id,
            p.category_id,
            c.category_id,
            p.prod_name,
            p.unit_price,
            DENSE_RANK() OVER (ORDER BY unit_price DESC) AS price_rank
        FROM
            products AS p
            INNER JOIN categories AS c ON p.category_id = c.category_id
    )
SELECT
    *
FROM
    CTE
WHERE
    price_rank = 14;

-- Getting product name of lowest price with first_value function
SELECT
    p.prod_id,
    p.category_id,
    c.category_name,
    p.prod_name,
    p.unit_price,
    FIRST_VALUE (p.prod_name) OVER (PARTITION BY p.category_id ORDER BY p.unit_price ASC) AS lowest_price_product,
    FIRST_VALUE (p.unit_price) OVER (PARTITION BY p.category_id ORDER BY p.unit_price ASC) AS lowest_price
FROM
    products AS p
    INNER JOIN categories AS c ON p.category_id = c.category_id
ORDER BY 2;

-- Getting product name of highest price with first_value function
SELECT
    p.prod_id,
    p.category_id,
    c.category_name,
    p.prod_name,
    p.unit_price,
    FIRST_VALUE (p.prod_name) OVER (PARTITION BY p.category_id ORDER BY p.unit_price DESC) AS higest_price_product,
    FIRST_VALUE (p.unit_price) OVER (PARTITION BY p.category_id ORDER BY p.unit_price DESC) AS higest_price
FROM
    products AS p
    INNER JOIN categories AS c ON p.category_id = c.category_id
ORDER BY 2;

-- Getting previous freight with lag function with an offset of 1
SELECT
    o.order_id,
    o.cust_id,
    o.freight,
    LAG(freight, 1) OVER (PARTITION BY o.cust_id) AS previous_freight
FROM
    orders AS o
ORDER BY 2;

-- Getting difference between the freight and previous freight with CTE and lag function
WITH
    CTE_1 AS (
        SELECT
            o.order_id,
            o.cust_id,
            o.freight
        FROM
            orders AS o
    ),
    CTE_2 AS (
        SELECT
            o1.order_id,
            o1.cust_id,
            o1.freight,
            LAG(o1.freight, 1) OVER (PARTITION BY o1.cust_id) AS previous_freight
        FROM
            orders AS o1
    )
SELECT
    *,
    (c1.freight - c2.previous_freight) AS variance
FROM
    CTE_1 AS c1
    INNER JOIN CTE_2 AS c2 ON c1.order_id = c2.order_id;

-- POSTGRESQL Recipes

-- Calculating moving average
SELECT
    air_id,
    month,
    year,
    air_volume,
    AVG(air_volume) OVER (ORDER BY air_id ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS running_4m_average,
    AVG(air_volume) OVER (ORDER BY air_id ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS running_5m_average
FROM
    airvolumes;

-- Calculating weighted moving average
WITH CTE_A AS (
    SELECT
        air_id, 
        month,
        year,
        air_volume,
        ROW_NUMBER () OVER (ORDER BY air_id)
    FROM
        airvolumes
)
SELECT
    a1.air_id,
    a1.month,
    AVG(a1.air_volume),
    SUM(
        CASE
            WHEN a1.row_number - a2.row_number = 0 THEN 0.4 * a2.air_volume
            WHEN a1.row_number - a2.row_number = 1 THEN 0.3 * a2.air_volume
            WHEN a1.row_number - a2.row_number = 2 THEN 0.2 * a2.air_volume
            WHEN a1.row_number - a2.row_number = 3 THEN 0.1 * a2.air_volume
        END
    )
FROM
    CTE_A AS a1
    JOIN CTE_A AS a2 ON a1.row_number BETWEEN a2.row_number - 3 AND a1.row_number
GROUP BY 1,2
ORDER BY 1;

-- Calculating exponential moving average
WITH 
    RECURSIVE t AS(
        SELECT
            month || '-' || year AS air_date,
            0.5 AS alpha,
            ROW_NUMBER() OVER (),
            air_volume
        FROM
            airvolumes
    ),
    ema AS(
        SELECT
            *,
            air_volume AS air_volume_ema
        FROM 
            t
        WHERE 
            ROW_NUMBER = 1
        UNION ALL
        SELECT
            t2.air_date,
            t2.alpha,
            t2.row_number,
            t2.air_volume,
            (t2.alpha * t2.air_volume) + ((1.0 - t2.alpha) * ema.air_volume_ema) AS air_volume_Ema
        FROM
            ema
        JOIN t AS t2 ON ema.row_number = t2.row_number - 1
    )
SELECT
    air_data,
    air_volume,
    air_volume_ema
FROM
    ema;

-- Calculating difference from the beginning row
SELECT
    month || '-' || year AS month_date,
    air_volume,
    FIRST_VALUE(air_volume) OVER() AS first_value_volume
FROM
    airvolumes;

-- Calculating difference from the beginning row with partition
WITH 
    CTE_Diff AS (
        SELECT 
            month,
            year,
            air_volume,
            FIRST_VALUE(air_volume) OVER (PARTITION BY month) AS first_value_volume 
        FROM
            airvolumes
    )
SELECT
    *,
    (air_volume - first_value_volume) AS diff
FROM
    CTE_Diff
ORDER BY 1,2;

-- Calculating month over month growth rate
SELECT
    order_id,
    cust_id,
    order_date
FROM
    orders
WHERE
    ship_country IN ('France')
ORDER BY 3;

SELECT
    DATE_TRUNC('month', order_date),
    COUNT(*) AS order_count
FROM
    orders
WHERE
    ship_country IN ('France')
GROUP BY 1
ORDER BY 1;

SELECT
    DATE_TRUNC('month', order_date),
    COUNT(*) AS order_count,
    LAG(COUNT(*), 1) OVER() AS previous_order_count
FROM
    orders
WHERE
    ship_country IN ('France')
GROUP BY 1
ORDER BY 1;

-- Calculating month over month growth rate percentage
SELECT
    DATE_TRUNC('month', order_date),
    COUNT(*) AS order_count,
    LAG(COUNT(*), 1) OVER() AS previous_order_count,
    100 * (COUNT(*) - LAG(COUNT(*), 1) OVER()) / LAG(COUNT(*), 1) OVER() || '%' AS growth
FROM
    orders
WHERE
    ship_country IN ('France')
GROUP BY 1
ORDER BY 1;

-- Calculating top N items per group
SELECT
    ship_country,
    ship_city,
    COUNT(*)
FROM
    orders
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

WITH 
    CTE_A AS (
        SELECT
            ship_country,
            ship_city,
            COUNT(*) AS shipped_count,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rankings
        FROM
            orders
        GROUP BY 1,2
    )
SELECT
    *
FROM
    CTE_A as a1
WHERE
    rankings <= 5;

WITH
    CTE_A AS (
        SELECT
            ship_country,
            ship_city,
            COUNT(*) AS shipped_count,
            ROW_NUMBER() OVER (PARTITION BY ship_country ORDER BY COUNT(*)) AS country_rank
        FROM
            orders
        GROUP BY 1,2
    )   
SELECT
    *
FROM
    CTE_A AS a1
WHERE
    country_rank = 1;

-- Calculating percentage of total sum and summary statistics
WITH
    CTE_Total AS (
        SELECT
            SUM(freight) AS total_freight
        FROM
            orders
    ),
    CTE_A AS (
        SELECT
            ship_country,
            SUM(freight) AS freight_sum,
            100 * (SUM(freight) / total.total_freight) AS total_percentage
        FROM
            orders, CTE_Total AS total
        GROUP BY
            ship_country,
            total.total_freight
        ORDER BY
            total_percentage DESC
    )
SELECT
    ship_country,
    freight_sum,
    total_percentage || ' %' AS total_percentage
FROM
    CTE_A AS a1;


-- Calculating summary statistics
WITH
    CTE_A AS (
        SELECT
            o.order_id,
            o.order_date,
            o.freight,
            o.ship_country,
            o.ship_city,
            od.quantity,
            od.unit_price,
            (od.quantity * od.unit_price) AS revenue
        FROM
            orders AS o
            INNER JOIN order_details AS od ON o.order_id = od.order_id
        WHERE
            o.ship_country IN ('France')
    )
SELECT
    'Total',
    SUM(a1.quantity) AS total_quantity,
    SUM(a1.revenue) AS total_revenue
FROM
    CTE_A AS a1
UNION ALL
SELECT
    'Average',
    AVG(a1.quantity) AS average_quantity,
    AVG(a1.revenue) AS average_revenue
FROM
    CTE_A AS a1
UNION ALL
SELECT
    'Minimum',
    MIN(a1.quantity) AS minimum_quantity,
    MIN(a1.revenue) AS minimum_revenue
FROM
    CTE_A AS a1
UNION ALL
SELECT
    'Maximum',
    MAX(a1.quantity) AS maximum_quantity,
    MAX(a1.revenue) AS maximum_revenue
FROM
    CTE_A AS a1;