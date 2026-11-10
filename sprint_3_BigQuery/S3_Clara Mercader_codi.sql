-- IT ACADEMY - SPRINT 3 
-- Nom alumne: Clara Mercader Garcia
-- Data: 10/11/2026

---------------------------------
-- NIVELL 1 --
---------------------------------

-- Exercici 1
-- Creem el dataset "Silver" usant codi SQL
CREATE SCHEMA IF NOT EXISTS `sprint3-analytics-clara.sprint3_silver`
OPTIONS (
    location = 'EU'
);

-- Afegim descripció de les capes
ALTER SCHEMA `sprint3-analytics-clara.sprint3_bronze`
SET OPTIONS (
  description = 'Capa de dades originals, sense transformacions, que conserva les fonts per garantir-ne la traçabilitat.'
);

ALTER SCHEMA `sprint3-analytics-clara.sprint3_silver`
SET OPTIONS (
  description = 'Capa de transformació i qualitat de dades. Conté taules natives amb noms i tipus de dades estandarditzats, tractament de valors incorrectes i unificació de fonts, preparades per a l\'anàlisi.'
);

ALTER SCHEMA `sprint3-analytics-clara.sprint3_gold`
SET OPTIONS (
  description = 'Capa de consum analític. Conté vistes i taules amb indicadors de negoci, agregacions i classificacions calculades a partir de Silver, preparades per a informes i visualitzacions.'
);


-- Exercici 2
-- Creem la taula "companies_raw"
CREATE OR REPLACE EXTERNAL TABLE 
  `sprint3-analytics-clara.sprint3_bronze.companies_raw`
(
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);

-- Comprovem que existeix
SELECT*
FROM `sprint3-analytics-clara.sprint3_bronze.companies_raw`
LIMIT 10;


-- Creem la taula "american_users"
CREATE OR REPLACE EXTERNAL TABLE 
  `sprint3-analytics-clara.sprint3_bronze.american_users_raw`
(
  id STRING, 
  name STRING, 
  surname STRING, 
  phone STRING, 
  email STRING, 
  birth_date STRING,
	country STRING, 
  city STRING, 
  postal_code STRING, 
  address STRING
)

OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);

-- Comprovem que existeix
SELECT*
FROM `sprint3-analytics-clara.sprint3_bronze.american_users_raw`
LIMIT 10;


-- Creem la taula "european_users"
CREATE OR REPLACE EXTERNAL TABLE 
  `sprint3-analytics-clara.sprint3_bronze.european_users_raw`
(
  id STRING, 
  name STRING, 
  surname STRING, 
  phone STRING, 
  email STRING, 
  birth_date STRING,
	country STRING, 
  city STRING,  
  postal_code STRING, 
  address STRING
)

OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);

-- Comprovem que existeix
SELECT*
FROM `sprint3-analytics-clara.sprint3_bronze.european_users_raw`
LIMIT 10;


-- Creem la taula "credit_cards"
CREATE OR REPLACE EXTERNAL TABLE 
  `sprint3-analytics-clara.sprint3_bronze.credit_cards_raw`
(
  id STRING, 
  user_id STRING, 
  iban STRING, 
  pan STRING, 
  pin STRING, 
  cvv STRING,
	track1 STRING, 
  track2 STRING,  
  expiring_date STRING
)

OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);

-- Comprovem que existeix
SELECT*
FROM `sprint3-analytics-clara.sprint3_bronze.credit_cards_raw`
LIMIT 10;


-- Creem la taula "transactions"
CREATE OR REPLACE EXTERNAL TABLE 
  `sprint3-analytics-clara.sprint3_bronze.transactions_raw`
(
  id STRING, 
  card_id STRING, 
  business_id STRING, 
  timestamp STRING, 
  amount STRING, 
  declined STRING,
	product_ids STRING, 
  user_id STRING,
  lat STRING,  
  longitude STRING
)

OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  skip_leading_rows = 1,
  field_delimiter = ';'
);

-- Comprovem que existeix
SELECT*
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw`
LIMIT 10;


-- Exercici 3
-- Taula carregada mitjançant interfície gràfica
-- Comprovem que s'ha creat bé
SELECT *
FROM `sprint3-analytics-clara.sprint3_bronze.products_raw`
LIMIT 10;

SELECT COUNT(*) AS total_registres
FROM `sprint3-analytics-clara.sprint3_bronze.products_raw`;


-- Exercici 4
-- Exercici 4a: Materialització de dades amb IA.
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`
AS
SELECT * FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw`;

-- Comprovem que s'ha creat bé
SELECT *
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`
LIMIT 10;


-- Exercici 4b: Auditoria de costos
-- Taula externa
SELECT id
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw`;

-- Taula nativa
SELECT id
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`;


-- Exercici 4c: El perill del Limit
SELECT *
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`;

SELECT *
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`
LIMIT 10;

SELECT id
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`;

SELECT *
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw`
LIMIT 10;


-- Exercici 5
-- Comprovem com estan escrits els camps que necessitem a la taula
SELECT timestamp,amount,declined
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`
LIMIT 10;


-- Fem la consulta
SELECT
  DATE(CAST(timestamp AS DATETIME)) AS data_convertida,
  SUM(CAST(amount AS DECIMAL)) AS ingres_dia 
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw_native`
WHERE CAST(declined AS NUMERIC) = 0 AND EXTRACT(YEAR FROM DATE(CAST(timestamp AS DATETIME))) = 2021
GROUP BY data_convertida
ORDER BY ingres_dia DESC
LIMIT 5;


