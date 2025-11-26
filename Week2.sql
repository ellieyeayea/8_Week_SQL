-- Data cleansing
-- Remove null values from customer_orders table
UPDATE customer_orders
SET exclusions = ''
WHERE (exclusions IS NULL or exclusions = 'null');

UPDATE customer_orders
SET extras = ''
WHERE (extras IS NULL or extras = 'null');

-- Clean inconsistent data from runner_orders table
UPDATE runner_orders
SET distance = REGEXP_REPLACE(distance, '\s*[[:alpha:]]', '', 'g'),
duration = REGEXP_REPLACE(duration, '\s*[[:alpha:]]', '', 'g');

-- Remove null values from runner_orders table
UPDATE runner_orders
SET pickup_time = ''
WHERE (pickup_time IS NULL or pickup_time = 'null');

UPDATE runner_orders
SET cancellation = ''
WHERE (cancellation IS NULL or cancellation = 'null');



-- SQL Queries
-- Part A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT 
	COUNT(*) as "Number of pizzas ordered"
FROM pizza_runner.customer_orders;

-- 2. How many unique customer orders were made?
SELECT 
	COUNT(d.*) as "Unique customer orders"
FROM (SELECT DISTINCT * FROM pizza_runner.customer_orders) d;

-- 3. How many successful orders were delivered by each runner?
SELECT 
	ro.runner_id,
	COUNT (ro.*) as "Successful orders delivered"
FROM pizza_runner.runner_orders ro
WHERE ro.pickup_time <> ''
GROUP BY (ro.runner_id)
ORDER BY ro.runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT 
	co.pizza_id,
	COUNT(co.pizza_id)
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> ''
GROUP BY co.pizza_id
ORDER BY co.pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT DISTINCT
	co.customer_id,
    pn.pizza_name,
    COUNT(co.pizza_id)
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.pizza_names pn
    	ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
ORDER BY co.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- 8. How many pizzas were delivered that had both exclusions and extras?
-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- 10. What was the volume of orders for each day of the week?


-- select * from runner_orders order by order_id;
-- select * from customer_orders;

