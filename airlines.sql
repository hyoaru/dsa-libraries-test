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


