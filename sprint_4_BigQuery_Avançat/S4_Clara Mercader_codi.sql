-- IT ACADEMY - SPRINT 4 
-- Nom alumne: Clara Mercader Garcia
-- Revisió P2P: Laura Juan
-- Data: 16/11/2026

---------------------------------
-- NIVELL 1 --
---------------------------------

-- Exercici 1
SELECT*
FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean` AS t
JOIN `sprint3-analytics-clara.sprint3_silver.companies_clean` AS c
ON t.business_id = c.company_id
WHERE c.country = "Germany" AND DATE(t.timestamp) = "2022-03-12";


-- Exercici 2
-- PAS 1: Creem la taula transactions_recent amb les dates noves
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_silver.transactions_recent` AS (
  SELECT * EXCEPT (timestamp),
  TIMESTAMP_SUB(
    CURRENT_TIMESTAMP(), 
    INTERVAL (CAST(RAND()*50 AS INT64)) DAY
  ) AS timestamp
  FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean`
);

-- Comprovem que s'ha creat bé i que les dates es troben dins els últims 50 dies
SELECT*
FROM `sprint3-analytics-clara.sprint3_silver.transactions_recent`;

SELECT MIN(DATE(timestamp)) AS data_antiga, MAX(DATE(timestamp)) AS data_recent
FROM `sprint3-analytics-clara.sprint3_silver.transactions_recent`;


-- PAS 2: Creem la taula optimitzada "transactions_optimized"
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_gold.fact_transactions_optimized` 
  PARTITION BY DATE(timestamp)
  CLUSTER BY business_id
AS(
  SELECT *
  FROM `sprint3-analytics-clara.sprint3_silver.transactions_recent`
);


-- Exercici 3
-- Pas 1: Creem la consulta
SELECT*
FROM `sprint3-analytics-clara.sprint3_silver.transactions_recent`
WHERE DATE(timestamp) 
  BETWEEN DATE_SUB (CURRENT_DATE(), INTERVAL 30 DAY)
  AND CURRENT_DATE();

-- PAS 2: Fem la versió amb la taula optimitzada
SELECT*
FROM `sprint3-analytics-clara.sprint3_gold.fact_transactions_optimized`
WHERE DATE(timestamp) 
  BETWEEN DATE_SUB (CURRENT_DATE(), INTERVAL 30 DAY)
  AND CURRENT_DATE();


-- Exercici 4
-- Creem la vista materialitzada
CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-clara.sprint3_gold.mv_daily_sales` AS
SELECT
  DATE(timestamp) AS data_vendes,
  SUM(amount) AS total_vendes
FROM `sprint3-analytics-clara.sprint3_gold.fact_transactions_optimized`
WHERE declined = "0"
GROUP BY DATE(timestamp);

-- Consultem la vista
SELECT data_vendes, ROUND(total_vendes, 2) AS total_vendes
FROM `sprint3-analytics-clara.sprint3_gold.mv_daily_sales`
ORDER BY data_vendes DESC;


---------------------------------
-- NIVELL 2 --
---------------------------------

-- Exercici 1
WITH VIP_Stats AS (
    SELECT
        t.user_id AS user_id,
        SUM(t.amount) AS total_gastat,
        COUNT(t.transaction_id) AS num_compres,
        ROUND(AVG(t.amount), 2) AS tiquet_mig,
        MAX(t.amount) AS max_compra
    FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean` AS t
    WHERE t.declined = "0"
    GROUP BY t.user_id
    HAVING total_gastat > 500
)
SELECT 
  u.user_id, 
  u.name AS nom_complet, 
  u.email, 
  vs.num_compres, 
  vs.tiquet_mig,
  vs.max_compra,
  vs.total_gastat 
FROM VIP_Stats AS vs
JOIN `sprint3-analytics-clara.sprint3_silver.users_combined` AS u
ON u.user_id = vs.user_id
ORDER BY total_gastat DESC;

-- Exercici 2
-- Construim la consulta; primer la CTE i després el càlcul de diff_percentual
WITH comparativa_diaria AS (
    SELECT
        data_vendes AS Data,
        total_vendes AS Vendes_Avui,
        LAG(total_vendes) OVER (ORDER BY data_vendes) AS Vendes_Ahir
    FROM `sprint3-analytics-clara.sprint3_gold.mv_daily_sales`
)
SELECT *,
  ROUND(SAFE_DIVIDE((Vendes_Avui - Vendes_Ahir), Vendes_Ahir) * 100,2) AS Diff_Percentual
