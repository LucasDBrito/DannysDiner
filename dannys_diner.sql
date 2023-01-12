CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;


CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);


INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 


CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);


INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  


CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);


INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


Case Study Questions
   --------------------*/


-- 1. What is the total amount each customer spent at the restaurant?


    SELECT dannys_diner.sales.customer_id, SUM(dannys_diner.menu.price) AS Total_Spent
    FROM dannys_diner.sales
    INNER JOIN dannys_diner.menu
    ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
    GROUP BY dannys_diner.sales.customer_id;


| customer_id | total_spent |
| ----------- | ----------- |
| B           | 74          |
| C           | 36          |
| A           | 76          |


---


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id ,COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY dannys_diner.sales.customer_id
;


| customer_id | count |
| ----------- | ----- |
| A           | 4     |
| B           | 6     |
| C           | 2     |


---



-- 3. What was the first item from the menu purchased by each customer?

WITH first_purchased AS
    (SELECT customer_id, order_date, product_name,
     DENSE_RANK() OVER(PARTITION BY dannys_diner.sales.customer_id
     ORDER BY dannys_diner.sales.order_date) AS rank
     FROM dannys_diner.sales
     JOIN dannys_diner.menu
     ON dannys_diner.sales.product_id = dannys_diner.menu.product_id)
    
    SELECT customer_id, product_name
    FROM first_purchased
    WHERE rank = 1
    GROUP BY customer_id, product_name;


| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |


---



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


    SELECT dannys_diner.menu.product_name, COUNT(dannys_diner.sales.product_id) AS most_purchased
    FROM dannys_diner.sales
    JOIN dannys_diner.menu
    ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
    GROUP BY dannys_diner.menu.product_name
    ORDER BY most_purchased DESC
    LIMIT 1;


| product_name | most_purchased |
| ------------ | -------------- |
| ramen        | 8              |


---




-- 5. Which item was the most popular for each customer?


    WITH most_purchased AS
(SELECT sales.customer_id, menu.product_name, COUNT(sales.product_id) AS order_count, 
 DENSE_RANK() OVER(PARTITION BY sales.customer_id 
                   ORDER BY count(sales.product_id) DESC) AS rank
 FROM dannys_diner.menu AS menu
 JOIN dannys_diner.sales AS sales
 ON menu.product_id=sales.product_id
 GROUP BY sales.customer_id, menu.product_name)
 SELECT customer_id, product_name, order_count
 FROM most_purchased
 where rank=1;




| customer_id | product_name | order_count |
| ----------- | ------------ | ----------- |
| A           | ramen        | 3           |
| B           | ramen        | 2           |
| B           | curry        | 2           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |


---





-- 6. Which item was purchased first by the customer after they became a member?
    WITH member_orders AS
    (SELECT sales.customer_id, sales.order_date, menu.product_name,
    DENSE_RANK () OVER(PARTITION BY sales.customer_id
                       ORDER BY sales.order_date) AS rank
    FROM dannys_diner.sales AS sales
    INNER JOIN dannys_diner.members AS members
    ON sales.customer_id=members.customer_id
    INNER JOIN dannys_diner.menu AS menu
    ON sales.product_id=menu.product_id
    WHERE sales.order_date > members.join_date)
    SELECT customer_id, product_name AS first_order
    FROM member_orders
    WHERE rank=1;


| customer_id | first_order |
| ----------- | ----------- |
| A           | ramen       |
| B           | sushi       |


---




-- 7. Which item was purchased just before the customer became a member?


    WITH pre_member AS
    (SELECT sales.customer_id, sales.order_date, menu.product_name,
    DENSE_RANK () OVER(PARTITION BY sales.customer_id
                       ORDER BY sales.order_date DESC) AS rank
    FROM dannys_diner.sales AS sales
    INNER JOIN dannys_diner.members AS members
    ON sales.customer_id=members.customer_id
    INNER JOIN dannys_diner.menu AS menu
    ON sales.product_id=menu.product_id
    WHERE sales.order_date < members.join_date)
    SELECT customer_id, product_name
    FROM pre_member
    where rank=1;


| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |


---





-- 8. What is the total items and amount spent for each member before they became a member?


    SELECT sales.customer_id,  COUNT(sales.product_id) AS total_orders_before_member, SUM(menu.price) AS total_spent_before_member
    FROM dannys_diner.sales AS sales
    INNER JOIN dannys_diner.members AS members
    ON sales.customer_id=members.customer_id
    INNER JOIN dannys_diner.menu AS menu
    ON sales.product_id=menu.product_id
    WHERE sales.order_date < members.join_date
    GROUP BY sales.customer_id
    ORDER BY sales.customer_id;


| customer_id | total_orders_before_member | total_spent_before_member |
| ----------- | -------------------------- | ------------------------- |
| A           | 2                          | 25                        |
| B           | 3                          | 40                        |


---




-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


    WITH price_points AS
    (SELECT *,
            CASE WHEN product_id=1 THEN price*20
        ELSE price*10
        END AS points
        FROM dannys_diner.menu)
    SELECT sales.customer_id, SUM(price_points.points)
    FROM price_points
    JOIN dannys_diner.sales AS sales
    ON price_points.product_id= sales.product_id
    GROUP BY sales.customer_id
    ORDER BY sales.customer_id;


| customer_id | sum |
| ----------- | --- |
| A           | 860 |
| B           | 940 |
| C           | 360 |


---



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
**Schema (PostgreSQL v13)**


    WITH bonus AS
    (SELECT *, 
          members.join_date + INTERVAL'6 day' AS valid_date,
              date_trunc('month', join_date) + interval '1 month' - interval '1 day' AS end_of_month
       FROM dannys_diner.members AS members)
    
    SELECT sales.customer_id, 
    SUM(CASE WHEN menu.product_id=1 THEN price*20
            WHEN sales.order_date BETWEEN members.join_date AND bonus.valid_date THEN price*20
       ELSE price*10
       END) AS points
    FROM dannys_diner.sales AS sales
    JOIN bonus
    ON sales.customer_id=bonus.customer_id
    JOIN dannys_diner.menu AS menu
    ON sales.product_id=menu.product_id
    JOIN dannys_diner.members AS members
    ON sales.customer_id=members.customer_id
    GROUP BY sales.customer_id;


| customer_id | points |
| ----------- | ------ |
| A           | 1370   |
| B           | 940    |


---





--Bonus Questions
--Joining all tables:


    SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
    CASE WHEN order_date >= members.join_date THEN 'Y'
    ELSE 'N'
    END AS member
    FROM dannys_diner.sales AS sales
    LEFT JOIN dannys_diner.menu AS menu
    ON sales.product_id=menu.product_id
    LEFT JOIN dannys_diner.members AS members
    ON sales.customer_id=members.customer_id
    ORDER BY sales.customer_id,sales.order_date;


| customer_id | order_date               | product_name | price | member |
| ----------- | ------------------------ | ------------ | ----- | ------ |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |


---




--Ranking member purchases:
    WITH joint AS
    (SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
    CASE WHEN order_date >= members.join_date THEN 'Y'
    ELSE 'N'
    END AS member
    FROM dannys_diner.sales AS sales
    LEFT JOIN dannys_diner.menu AS menu
    ON sales.product_id=menu.product_id
    LEFT JOIN dannys_diner.members AS members
    ON sales.customer_id=members.customer_id
    ORDER BY sales.customer_id,sales.order_date)
    
    SELECT *, 
    CASE WHEN member = 'N' THEN NULL
    ELSE RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
    FROM joint;


| customer_id | order_date               | product_name | price | member | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |         |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      | 1       |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |         |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |         |


---

