-------------------------------------------------------------- Сreate ------------------------------------------------------------------------------
CREATE TABLE PRODUCTS (
  ID integer NOT NULL,
  CODE varchar(50)NOT NULL,
  NAME varchar(200) NOT NULL,
  CONSTRAINT PRODUCTS_PK PRIMARY KEY (ID),
  CONSTRAINT PRODUCTS_CODE_UK UNIQUE (CODE)
);

CREATE TABLE SHOPS (
  ID integer NOT NULL,
  NAME varchar(200) NOT NULL,
  REGION varchar(200) NOT NULL,
  CITY varchar(200) NOT NULL,
  ADDRESS varchar(200) NOT NULL,
  MANAGER_ID integer,
  CONSTRAINT SHOPS_PK PRIMARY KEY (ID)
);

CREATE TABLE EMPLOYEES (
  ID integer NOT NULL,
  FIRST_NAME varchar(100) NOT NULL,
  LAST_NAME varchar(100) NOT NULL,
  JOB_NAME varchar(100) NOT NULL,
  SHOP_ID integer,
  CONSTRAINT EMPLOYEES_PK PRIMARY KEY (ID)
);

CREATE TABLE PURCHASES (
  ID integer NOT NULL,
  DATETIME date NOT NULL,
  AMOUNT integer NOT NULL,
  SELLER_ID integer,
  CONSTRAINT PURCHASES_PK PRIMARY KEY (ID)
);

CREATE TABLE PURCHASE_RECEIPTS (
  PURCHASE_ID integer,
  ORDINAL_NUMBER integer,
  PRODUCT_ID integer,
  QUANTITY decimal(10, 5),
  AMOUNT_FULL integer NOT NULL,
  AMOUNT_DISCOUNT integer,
  CONSTRAINT PURCHASE_RECEIPTS_PK PRIMARY KEY (PURCHASE_ID, ORDINAL_NUMBER)
);


----------------------------------------------------------- Добавление внешних ключей-------------------------------------------------------------------
ALTER TABLE SHOPS
  ADD CONSTRAINT SHOPS_EMPLOYEES_FK FOREIGN KEY (MANAGER_ID) REFERENCES EMPLOYEES (ID);

ALTER TABLE EMPLOYEES
  ADD CONSTRAINT EMPLOYEES_SHOPS_FK FOREIGN KEY (SHOP_ID) REFERENCES SHOPS (ID);

ALTER TABLE PURCHASES
  ADD CONSTRAINT PURCHASES_EMPLOYEES_FK FOREIGN KEY (SELLER_ID) REFERENCES EMPLOYEES (ID);

ALTER TABLE PURCHASE_RECEIPTS
  ADD CONSTRAINT PURCHASE_RECEIPTS_PRODUCTS_FK FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS (ID),
  ADD CONSTRAINT PURCHASE_RECEIPTS_PURCHASES_FK FOREIGN KEY (PURCHASE_ID) REFERENCES PURCHASES (ID);


----------------------------------------------------------------Insert-----------------------------------------------------------------------------------
INSERT INTO PRODUCTS (ID, CODE, NAME)
VALUES
  (3001, 'AB123', 'Product1'),
  (3002, 'CD456', 'Product2'),
  (3003, 'EF789', 'Product3');

INSERT INTO EMPLOYEES (ID, FIRST_NAME, LAST_NAME, JOB_NAME, SHOP_ID)
VALUES
  (101, 'Nikolay', 'Sovkov', 'Manager', NULL),
  (102, 'Ivan', 'Uglov', 'Manager', NULL),
  (103, 'Michael', 'Kirkorov', 'Manager', NULL);

INSERT INTO SHOPS (ID, NAME, REGION, CITY, ADDRESS, MANAGER_ID)
VALUES
  (1, 'Supermarket1', 'Khakassia', 'City1', 'Address1', 101),
  (2, 'Supermarket2', 'Khakassia', 'City2', 'Address2', 102),
  (3, 'Supermarket3', 'Komi', 'City3', 'Address3', 103);

UPDATE EMPLOYEES
   SET SHOP_ID = (SELECT ID
                  FROM SHOPS
                  WHERE SHOPS.MANAGER_ID = EMPLOYEES.ID)
WHERE EXISTS (SELECT ID
              FROM SHOPS
              WHERE SHOPS.MANAGER_ID = EMPLOYEES.ID);

INSERT INTO EMPLOYEES (ID, FIRST_NAME, LAST_NAME, JOB_NAME, SHOP_ID)
VALUES
  (104, 'John', 'Petrov', 'seller', 1),
  (105, 'Ivan', 'Ivanov', 'seller', 2),
  (106, 'Irina', 'Sidorova', 'seller', 3);

INSERT INTO PURCHASES (ID, DATETIME, AMOUNT, SELLER_ID)
VALUES
  (1001, '2022-01-15', 50, 104),
  (1002, '2022-02-10', 100, 105),
  (1003, '2022-02-10', 100, 105),
  (1004, '2022-03-10', 100, 105),
  (1005, '2022-03-05', 75, 106),
  (1006, '2022-03-24', 75, 106),
  (1007, '2024-03-24', 75, 106),
  (1008, '2024-03-25', 175, 106),
  (1009, '2024-03-21', 175, 104),
  (1010, '2024-04-21', 105, 104),
  (1011, '2024-04-21', 10, 104);