FROM comparativa_diaria
ORDER BY Data;


-- Exercici 3
SELECT
  data_vendes AS data,
  ROUND(total_vendes, 2) AS Vendes_Dia,
  ROUND(
    SUM(total_vendes) OVER (
      PARTITION BY EXTRACT(YEAR FROM data_vendes)
      ORDER BY data_vendes
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ),2
  ) AS Vendes_Acumulades_YTD
FROM `sprint3-analytics-clara.sprint3_gold.mv_daily_sales`
ORDER BY data_vendes;


-- Exercici 4
-- Creem el llistat
WITH primeres_compres AS (
  SELECT
      user_id,
      timestamp,
      amount,
      ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY timestamp, transaction_id
      ) AS num_compra 
  FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean`
  WHERE declined = "0"
  QUALIFY num_compra <= 3
),
estadistiques_inicials AS (
  SELECT
    user_id,
    ROUND(AVG(amount),2) AS mitjana_compres,
    MAX(IF(num_compra = 3, timestamp, NULL)) AS data_tercera_compra,
    MAX(IF(num_compra = 3, amount, NULL)) AS import_tercera_compra
  FROM primeres_compres
  GROUP BY user_id
  HAVING COUNT(*) = 3
)
SELECT
  u.user_id,
  u.name AS nom_complet,
  u.email,
  ei.data_tercera_compra,
  ei.import_tercera_compra,
  ei.mitjana_compres
FROM estadistiques_inicials AS ei
JOIN `sprint3-analytics-clara.sprint3_silver.users_combined` AS u
ON u.user_id = ei.user_id;

-- Comprovació tercera compra per a user_id 1
SELECT timestamp, amount
FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean`
WHERE user_id = "1" AND declined = "0"
ORDER BY timestamp, transaction_id;


---------------------------------
-- NIVELL 3 --
---------------------------------

-- Exercici 1
-- Creem la taula dim_transactions_flat
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_gold.dim_transactions_flat` AS (
  SELECT
      t.transaction_id,
      DATE(t.timestamp) AS timestamp,
      t.amount AS total_ticket,
      p.product_id,
      p.name AS product_name,
      p.price AS product_price
  FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean` AS t
  CROSS JOIN UNNEST(t.product_ids) AS product_id
  JOIN `sprint3-analytics-clara.sprint3_silver.products_clean` AS p
  ON CAST(product_id AS string) = p.product_id
  WHERE t.declined = "0"
);

-- Comprovem que s'ha creat bé
SELECT *
FROM `sprint3-analytics-clara.sprint3_gold.dim_transactions_flat`
ORDER BY transaction_id
LIMIT 10;

-- Exercici 2
SELECT product_id, product_name, COUNT(*) AS num_vendes
FROM `sprint3-analytics-clara.sprint3_gold.dim_transactions_flat`
GROUP BY product_id, product_name
ORDER BY num_vendes DESC
LIMIT 5;


-- Exercici 3
-- PAS 1: Creem una funció SQL persistent anomenada calculate_tax(amount) 
CREATE OR REPLACE FUNCTION `sprint3-analytics-clara.sprint3_gold.calculate_tax`(amount FLOAT64)
RETURNS FLOAT64
AS (amount * 1.21);

-- Comprovem que funciona
SELECT `sprint3-analytics-clara.sprint3_gold.calculate_tax`(100) AS preu_amb_iva;


-- PAS 2A: Modifiquem la taula de l'exercici 1 per incloure product_price_tax_inc
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_gold.dim_transactions_flat` AS (
  SELECT
      t.transaction_id,
      DATE(t.timestamp) AS timestamp,
      t.amount AS total_ticket,
      p.product_id,
      p.name AS product_name,
      p.price AS product_price,
      `sprint3-analytics-clara.sprint3_gold.calculate_tax`(p.price) AS product_price_tax_inc
  FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean` AS t
  CROSS JOIN UNNEST(t.product_ids) AS product_id
  JOIN `sprint3-analytics-clara.sprint3_silver.products_clean` AS p
  ON CAST(product_id AS string) = p.product_id
  WHERE t.declined = "0"
);

-- Comprovem que s'ha creat bé
SELECT
    product_name,
    product_price,
    product_price_tax_inc
FROM `sprint3-analytics-clara.sprint3_gold.dim_transactions_flat`
LIMIT 10;




