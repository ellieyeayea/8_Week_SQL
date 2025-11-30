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


-- Part B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
	(DATE_TRUNC('Week', registration_date::TIMESTAMP) + INTERVAL '4 days')::DATE as "Week start",
    COUNT(*) as "Runners signed up"
FROM pizza_runner.runners
GROUP BY "Week start"
ORDER BY "Week start";

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
    AVG(EXTRACT(EPOCH FROM (ro.pickup_time::TIMESTAMP - co.order_time::TIMESTAMP))) / 60 as "Average runner arrival time (minutes)"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> '';

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT DISTINCT
	co.order_id,
	COUNT(co.pizza_id)OVER(PARTITION BY co.order_id) as "Pizza prepared for order",
    EXTRACT(EPOCH FROM (ro.pickup_time::TIMESTAMP - co.order_time::TIMESTAMP))/60 as "Time to prepare order (minutes)"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> ''
ORDER BY co.order_id;

-- 4. What was the average distance travelled for each customer?
SELECT
	co.customer_id,
	ROUND(AVG(ro.distance::NUMERIC), 2) as "Average distance travelled (km)"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.distance <> ''
GROUP BY co.customer_id
ORDER BY co.customer_id;
        
-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
	MAX(duration)::NUMERIC - MIN(duration)::NUMERIC as "Difference between longest and shortest delivery time (minutes)"
FROM pizza_runner.runner_orders
WHERE duration <> '';

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	runner_id,
	AVG(duration::NUMERIC) as "Average delivery speed (minutes)"
FROM pizza_runner.runner_orders
WHERE duration <> ''
GROUP BY runner_id
ORDER BY runner_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT DISTINCT 
	runner_id,
	COUNT(order_id)OVER(PARTITION BY runner_id) as "All orders",
    SUM(CASE WHEN duration <> '' THEN 1 ELSE 0 END)OVER(PARTITION BY runner_id) as "Successful delivery",
    (SUM(CASE WHEN duration <> '' THEN 1 ELSE 0 END)OVER(PARTITION BY runner_id)::FLOAT / COUNT(order_id)OVER(PARTITION BY runner_id)::FLOAT)*100 || '%' as "Successful delivery percentage"
FROM 
	pizza_runner.runner_orders
ORDER BY runner_id;

-- Part C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?
SELECT
    pn.pizza_name,
    STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) as "Standard ingredients"
FROM pizza_runner.pizza_names pn
	JOIN (SELECT 
              pizza_id,
              REGEXP_SPLIT_TO_TABLE(toppings, ', ') as top
          FROM pizza_runner.pizza_recipes) pr
          ON pn.pizza_id = pr.pizza_id
    JOIN pizza_runner.pizza_toppings pt
    	ON pr.top::INT = pt.topping_id
GROUP BY pn.pizza_name;

-- 2. What was the most commonly added extra?
SELECT 
	pt.topping_name as "Most commonly added extra",
	COUNT(ex.e) as "Times added" 
FROM (SELECT 
      	order_id,
      	REGEXP_SPLIT_TO_TABLE(extras, ', ') as e
      FROM pizza_runner.customer_orders
      WHERE extras <> '') ex
      JOIN pizza_runner.pizza_toppings pt
      			ON ex.e::INT = pt.topping_id
GROUP BY topping_name
ORDER BY "Times added" DESC
LIMIT 1;


-- 3. What was the most common exclusion?
SELECT 
	pt.topping_name as "Most common exclusion",
	COUNT(ex.e) as "Times excluded"
FROM
	(SELECT 
      	order_id,
      	REGEXP_SPLIT_TO_TABLE(exclusions, ', ') as e
      FROM pizza_runner.customer_orders
      WHERE exclusions <> '') ex
    JOIN pizza_runner.pizza_toppings pt
      	ON ex.e::INT = pt.topping_id
GROUP BY topping_name
ORDER BY "Times excluded" DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--         Meat Lovers
--         Meat Lovers - Exclude Beef
--         Meat Lovers - Extra Bacon
--         Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
With nco as (SELECT 
             	ROW_NUMBER()OVER() as rn, *
			 FROM pizza_runner.customer_orders)

SELECT
	nco.rn,
	nco.order_id,
    nco.pizza_id,
    pn.pizza_name || 
    	CASE WHEN excl.rn IS NOT NULL THEN ' - Exclude ' || excl.exclude ELSE '' END || 	
    	CASE WHEN extra.rn IS NOT NULL THEN ' - Extra ' || extra.extra ELSE '' END as "Order item"
