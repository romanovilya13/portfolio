--Давайте создадим пример базы данных и оптимизируем медленный запрос.
--Создание базы данных и таблиц

--Пусть у нас есть база данных "online_store" с таблицами "orders" и "products".
  
  CREATE DATABASE online_store;
  USE online_store;
  
  CREATE TABLE products (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    category_id INT NOT NULL
  );
  
  CREATE TABLE orders (
    id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    product_id INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id)
  );

--Медленный запрос
--Пусть у нас есть запрос, который выбирает все заказы за последний месяц, где сумма заказа превышает 1000 рублей, и группирует результаты по категориям продуктов.

SELECT 
  p.category_id, 
  COUNT(o.id) AS order_count, 
  SUM(o.total) AS total_sum
FROM 
  orders o 
  JOIN products p ON o.product_id = p.id
WHERE 
  o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
  AND o.total > 1000
GROUP BY 
  p.category_id;

--Анализ и оптимизация

--1) Индексация: Создадим индексы на столбцы, используемые в WHERE и JOIN.
CREATE INDEX idx_orders_order_date ON orders (order_date);
CREATE INDEX idx_orders_product_id ON orders (product_id);
CREATE INDEX idx_products_category_id ON products (category_id);

--2) Перефразирование логики: Переформулируем запрос, используя подзапросы вместо JOIN.
  SELECT 
  p.category_id, 
  COUNT(o.id) AS order_count, 
  SUM(o.total) AS total_sum
FROM 
  products p
WHERE 
  p.id IN (
    SELECT 
      o.product_id
    FROM 
      orders o
    WHERE 
      o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
      AND o.total > 1000
  )
GROUP BY 
  p.category_id;

--3) Партиционирование: Разделим таблицу orders на партиции по месяцам, чтобы ускорить доступ к данным за последний месяц.
  CREATE TABLE orders_partitioned (
  id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date DATE NOT NULL,
  total DECIMAL(10, 2) NOT NULL,
  product_id INT NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
) PARTITION BY RANGE (YEAR(order_date), MONTH(order_date));

CREATE PARTITION orders_partitioned_q1 VALUES LESS THAN (2023, 4);
CREATE PARTITION orders_partitioned_q2 VALUES LESS THAN (2023, 7);
CREATE PARTITION orders_partitioned_q3 VALUES LESS THAN (2023, 10);
CREATE PARTITION orders_partitioned_q4 VALUES LESS THAN MAXVALUE;

--По итогу мы имеем оптимизированный запрос
SELECT 
  p.category_id, 
  COUNT(o.id) AS order_count, 
  SUM(o.total) AS total_sum
FROM 
  products p
WHERE 
  p.id IN (
    SELECT 
      o.product_id
    FROM 
      orders_partitioned o
    WHERE 
      o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
      AND o.total > 1000
  )
GROUP BY 
  p.category_id;