INSERT INTO PURCHASE_RECEIPTS (PURCHASE_ID, ORDINAL_NUMBER, PRODUCT_ID, QUANTITY, AMOUNT_FULL, AMOUNT_DISCOUNT)
VALUES
  (1001, 1, 3001, 2, 20, 0),
  (1002, 2, 3002, 1, 15, 0),
  (1003, 2, 3003, 3, 25, 2),
  (1004, 1, 3001, 3, 30, 5),
  (1005, 2, 3002, 1, 15, 0),
  (1006, 1, 3001, 2, 20, 0),
  (1007, 2, 3002, 1, 15, 0),
  (1008, 2, 3001, 3, 25, 2),
  (1009, 1, 3001, 3, 30, 5),
  (1010, 2, 3001, 1, 105, 0),
  (1011, 2, 3001, 1, 10, 0);


-------------------------------------------------------------------Select---------------------------------------------------------------------------------
 
/*1. С целью повышения эффективности магазинов отделу маркетинга необходимы следующие отчёты за
предыдущий месяц. Отчёт формируется на дату запуска за предыдущий календарный месяц.*/
--a. Коды и названия товаров, по которым не было покупок.
SELECT 
		p.CODE, 
		p.NAME
FROM PRODUCTS p
WHERE p.CODE NOT IN (
	SELECT p.CODE
	FROM PRODUCTS p
	LEFT JOIN PURCHASE_RECEIPTS pr
	ON P.id = pr.PRODUCT_ID
	LEFT JOIN PURCHASES pu
	ON pr.PURCHASE_id = pu.ID
	WHERE pu.DATETIME >= date_trunc('month', CURRENT_DATE) - interval '1 month' 
						AND pu.DATETIME < date_trunc('month', CURRENT_DATE)
				);

--b. В разрезе магазинов имена и фамилии продавцов, которые не совершили ни одной продажи, а также самых эффективных продавцов (по полученной выручке).
SELECT 
		e.FIRST_NAME, 
		e.LAST_NAME, 
		e.JOB_NAME, 
		e.SHOP_ID
FROM EMPLOYEES e 
WHERE e.ID NOT IN (						
					SELECT e.ID
					FROM EMPLOYEES e 
					LEFT JOIN PURCHASES pu 
					ON e.ID = pu.SELLER_ID
					WHERE pu.DATETIME >= date_trunc('month', CURRENT_DATE) - interval '1 month' 
										AND pu.DATETIME < date_trunc('month', CURRENT_DATE)
					);

				
--Cамые эффективные продавцы (по полученной выручке) в каждом магазине			
WITH sum_salles_previous_month AS (
	SELECT e.ID, 
			FIRST_NAME, 
			LAST_NAME, 
			JOB_NAME, 
			SHOP_ID, 
			sum(pu.AMOUNT) AS SUM_AMONT
	FROM EMPLOYEES e 
	LEFT JOIN PURCHASES pu 
	ON e.ID = pu.SELLER_ID
	WHERE pu.DATETIME >= date_trunc('month', CURRENT_DATE) - interval '1 month' 
						AND pu.DATETIME < date_trunc('month', CURRENT_DATE)	
	GROUP BY e.ID
),
ranked_sellers AS (
	SELECT 
			*, 
			RANK() OVER (PARTITION BY SUM_AMONT) AS runk_sum
	FROM sum_salles_previous_month
)
SELECT 
	 ID, 
	 FIRST_NAME, 
	 LAST_NAME, 
	 JOB_NAME, 
	 SHOP_ID, 
	 SUM_AMONT
FROM ranked_sellers
WHERE runk_sum = 1;	

--c. Выручка в разрезе регионов. Упорядочите результат по убыванию выручки.
SELECT 
	sum(pu.AMOUNT) AS SUM_AMONT, 
	s.REGION
FROM PURCHASES pu
LEFT JOIN EMPLOYEES e
ON pu.SELLER_ID = e.ID
LEFT JOIN SHOPS s
ON e.SHOP_ID = s.ID
WHERE pu.DATETIME >= date_trunc('month', CURRENT_DATE) - interval '1 month' 
						AND pu.DATETIME < date_trunc('month', CURRENT_DATE)
GROUP BY s.REGION
ORDER BY SUM_AMONT DESC;


/*2. Выяснилось, что в результате программного сбоя в части магазинов в некоторые дни полная
стоимость покупки не бьётся с её разбивкой по товарам. Выведите такие магазины и дни, в которые в
них случился сбой, а также сумму расхождения между полной стоимостью покупки и суммой по чеку.*/
SELECT 
	s.NAME,
    pu.DATETIME,
    --COALESCE(pu.AMOUNT, 0) AS pu_amount,
    --COALESCE(pr.AMOUNT_FULL, 0) AS pr_amount_full,
    --COALESCE(pr.AMOUNT_DISCOUNT, 0) AS pr_amount_discount,
    (COALESCE(pu.AMOUNT, 0) - (COALESCE(pr.AMOUNT_FULL, 0) - COALESCE(pr.AMOUNT_FULL, 0)*0.01*COALESCE(pr.AMOUNT_DISCOUNT, 0))) AS difference
FROM SHOPS s
LEFT JOIN EMPLOYEES e 
ON s.ID = e.SHOP_ID
LEFT JOIN PURCHASES pu 
ON e.ID = pu.SELLER_ID
LEFT JOIN PURCHASE_RECEIPTS pr 
ON pu.ID = pr.PURCHASE_ID
WHERE pu.DATETIME IS NOT NULL
AND (COALESCE(pu.AMOUNT, 0) - (COALESCE(pr.AMOUNT_FULL, 0) - COALESCE(pr.AMOUNT_FULL, 0)*0.01*COALESCE(pr.AMOUNT_DISCOUNT, 0))) > 0;


					