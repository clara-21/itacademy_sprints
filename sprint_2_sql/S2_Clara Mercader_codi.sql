-- IT ACADEMY - SPRINT 2 
-- Nom alumne: Clara Mercader Garcia
-- Data: 26/10/2026

---------------------------------
-- NIVELL 1 --
---------------------------------

-- Exercici 1
-- A partir dels documents adjunts (estructura_dades i dades_introduir), importa les dues taules. 
-- Mostra les característiques principals de l'esquema creat i explica les diferents taules i variables que existeixen. 
-- Assegura't d'incloure un diagrama que il·lustri la relació entre les diferents taules i variables.

-- S'obre i s'executa el fitxer "N1-Ex.1__ estructura dades" 
-- Es comprova que s'han creat les taules i els camps que contenen
DESCRIBE company;
DESCRIBE transaction;

-- S'obre i s'executa el fitxer "N1-Ex.1__dades_introduir"
-- Es comprova que les dades de les taules "commpany" i "transaction" s'han introduït correctament
SELECT *
FROM company;

SELECT *
FROM transaction;


-- Exercici 2
-- Utilitzant JOIN realitzaràs les següents consultes:

-- Llistat dels països que estan generant vendes.
SELECT DISTINCT c.country
FROM company AS c
JOIN transaction AS t
	ON c.id = t.company_id
WHERE t.declined = 0
ORDER BY c.country;


-- Des de quants països es generen les vendes.
SELECT COUNT(DISTINCT c.country) AS num_paisos
FROM company AS c
JOIN transaction AS t
	ON c.id = t.company_id
WHERE t.declined = 0;


-- Identifica la companyia amb la mitjana més gran de vendes.
SELECT c.company_name, AVG(t.amount) as mitjana_vendes
FROM company AS c
JOIN transaction AS t
	ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.id, c.company_name
ORDER BY mitjana_vendes DESC
LIMIT 1;


-- Exercici 3
-- Utilitzant només subconsultes (sense utilitzar JOIN):
-- Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT *
FROM transaction
WHERE company_id IN (SELECT id 
						FROM company
                        WHERE country = 'Germany');


-- Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT c.company_name
FROM company AS c
WHERE c.id IN (SELECT transaction.company_id FROM transaction
				WHERE amount > (SELECT AVG(amount) FROM transaction));


-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
SELECT c.company_name
FROM company AS c
WHERE NOT EXISTS (
	SELECT* 
    FROM transaction AS t 
    WHERE c.id = t.company_id
);


-- Exercici 4
-- La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi detalls crucials sobre les targetes de crèdit. 
-- La nova taula ha de ser capaç d'identificar de manera única cada targeta i establir una relació adequada amb les altres dues taules ("transaction" i "company"). 
-- Després de crear la taula serà necessari que ingressis la informació del document denominat "dades_introduir_credit". 
-- Recorda mostrar el diagrama i realitzar una breu descripció d'aquest.

-- Creació de la taula credit_card 
CREATE TABLE credit_card (
	id VARCHAR(15) PRIMARY KEY, 
    iban VARCHAR(50), 
    pan VARCHAR(20), 
    pin VARCHAR(5), 
    cvv VARCHAR(5), 
    expiring_date VARCHAR(30)
    );

-- S'obre i s'executa el fitxer "N1-Ex.4__ datos_introducir_credit"
-- Es comprova que les dades s'han introduït correctament
SELECT *
FROM credit_card;

-- Es comprova que no hi ha transaccions "orfes" de targeta 
SELECT COUNT(*) AS targetes_no_trobades
FROM transaction t
LEFT JOIN credit_card cc
    ON t.credit_card_id = cc.id
WHERE cc.id IS NULL;

-- Es crea la constraint per relacionar la credit_card_id de la taula transaction amb la PK de la taula credit_card
ALTER TABLE transaction
ADD CONSTRAINT fk_Credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card (id);


-- Exercici 5
-- El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit amb ID CcU-2938. 
-- La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999. 
-- Recorda mostrar que el canvi es va realitzar.

-- Comprovem el registre, efectivament la informació no està bé
SELECT id, iban
FROM credit_card 
WHERE id = 'CcU-2938';

-- Actualitzem amb la informació correcta
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

-- Comprovem que s'ha actualitzat
SELECT id, iban
FROM credit_card 
WHERE id = 'CcU-2938';


-- Exercici 6
-- En la taula "transaction" ingressa una nova transacció amb la següent informació:
-- Id 108B1D1D-5B23-A76C-55EF-C568E49A99DD; credit_card_id CcU-9999; company_id b-9999;  
-- user_id 9999; lat 829.999; longitude -117.999; amount 111.11; declined 0

