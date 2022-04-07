-- Exit Assesment
-- Note: Unless otherwise stated, all questions are evaluated against all stores (branches) of the DVD rental business.

-- 1. Who is the 5th actor having the least number films recorded in the database?
WITH
    CTE_A AS (
        SELECT 
            st.store_id,
            st.address_id,
            st.manager_staff_id,
            iv.film_id,
            iv.last_update
        FROM
            store AS st
            INNER JOIN inventory AS iv ON st.store_id = iv.store_id
    ),
    CTE_B AS (
        SELECT 
            a.actor_id,
            a.first_name,
            a.last_name,
            fa.film_id,
            f.title
        FROM
            actor AS a
            INNER JOIN film_actor AS fa ON a.actor_id = fa.actor_id
            INNER JOIN film AS f ON fa.film_id = f.film_id
    ),
    CTE_C AS (
        SELECT
            a.store_id,
            b.actor_id,
            b.first_name,
            b.last_name,
            b.film_id,
            b.title
        FROM
            CTE_A AS a
            INNER JOIN CTE_B AS b ON a.film_id = b.film_id
    ),
    CTE_D AS (
        SELECT
            actor_id,
            first_name,
            last_name,
            COUNT(DISTINCT film_id),
            ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT film_id)) AS rank
        FROM
            CTE_C
        GROUP BY
            1,2,3
        ORDER BY 
            4 ASC
    )
SELECT
    DISTINCT actor_id,
    first_name,
    last_name,
    COUNT(*) OVER (PARTITION BY actor_id)
FROM
    CTE_B
ORDER BY 4;

-- 2. What are the top 5 film categories in terms of number of films?
WITH
    CTE_A AS (
        SELECT 
            f.film_id,
            f.title,
            c.category_id,
            c.name
        FROM
            film AS f
            INNER JOIN film_category AS fc ON f.film_id = fc.film_id
            INNER JOIN category AS c ON fc.category_id = c.category_id 
    ),
    CTE_B AS (
        SELECT 
            DISTINCT category_id,
            name,
            COUNT(*) OVER (PARTITION BY category_id) AS film_count
        FROM
            CTE_A 
    )
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY film_count DESC)
FROM    
    CTE_B;

-- 3. What is percent contribution of film category “Music” in terms of payments across all stores?
WITH
    CTE_A AS (
        SELECT 
            iv.store_id,
            p.payment_id,
            r.rental_id,
            iv.film_id,
            p.amount 
        FROM
            payment AS p
            INNER JOIN rental AS r ON p.rental_id = r.rental_id
            INNER JOIN inventory AS iv ON r.inventory_id = iv.inventory_id
    ),
    CTE_B AS (
        SELECT 
            f.film_id,
            f.title,
            c.category_id,
            c.name
        FROM
            film AS f
            INNER JOIN film_category AS fc ON f.film_id = fc.film_id
            INNER JOIN category AS c ON fc.category_id = c.category_id
    ),
    CTE_C AS (
        SELECT 
            SUM(amount) AS total_amount
        FROM
            CTE_A AS a 
            INNER JOIN CTE_B AS b ON a.film_id = b.film_id 
    ),
    CTE_D AS (
        SELECT 
            a.store_id,
            a.payment_id,
            b.category_id,
            b.name,
            a.amount
        FROM
            CTE_A AS a
            INNER JOIN CTE_B AS b ON a.film_id = b.film_id 
    ),
    CTE_E AS (
        SELECT 
            d.category_id,
            d.name,
            100 * SUM(amount) / c.total_amount AS total_percentage 
        FROM
            CTE_D AS d, 
            CTE_C AS c
        GROUP BY
            1,2,
            c.total_amount
        ORDER BY
            3 DESC
    )
SELECT
    category_id,
    name,
    total_percentage || ' %' AS total_percentage
FROM
    CTE_E;

