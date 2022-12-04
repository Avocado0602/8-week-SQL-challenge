-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id,
SUM(price) as total_spending
FROM Sales a
LEFT JOIN Menu b ON (a.product_id = b.product_id)
GROUP BY customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id,
COUNT (DISTINCT order_date) AS date_visited
FROM sales
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id,
product_name
FROM Sales a
JOIN Menu b ON (a.product_id = b.product_id)
GROUP BY customer_id

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH most_purchased_item AS (
  SELECT product_id,
  COUNT (product_id) AS num_purchased
  FROM Sales
  GROUP BY product_id
  ORDER BY num_purchased DESC
  LIMIT 1
)
SELECT * FROM most_purchased_item

-- 5. Which item was the most popular for each customer?
WITH purchase_per_customer AS (
 SELECT customer_id,
 product_id,
 count(product_id) as num_purchased,
 Dense_Rank() OVER (PARTITION BY customer_id ORDER BY count(product_id) DESC) AS rn
 FROM Sales
 GROUP BY customer_id,
 product_id
)
SELECT *
FROM purchase_per_customer
WHERE rn = 1

-- 6. Which item was purchased first by the customer after they became a member?
WITH item_first_purchase AS (
  SELECT *,
  Dense_Rank() OVER (PARTITION BY a.customer_id ORDER BY order_date ASC) AS rn
  FROM Sales a
  LEFT JOIN Members b 
  ON (a.customer_id = b.customer_id)
  WHERE order_date >= join_date
  )
SELECT distinct customer_id,
product_id
FROM item_first_purchase
WHERE rn=1

-- 7. Which item was purchased just before the customer became a member?
  SELECT distinct a.customer_id, 
  product_id
  FROM Sales a
  LEFT JOIN Members b 
  ON (a.customer_id = b.customer_id)
  WHERE order_date < join_date OR join_date IS NULL
  
  -- 8. What is the total items and amount spent for each member before they became a member?
  WITH before_member AS (
    SELECT *
    FROM Sales a
    LEFT JOIN Members b 
    ON (a.customer_id = b.customer_id)
    LEFT JOIN Menu c ON (a.product_id=c.product_id)
    WHERE order_date < join_date OR join_date IS NULL
  )
  SELECT customer_id,
  count(product_id) as num_purchased,
  sum(price) as amount_purchased
  FROM before_member
  GROUP BY customer_id
  
  -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH spending_record AS (
  SELECT customer_id,
  product_name,
  SUM(price) AS total_spending,
  CASE WHEN product_name = "sushi" THEN price*20 ELSE price*10 END AS point
  FROM Sales a
  LEFT JOIN Menu b ON (a.product_id = b.product_id)
  GROUP BY customer_id,
  product_name
 )
SELECT customer_id,
SUM(point) AS total_point
FROM spending_record
GROUP BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH first_week AS(
  SELECT *,
  DATE(join_date,'+6 days') AS end_of_first_week
  FROM Sales a
  LEFT JOIN Menu b ON (a.product_id = b.product_id)
  LEFT JOIN Members c ON (a.customer_id = c.customer_id)
  ),
loyalty_point AS(
  SELECT *,
  CASE WHEN order_date>=join_date AND order_date<=end_of_first_week AND product_name="sushi" THEN price*40
  WHEN order_date>=join_date AND order_date<=end_of_first_week AND product_name!="sushi" THEN price*20
  WHEN product_name="sushi" THEN price*20 ELSE price*10
  END AS accumulated_point
  FROM first_week
  WHERE order_date <= DATE('2021-01-31')
  )
SELECT customer_id,
SUM(accumulated_point) AS total_point
FROM loyalty_point
GROUP BY customer_id
HAVING customer_id = 'A' OR customer_id = 'B'

-- Bonus questions
SELECT a.customer_id,
order_date,
product_name,
price,
CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS member
FROM Sales a
LEFT JOIN Menu b ON (a.product_id = b.product_id)
LEFT JOIN Members c ON (a.customer_id = c.customer_id)

-- Bonus questions
WITH member_table AS (
  SELECT a.customer_id,
  order_date,
  product_name,
  price,
  CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS member
  FROM Sales a
  LEFT JOIN Menu b ON (a.product_id = b.product_id)
  LEFT JOIN Members c ON (a.customer_id = c.customer_id)
 ),
rank_member_table AS(
 SELECT *,
 Dense_Rank() OVER (PARTITION BY customer_id, member ORDER BY order_date) AS rn
 FROM member_table
)
SELECT customer_id,
order_date,
product_name,
price,
member,
CASE WHEN member = 'N' THEN 'NULL' ELSE rn END AS rn
FROM rank_member_table






 
  


  