-- Comprovació foreign keys
SELECT id FROM credit_card WHERE id = 'CcU-9999';
SELECT id FROM company WHERE id = 'b-9999';

-- No existeix ni la targeta de crèdit ni la companyia, així que les introduïm a les taules corresponents
INSERT INTO company (id)
VALUES ('b-9999');

INSERT INTO credit_card (id)
VALUES ('CcU-9999');

-- I ara ingressem la nova transacció
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined) VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, NOW() , 111.11, '0');
  
-- Comprovació de que s'ha inserit
SELECT *
FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


-- Exercici 7
-- Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. 
-- Recorda mostrar el canvi realitzat.

-- Eliminem la columna "pan"
ALTER TABLE credit_card
DROP COLUMN pan;

-- Comprovem que s'ha eliminat correctament
DESCRIBE credit_card;


-- Exercici 8
-- Descarrega els arxius CSV que trobaràs a l'apartat de recursos
-- Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui almenys 4 taules de les quals puguis realitzar les següents consultes

DROP DATABASE IF EXISTS transactions_users;
CREATE DATABASE IF NOT EXISTS transactions_users;
USE transactions_users;

-- Creació taula users
CREATE TABLE users (
	id INT PRIMARY KEY, 
    name VARCHAR(100), 
    surname VARCHAR(100), 
    phone VARCHAR(30), 
    email VARCHAR(100), 
    birth_date VARCHAR(30),
	country VARCHAR(30), 
    city VARCHAR(30), 
    postal_code VARCHAR(15), 
    address VARCHAR(150),
	signup_date VARCHAR(30), 
    user_segment VARCHAR(30), 
    income_band VARCHAR(30),
    source_region VARCHAR(20)
    );

-- Mirem que es puguin carregar dades (això per comprovar el servidor + habilitar-ho al workbench (opcions avançades de la connexió, afegim OPT_LOCAL_INFILE = 1) 
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

-- Carreguem taula AMERICAN_USERS
LOAD DATA LOCAL INFILE 'C:/Users/clara/Documents/itacademy/S2/N1-Ex.8__american_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES (id, name, surname, phone, email, birth_date, country, city,
 postal_code, address, signup_date, user_segment, income_band)
SET source_region = 'American';

-- Comprovem que s'ha carregat bé
SELECT *
FROM users
LIMIT 10;

-- Càrrega taula EUROPEAN_USERS
LOAD DATA LOCAL INFILE 'C:/Users/clara/Documents/itacademy/S2/N1-Ex.8__european_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES (id, name, surname, phone, email, birth_date, country, city,
 postal_code, address, signup_date, user_segment, income_band)
SET source_region = 'European';

-- Comprovem que s'han carregat tots els usuaris 
SELECT
    COUNT(*) AS total_usuaris,
    COUNT(DISTINCT id) AS ids_unics,
    MIN(id) AS primer_id,
    MAX(id) AS ultim_id
FROM users;

SELECT source_region, COUNT(*) AS num_users
FROM users
GROUP BY source_region;

-- Creació TAULA COMPANIES
CREATE TABLE companies (
	company_id VARCHAR(15) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(50),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255),
	merchant_category VARCHAR(50), 
	merchant_price_position VARCHAR(50)
    );

-- Càrrega taula COMPANIES
LOAD DATA LOCAL INFILE 'C:/Users/clara/Documents/itacademy/S2/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Comprovem que s'ha carregat bé
SELECT *
FROM companies
LIMIT 10;

-- Creació TAULA CREDIT_CARDS
CREATE TABLE credit_cards (
	id VARCHAR(15) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(50), 
    pan VARCHAR(20), 
    pin VARCHAR(5), 
    cvv VARCHAR(5),
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(30),
    card_type VARCHAR(30),
    card_renewal_flag BOOLEAN
    );

-- Càrrega taula CREDIT_CARDS
LOAD DATA LOCAL INFILE 'C:/Users/clara/Documents/itacademy/S2/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Comprovació
SELECT *
FROM credit_cards
LIMIT 10;

-- Creació TAULA TRANSACTIONS
CREATE TABLE transactions (
	id VARCHAR(255) PRIMARY KEY,
	card_id VARCHAR(15),
	business_id VARCHAR(15), 
    timestamp TIMESTAMP,
    amount DECIMAL(10, 2),
	declined BOOLEAN,
    product_ids TEXT(150),
	user_id INT,
	lat FLOAT,
	longitude FLOAT,
    discount_amount DECIMAL(10, 2),
    tax_amount DECIMAL(10, 2),
    shipping_amount DECIMAL(10, 2),
    channel VARCHAR(50),
    campaign_id VARCHAR(50),
    device_type VARCHAR(50),
    is_international BOOLEAN,
    decline_reason VARCHAR(250),
    distance_km DECIMAL(10, 2)
    );
	
	