WITH
    CTE_A AS (
        SELECT 
            iv.store_id,
            p.payment_id,
            r.rental_id,
            iv.film_id,
            p.amount 
        FROM
            payment AS p
            INNER JOIN rental AS r ON p.rental_id = r.rental_id
            INNER JOIN inventory AS iv ON r.inventory_id = iv.inventory_id
    ),
    CTE_B AS (
        SELECT 
            f.film_id,
            f.title,
            c.category_id,
            c.name
        FROM
            film AS f
            INNER JOIN film_category AS fc ON f.film_id = fc.film_id
            INNER JOIN category AS c ON fc.category_id = c.category_id
    ),
    CTE_C AS (
        SELECT 
            DISTINCT b.category_id,
            b.name,
            100 * (SUM(a.amount) OVER (PARTITION BY b.category_id)) / SUM(a.amount) OVER ()
        FROM
            CTE_A AS a
            INNER JOIN CTE_B AS b ON a.film_id = b.film_id
        ORDER BY
            3 DESC
    )
SELECT
    *
FROM
    CTE_C;

-- 4. What is the average length of films for those rated PG-13?
SELECT
    rating,
    AVG(length) AS average_length
FROM
    film
GROUP BY
    1;

-- Find the difference of the very first recorded day sales (in terms of payments) against the very last day sales.
SELECT
    payment_date,
    amount,
    FIRST_VALUE(amount) OVER(ORDER BY payment_date DESC) AS last_value,
    (amount - (FIRST_VALUE(amount) OVER(ORDER BY payment_date DESC))) AS diff,
    ROW_NUMBER() OVER (ORDER BY payment_date ASC) AS date_rank
FROM
    payment
ORDER BY 2
LIMIT 1;

WITH
    CTE_A (date_by_day, amount)  AS (
        SELECT
            DISTINCT DATE_TRUNC('day', payment_date),
            SUM(amount) OVER (PARTITION BY DATE_TRUNC('day', payment_date))
        FROM
            payment
        ORDER BY 1
    )
SELECT
    *,
    (amount - LAST_VALUE(amount) OVER()) AS diff,
    LAST_VALUE(amount) OVER()
FROM
    CTE_A;


-- 6. Rank the customers in terms of highest number of total payments. Which customer is ranked 5th?
WITH
    CTE_A AS (
        SELECT 
            DISTINCT c.customer_id,
            c.first_name,
            c.last_name,
            SUM(amount) OVER (PARTITION BY c.customer_id) AS total_payments
        FROM
            customer AS c
            INNER JOIN payment AS p ON c.customer_id = p.customer_id
    )
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_payments DESC) AS ranking
FROM
    CTE_A
LIMIT 5;

-- 7. Provide the rankings of films in terms of highest average payment amounts. Which is ranked 7th? Hint: Allow skipping of rank numbers.
WITH
    CTE_A AS (
        SELECT 
            DISTINCT iv.film_id,
            f.title,
            AVG(p.amount) OVER (PARTITION BY iv.film_id) AS average_payment
        FROM
            payment AS p
            INNER JOIN rental AS r ON p.rental_id = r.rental_id
            INNER JOIN inventory AS iv ON r.inventory_id = iv.inventory_id
            INNER JOIN film AS f ON iv.film_id = f.film_id
    )
SELECT
    *,
    RANK() OVER (ORDER BY average_payment DESC)
FROM
    CTE_A;

-- 8. Can you say that there is growth in terms of daily average payment amounts?
WITH
    CTE_A AS (
        SELECT
            DISTINCT DATE_TRUNC('day', payment_date) AS payment_by_day,
            SUM(amount) OVER (PARTITION BY DATE_TRUNC('day', payment_date)) AS total_amount
        FROM
            payment
        ORDER BY 1
    ),
    CTE_B AS (
        SELECT
            *,
            LAG(total_amount, 1) OVER () AS previous_total_amount,
            100 * ((total_amount - LAG(total_amount, 1) OVER ()) / LAG(total_amount, 1) OVER ()) AS rate
        FROM
            CTE_A
    )
SELECT
    *,
    SUM(rate) OVER ()
FROM
    CTE_B;

SELECT
    *
FROM
    customer AS c
    FULL OUTER JOIN address AS a ON c.address_id = a.address_id
-- WHERE
--     c.address_id != a.address_id