FROM nco
	JOIN pizza_runner.pizza_names pn
    	ON nco.pizza_id = pn.pizza_id
    LEFT JOIN (SELECT 
                    ext.rn,
                    STRING_AGG(ptext.topping_name, ', ' ORDER BY ptext.topping_name) as "extra"
                FROM (SELECT
                          rn,
                          REGEXP_SPLIT_TO_TABLE(extras, ', ') as e
                      FROM nco
                      WHERE extras <> '') ext
                     JOIN pizza_runner.pizza_toppings ptext
                        ON ext.e::INT = ptext.topping_id
              		  GROUP BY ext.rn) extra
          ON nco.rn = extra.rn
    LEFT JOIN (SELECT 
                    ex.rn,
                    STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) as "exclude"
                FROM (SELECT
                          rn,
                          REGEXP_SPLIT_TO_TABLE(exclusions, ', ') as e
                      FROM nco
                      WHERE exclusions <> '') ex
                     JOIN pizza_runner.pizza_toppings pt
                        ON ex.e::INT = pt.topping_id
              		  GROUP BY ex.rn) excl
          ON nco.rn = excl.rn
ORDER BY nco.order_id, nco.pizza_id;
            

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--         For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
With nco as (SELECT 
             	ROW_NUMBER()OVER() as rn, *
			 FROM pizza_runner.customer_orders)
     ,pi as (SELECT 
                nco.rn, nco.order_id, nco.pizza_id, 
                REGEXP_SPLIT_TO_TABLE(pr.toppings || CASE WHEN nco.extras <> '' THEN ', ' || nco.extras ELSE '' END, ', ') as top
            FROM nco
                JOIN pizza_runner.pizza_recipes pr
                    ON nco.pizza_id = pr.pizza_id)
     ,ft as (SELECT pi.rn, pi.top, COUNT(pi.top) as cnt
                FROM pi
                LEFT JOIN (SELECT rn, REGEXP_SPLIT_TO_TABLE(exclusions, ', ') as ex
                                  FROM nco
                                  WHERE exclusions <> '') exc
                     ON pi.rn = exc.rn
                     AND pi.top = exc.ex
            WHERE exc.rn is null
            GROUP BY pi.rn, pi.top)
SELECT
	nco.rn, nco.order_id, nco.pizza_id,
    pn.pizza_name || ': ' || STRING_AGG(CASE WHEN ft.cnt > 1 THEN ft.cnt||'x'||pt.topping_name 
                                        ELSE pt.topping_name END, ', ' ORDER BY pt.topping_name) as "Pizza ingredients list"
FROM nco
	JOIN pizza_runner.pizza_names pn
    	ON nco.pizza_id = pn.pizza_id
    JOIN ft
    	ON nco.rn = ft.rn
    JOIN pizza_runner.pizza_toppings pt
    	ON ft.top::INT = pt.topping_id
GROUP BY nco.rn, nco.order_id, nco.pizza_id, pn.pizza_name
ORDER BY nco.order_id, nco.pizza_id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
With nco as (SELECT 
             	ROW_NUMBER()OVER() as rn, co.*
			 FROM pizza_runner.customer_orders co
             JOIN pizza_runner.runner_orders ro
                  ON co.order_id = ro.order_id
             WHERE ro.pickup_time <> '')
     ,pi as (SELECT 
                nco.rn, nco.order_id, nco.pizza_id, 
                REGEXP_SPLIT_TO_TABLE(pr.toppings || CASE WHEN nco.extras <> '' THEN ', ' || nco.extras ELSE '' END, ', ') as top
            FROM nco
                JOIN pizza_runner.pizza_recipes pr
                    ON nco.pizza_id = pr.pizza_id)
SELECT pt.topping_name, COUNT(pi.top) as "Total used" 
FROM pi
	JOIN pizza_toppings pt
    	ON pi.top::INT = pt.topping_id
	LEFT JOIN (SELECT rn, REGEXP_SPLIT_TO_TABLE(exclusions, ', ') as ex
               FROM nco
               WHERE exclusions <> '') exc
        ON pi.rn = exc.rn
        AND pi.top = exc.ex
WHERE exc.rn is null
GROUP BY pt.topping_name
ORDER BY "Total used" DESC;

-- Part D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT
	SUM(CASE WHEN co.pizza_id = 1 THEN 12 
        ELSE 10 END) as "Total money made"
FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
    	ON co.order_id = ro.order_id
WHERE ro.pickup_time <> '';

-- 2. What if there was an additional $1 charge for any pizza extras?
--    Add cheese is $1 extra
-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
        -- customer_id
        -- order_id
        -- runner_id
        -- rating
        -- order_time
        -- pickup_time
        -- Time between order and pickup
        -- Delivery duration
        -- Average speed
        -- Total number of pizzas
-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?