-- Càrrega taula transactions
LOAD DATA LOCAL INFILE 'C:/Users/clara/Documents/itacademy/S2/N1-Ex.8__transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Comprovem que s'ha carregat bé
SELECT *
FROM transactions
LIMIT 10;

-- Comprovem que no hi ha registres "orfes" abans de crear FK
SELECT COUNT(*) AS targetes_no_trobades
FROM transactions t
LEFT JOIN credit_cards c
    ON t.card_id = c.id
WHERE c.id IS NULL;

SELECT COUNT(*) AS empreses_no_trobades
FROM transactions t
LEFT JOIN companies c
    ON t.business_id = c.company_id
WHERE c.company_id IS NULL;

SELECT COUNT(*) AS usuaris_no_trobats
FROM transactions t
LEFT JOIN users u
    ON t.user_id = u.id
WHERE u.id IS NULL;

-- Creem FK
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_cards
FOREIGN KEY (card_id)
REFERENCES credit_cards(id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_companies
FOREIGN KEY (business_id)
REFERENCES companies(company_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_users
FOREIGN KEY (user_id)
REFERENCES users(id);

-- Exercici 9
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.

SELECT id, name, surname
FROM users
WHERE id IN (SELECT user_id
			FROM transactions
            GROUP BY user_id
			HAVING COUNT(id) > 80);

-- Exercici 10
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
SELECT cc.iban, ROUND(AVG(t.amount), 2) as mitjana_amount
FROM transactions t
JOIN credit_cards cc
	ON t.card_id = cc.id
JOIN companies co
	ON t.business_id = co.company_id
WHERE co.company_name = 'Donec Ltd' AND t.declined = 0
GROUP BY cc.iban
ORDER BY mitjana_amount DESC;


---------------------------------
-- NIVELL 2 --
---------------------------------

-- Exercici 1
-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
-- Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(timestamp) AS data, SUM(amount) AS total_vendes
FROM transactions
WHERE declined = 0
GROUP BY DATE(timestamp)
ORDER BY total_vendes DESC
LIMIT 5;

-- Exercici 2
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 350 i 400 euros 
-- i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
-- Ordena els resultats de major a menor quantitat.

SELECT co.company_name, co.phone, co.country, DATE(t.timestamp) AS data, t.amount
FROM companies co
JOIN transactions t
	ON t.business_id = co.company_id
WHERE t.amount BETWEEN 350 AND 400 AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY t.amount DESC;

-- Exercici 3
-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, per la qual cosa et demanen la informació sobre 
-- la quantitat de transaccions que realitzen les empreses, però el departament de recursos humans és exigent i vol 
-- un llistat de les empreses on especifiquis si tenen igual o més de 400 transaccions o menys.

SELECT co.company_id, co.company_name, COUNT(t.id) AS num_transaccions, 
CASE
    WHEN COUNT(t.id) >= 400 THEN '400 o més'
    ELSE 'menys de 400'
END AS categoria_transaccions
FROM companies co
LEFT JOIN transactions t
	ON co.company_id = t.business_id
GROUP BY co.company_id, co.company_name
ORDER BY num_transaccions DESC;


-- Exercici 4
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

-- Comprovem que aquesta transacció existeix
SELECT *
FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- L'eliminem de la taula
DELETE FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Comprovem que ja no hi és
SELECT *
FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';


-- Exercici 5
-- La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives. 
-- S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. 
-- Serà necessària que creïs una vista anomenada VistaMarketing que contingui 
-- la següent informació: Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. 
-- Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.

CREATE VIEW VistaMarketing AS
SELECT co.company_name, co.phone, co.country, AVG(t.amount) as mitjana_compra 
FROM companies co
JOIN transactions t
	ON co.company_id = t.business_id
WHERE t.declined = 0
GROUP BY co.company_id;

SELECT *
FROM VistaMarketing
ORDER BY mitjana_compra DESC;


---------------------------------
-- NIVELL 3 --
---------------------------------
-- Exercici 1
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions han estat declinades aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. 
-- Partint d’aquesta taula respon:
-- Quantes targetes estan actives?

-- Comprovem que no hi ha targetes sense transaccions
SELECT COUNT(*) AS targetes_no_usades
FROM credit_cards cc
LEFT JOIN transactions t
    ON cc.id = t.card_id
WHERE t.card_id IS NULL;

-- Creem la taula
CREATE TABLE estat_targetes AS
SELECT card_id, 
CASE
    WHEN SUM(declined) = 3 THEN 'Inactiva'
    ELSE 'Activa'
END AS estat_targeta
FROM (
    SELECT
        card_id,
        timestamp,
        declined,
        ROW_NUMBER() OVER (
            PARTITION BY card_id
            ORDER BY timestamp DESC, id DESC
        ) AS num_transaccio
    FROM transactions
) AS transaccions_numerades
WHERE num_transaccio <= 3
GROUP BY card_id;

-- Recompte de targetes_actives
SELECT COUNT(*) AS targetes_actives
FROM estat_targetes
WHERE estat_targeta = 'Activa';


-- Comprovació que realment no hi ha targetes inactives
SELECT card_id, SUM(declined) AS num_rebutjos
FROM (
    SELECT
        card_id,
        declined,
        ROW_NUMBER() OVER (
            PARTITION BY card_id
            ORDER BY timestamp DESC, id DESC
        ) AS num_transaccio
    FROM transactions
) AS transaccions_numerades
WHERE num_transaccio <= 3
GROUP BY card_id
ORDER BY num_rebutjos DESC
LIMIT 10;


-- Exercici 2
-- Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv amb la base de dades creada (ja que fins ara no podíem fer-ho), tenint en compte que des de transaction tens product_ids. 
-- Genera la següent consulta:
-- Necessitem conèixer el nombre de vegades que s'ha venut cada producte.

-- PAS 1: Creació de la taula products i importació de les dades
CREATE TABLE products (
	id INT PRIMARY KEY, 
    product_name VARCHAR(50), 
    price VARCHAR(30), 
    colour VARCHAR(20), 
    weight DECIMAL (10, 1), 
    warehouse_id VARCHAR(20),
    category VARCHAR(20), 
    brand VARCHAR(20), 
    cost VARCHAR (30), 
    launch_date DATE
    );

LOAD DATA LOCAL INFILE 'C:/Users/clara/Documents/itacademy/S2/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Comprovació de que s'ha carregat bé
SELECT COUNT(*) FROM products;
SELECT * FROM products LIMIT 10;


-- PAS 2: Creació de la taula transaction_products 
CREATE TABLE transaction_products (
    transaction_id VARCHAR(255),
    product_id INT,
    PRIMARY KEY (transaction_id, product_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);


-- Separar els identificadors de transactions.product_ids i inserir una fila per cada parella transacció-producte.
-- Mirem com estan escrits els product_ids
SELECT id, product_ids
FROM transactions
LIMIT 10;

-- Consulta per omplir taula transactions x producte
SELECT
    t.id AS transaction_id,
    p.product_id
FROM transactions t
CROSS JOIN JSON_TABLE(
    CONCAT('[', REPLACE(t.product_ids, ' ', ''), ']'),
    '$[*]' COLUMNS (
        product_id INT PATH '$'
    )
) AS p
LIMIT 20;

-- Comprovem que tots els productes existeixen a la taula products
SELECT COUNT(*) AS productes_inexistents
FROM transactions t
CROSS JOIN JSON_TABLE(
    CONCAT('[', REPLACE(t.product_ids, ' ', ''), ']'),
    '$[*]' COLUMNS (
        product_id INT PATH '$'
    )
) AS p
LEFT JOIN products pr ON p.product_id = pr.id
WHERE pr.id IS NULL;

-- Comprovem que no hi ha combinacions transaction-product duplicades
SELECT t.id, p.product_id, COUNT(*) AS repeticions
FROM transactions t
CROSS JOIN JSON_TABLE(
    CONCAT('[', REPLACE(t.product_ids, ' ', ''), ']'),
    '$[*]' COLUMNS (
        product_id INT PATH '$'
    )
) AS p
GROUP BY t.id, p.product_id
HAVING COUNT(*) > 1;

-- Omplim taula transaction_products
INSERT INTO transaction_products (transaction_id, product_id)
SELECT
    t.id,
    p.product_id
FROM transactions t
CROSS JOIN JSON_TABLE(
    CONCAT('[', REPLACE(t.product_ids, ' ', ''), ']'),
    '$[*]' COLUMNS (
        product_id INT PATH '$'
    )
) AS p;

-- Comprovem que la taula s'ha omplert correctament
SELECT *
FROM transaction_products
ORDER BY transaction_id
LIMIT 25;

-- Recompte productes venuts
SELECT p.id, p.product_name, COUNT(t.id) AS num_vendes
FROM products p
LEFT JOIN transaction_products tp
	ON p.id = tp.product_id
LEFT JOIN transactions t
    ON tp.transaction_id = t.id
    AND t.declined = 0
GROUP BY p.id, p.product_name
ORDER BY num_vendes DESC;