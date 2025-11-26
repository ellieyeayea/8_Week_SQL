-- This is my answer for Week 1 SQL Challenge: Danny's Diner by Data with Danny
-- https://8weeksqlchallenge.com/case-study-1/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id,
    SUM(m.price)
FROM
	dannys_diner.sales as s
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
GROUP BY s.customer_id;


-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id,
	COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT ON (s.customer_id) 
	s.customer_id,
    s.order_date,
    m.product_name
FROM dannys_diner.sales as s
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
ORDER BY s.customer_id, s.order_date;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT DISTINCT
	s.product_id,
    m.product_name,
    COUNT(s.order_date)OVER(PARTITION BY s.product_id) as cnt
FROM dannys_diner.sales as s 
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
ORDER BY cnt DESC
LIMIT 1;
    
    
-- 5. Which item was the most popular for each customer?
SELECT DISTINCT ON (s.customer_id)
	s.customer_id,
    s.product_id,
    COUNT(s.order_date)OVER(PARTITION BY s.customer_id, s.product_id) as cnt,
    m.product_name
FROM dannys_diner.sales as s
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
ORDER BY s.customer_id, cnt DESC;


-- 6. Which item was purchased first by the customer after they became a member? 	
SELECT DISTINCT ON (s.customer_id)
	s.customer_id,
	s.order_date,
    m.product_name
FROM 
	dannys_diner.sales as s
    JOIN dannys_diner.members as mb
    	ON s.customer_id = mb.customer_id
    JOIN dannys_diner.menu as m 
    	ON s.product_id = m.product_id
WHERE s.order_date >= mb.join_date;


-- 7. Which item was purchased just before the customer became a member?
SELECT DISTINCT ON (s.customer_id)
	s.customer_id,
	s.order_date,
    m.product_name
FROM 
	dannys_diner.sales as s
    JOIN dannys_diner.members as mb
    	ON s.customer_id = mb.customer_id
    JOIN dannys_diner.menu as m 
    	ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
	s.customer_id,
    COUNT(s.product_id),
    SUM(m.price)
FROM 
	dannys_diner.sales as s
    JOIN dannys_diner.members as mb
    	ON s.customer_id = mb.customer_id
    JOIN dannys_diner.menu as m 
    	ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
	s.customer_id,
    SUM(
      	CASE WHEN m.product_name = 'sushi' THEN m.price*10*2
      	ELSE m.price*10
      	END
       ) as points
FROM dannys_diner.sales as s
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
GROUP BY s.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
	s.customer_id,
    SUM(
      	CASE WHEN (s.order_date BETWEEN mb.join_date AND mb.join_date + 7) THEN m.price*10*2
      	WHEN (s.order_date NOT BETWEEN mb.join_date AND mb.join_date + 7) AND m.product_name = 'sushi' THEN m.price*10*2
      	ELSE m.price*10
      	END
       ) as points
FROM dannys_diner.sales as s
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
    JOIN dannys_diner.members as mb
    	ON s.customer_id = mb.customer_id
WHERE EXTRACT(MONTH from s.order_date) = 1
GROUP BY s.customer_id;


-- Bonus question: Join All The Things
CREATE VIEW All_data AS
SELECT
	s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE WHEN s.order_date >= mb.join_date THEN 'Y'
    	ELSE 'N'
    END as member

FROM dannys_diner.sales as s
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
    LEFT JOIN dannys_diner.members as mb
    	ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;

Select * from All_data;


-- Bonus question: Rank All The Things
CREATE VIEW Member_rank AS
SELECT
	s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE WHEN s.order_date >= mb.join_date THEN 'Y'
    	ELSE 'N'
    END as member,
	COALESCE(r.ranking, null) as ranking
FROM dannys_diner.sales as s
	JOIN dannys_diner.menu as m
    	ON s.product_id = m.product_id
    LEFT JOIN dannys_diner.members as mb
    	ON s.customer_id = mb.customer_id
    LEFT JOIN (SELECT DISTINCT
                s.customer_id,
                s.order_date,
                RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as ranking
            FROM dannys_diner.sales as s
                 JOIN dannys_diner.members as mb
                    ON s.customer_id = mb.customer_id
            WHERE s.order_date >= mb.join_date) as r
         ON s.customer_id = r.customer_id
         AND s.order_date = r.order_date
ORDER BY s.customer_id, s.order_date;

Select * from Member_rank;
