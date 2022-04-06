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