-- Exercici 6
-- Interpretació 1: mostrem només les transaccions que compleixen les condicions de data i import
SELECT c.company_name, c.country, DATE(CAST(t.timestamp AS DATETIME)) AS data_transaccio
FROM `sprint3-analytics-clara.sprint3_bronze.companies_raw` AS c
JOIN `sprint3-analytics-clara.sprint3_bronze.transactions_raw` AS t
ON c.company_id = t.business_id
WHERE CAST(t.amount AS DECIMAL) BETWEEN 100 AND 200 AND DATE(CAST(t.timestamp AS DATETIME)) IN ('2015-04-29', '2018-07-20', '2024-03-13');


---------------------------------
-- NIVELL 2 --
---------------------------------

-- Exercici 1
-- Creem la taula products_clean al dataset “silver”
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_silver.products_clean` AS
SELECT 
  id AS product_id,
  product_name AS name,
  CAST(REPLACE(price, '$', '') AS FLOAT64) AS price,
  colour,
  weight,
  CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  category,
  brand,
  cost,
  launch_date
FROM `sprint3-analytics-clara.sprint3_bronze.products_raw`;
  
-- Comprovem que s'ha creat bé
SELECT *
FROM `sprint3-analytics-clara.sprint3_silver.products_clean`
LIMIT 10;


-- Exercici 2
-- Creem la taula transactions_clean
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_silver.transactions_clean` AS
SELECT 
  id AS transaction_id,
  card_id,
  business_id,
  SAFE_CAST(timestamp AS TIMESTAMP) AS timestamp,
  IFNULL(SAFE_CAST(amount AS DECIMAL), 0) AS amount,
  declined,
  ARRAY(
    SELECT SAFE_CAST(element AS INT64)
    FROM UNNEST(SPLIT(product_ids, ',')) AS element
  ) AS product_ids,
  user_id,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-clara.sprint3_bronze.transactions_raw`;

-- Comprovem que s'ha creat bé
SELECT*
FROM `sprint3-analytics-clara.sprint3_silver.transactions_clean`
LIMIT 10;


-- Exercici 3
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_silver.users_combined` AS
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'USA' AS origin
FROM `sprint3-analytics-clara.sprint3_bronze.american_users_raw`
UNION ALL
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'EUROPE' AS origin
FROM `sprint3-analytics-clara.sprint3_bronze.european_users_raw`;

-- Comprovem que s'ha creat bé
SELECT*
FROM `sprint3-analytics-clara.sprint3_silver.users_combined`
LIMIT 10;

-- Comprovem que la taula users_combined conté la suma de les d'usuaris USA i Europa
SELECT COUNT(id)
FROM `sprint3-analytics-clara.sprint3_bronze.american_users_raw`;

SELECT COUNT(id)
FROM `sprint3-analytics-clara.sprint3_bronze.european_users_raw`;

SELECT COUNT(user_id) AS usuaris_origen
FROM `sprint3-analytics-clara.sprint3_silver.users_combined`
GROUP BY origin;

-- Comprovem que no hi ha ids duplicats
SELECT user_id, COUNT(*) AS duplicats
FROM `sprint3-analytics-clara.sprint3_silver.users_combined`
GROUP BY user_id
HAVING duplicats >1;


-- Exercici 4
-- Creem la taula companies_clean
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_silver.companies_clean` AS
SELECT *
FROM `sprint3-analytics-clara.sprint3_bronze.companies_raw`;

-- Comprovem que s'ha creat bé
SELECT COUNT(*)
FROM `sprint3-analytics-clara.sprint3_silver.companies_clean`;

-- Creem la taula credit_cards_clean
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_silver.credit_cards_clean` AS
SELECT
  id as credit_card_id,
  * EXCEPT(id)
FROM `sprint3-analytics-clara.sprint3_bronze.credit_cards_raw`;

-- Comprovem que s'ha creat bé
SELECT COUNT(*)
FROM `sprint3-analytics-clara.sprint3_silver.credit_cards_clean`;


---------------------------------
-- NIVELL 3 --
---------------------------------

-- Exercici 1
CREATE OR REPLACE VIEW `sprint3-analytics-clara.sprint3_gold.v_marketing_kpis` AS(
  SELECT 
    c.company_name, 
    c.phone, 
    c.country, 
    ROUND(AVG(t.amount),2) AS mitjana_compra, 
    CASE
      WHEN AVG(t.amount) > 260 THEN "Premium"
      ELSE "Standard"
    END AS client_tier
  FROM `sprint3-analytics-clara.sprint3_silver.companies_clean` AS c
  LEFT JOIN `sprint3-analytics-clara.sprint3_silver.transactions_clean` AS t
    ON t.business_id = c.company_id AND t.declined = '0'
  GROUP BY c.company_id, c.company_name, c.phone, c.country
);

SELECT *
FROM `sprint3-analytics-clara.sprint3_gold.v_marketing_kpis`
ORDER BY client_tier ASC, mitjana_compra DESC;

-- Exercici 2
-- Creem la taula "product_sales_ranking"
CREATE OR REPLACE TABLE `sprint3-analytics-clara.sprint3_gold.product_sales_ranking` AS(
  SELECT
    p.product_id,
    p.name,
    p.price,
    p.colour,
    COUNT(t.transaction_id) AS total_sold
  FROM `sprint3-analytics-clara.sprint3_silver.products_clean` AS p
  LEFT JOIN `sprint3-analytics-clara.sprint3_silver.transactions_clean` AS t
    ON CAST(p.product_id AS INT64) IN UNNEST(t.product_ids) AND t.declined = '0'
  GROUP BY p.product_id, p.name, p.price, p.colour
);

-- Comprovem que s'ha creat bé
SELECT*
FROM `sprint3-analytics-clara.sprint3_gold.product_sales_ranking`
ORDER BY total_sold DESC; 
