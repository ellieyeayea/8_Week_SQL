-- This is my answer for Week 1 SQL Challenge: Danny's Diner by Data with Danny
-- https://8weeksqlchallenge.com/case-study-2/


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
	COUNT(co.pizza_id) as "Times delivered"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> ''
GROUP BY co.pizza_id
ORDER BY co.pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	customer_id,
	SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) as "Meatlovers pizzas ordered",
    SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) as "Vegetarian pizzas ordered"
FROM pizza_runner.customer_orders
GROUP BY customer_id
ORDER BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT 
	COUNT(co.pizza_id) as "Maximum pizzas delivered"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> ''
GROUP BY co.order_id
ORDER BY "Maximum pizzas delivered" DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	co.customer_id,
	SUM(CASE WHEN (co.exclusions <> '' OR co.extras <> '') THEN 1 ELSE 0 END) as "Number of pizzas that has change",
    SUM(CASE WHEN (co.exclusions = '' AND co.extras = '') THEN 1 ELSE 0 END) as "Number of pizzas with no change"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> ''
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
	COUNT(co.pizza_id) as "Pizzas delivered that had exclusions and extras"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> ''
    AND co.exclusions <> ''
	AND co.extras <> '';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
    EXTRACT(HOUR FROM order_time) as "Hour of the day",
    COUNT(pizza_id) as "Number of pizzas ordered"
FROM pizza_runner.customer_orders
GROUP BY "Hour of the day"
ORDER BY "Hour of the day";

-- 10. What was the volume of orders for each day of the week?
SELECT
	EXTRACT(DOW FROM order_time) as "Day of the week",
	TO_CHAR(order_time, 'Day') as "Day",
    COUNT(pizza_id) as "Number of pizzas ordered"
FROM pizza_runner.customer_orders
GROUP BY "Day of the week", "Day"
ORDER BY "Day of the week";
