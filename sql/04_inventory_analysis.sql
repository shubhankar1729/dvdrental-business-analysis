-- ==========================================================
-- Business Question 1: Inventory Count by Film
-- Purpose:
-- Determine how many copies of each film are available in
-- inventory. This helps identify movies with high or low
-- stock levels across all stores.
-- ==========================================================

SELECT
    f.film_id,
    f.title AS film_title,
    COUNT(i.inventory_id) AS total_inventory_copies
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
GROUP BY
    f.film_id,
    f.title
ORDER BY
    total_inventory_copies DESC;

-- ==========================================================
-- Business Question 2: Films with the Highest Inventory
-- Purpose:
-- Identify movies with the highest number of inventory
-- copies. These movies occupy the most storage space and
-- represent the largest inventory investment.
-- ==========================================================

SELECT
    f.film_id,
    f.title AS film_title,
    COUNT(i.inventory_id) AS total_inventory_copies
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
GROUP BY
    f.film_id,
    f.title
ORDER BY
    total_inventory_copies DESC
LIMIT 10;

-- ==========================================================
-- Business Question 3: Films with the Lowest Inventory
-- Purpose:
-- Identify movies with the fewest inventory copies. These
-- films may require additional copies if demand increases.
-- ==========================================================

SELECT
    f.film_id,
    f.title AS film_title,
    COUNT(i.inventory_id) AS total_inventory_copies
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
GROUP BY
    f.film_id,
    f.title
ORDER BY
    total_inventory_copies ASC,
    film_title
LIMIT 10;

-- ==========================================================
-- Business Question 4: Inventory Distribution by Store
-- Purpose:
-- Analyze how inventory is distributed between stores.
-- This helps management evaluate stock allocation.
-- ==========================================================

SELECT
    s.store_id,
    COUNT(i.inventory_id) AS total_inventory,
    COUNT(DISTINCT i.film_id) AS unique_films
FROM store s
JOIN inventory i
    ON s.store_id = i.store_id
GROUP BY
    s.store_id
ORDER BY
    total_inventory DESC;

-- ==========================================================
-- Business Question 5: Available vs Rented Inventory
-- Purpose:
-- Determine how many inventory items are currently available
-- and how many are currently rented out. This helps monitor
-- inventory utilization.
-- ==========================================================

SELECT
    CASE
        WHEN r.return_date IS NULL THEN 'Currently Rented'
        ELSE 'Available'
    END AS inventory_status,
    COUNT(*) AS total_inventory_items
FROM inventory i
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id
    AND r.rental_date = (
        SELECT MAX(r2.rental_date)
        FROM rental r2
        WHERE r2.inventory_id = i.inventory_id
    )
GROUP BY
    inventory_status
ORDER BY
    total_inventory_items DESC;

-- ==========================================================
-- Business Question 6: Inventory Utilization Rate
-- Purpose:
-- Calculate the rental frequency of each inventory item.
-- This helps identify inventory copies that are highly
-- utilized and those that remain underutilized.
-- ==========================================================

SELECT
    i.inventory_id,
    f.film_id,
    f.title AS film_title,
    COUNT(r.rental_id) AS total_rentals
FROM inventory i
JOIN film f
    ON i.film_id = f.film_id
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id
GROUP BY
    i.inventory_id,
    f.film_id,
    f.title
ORDER BY
    total_rentals DESC;

-- ==========================================================
-- Business Question 7: Most Frequently Rented Inventory Items
-- Purpose:
-- Identify the inventory copies that have been rented the
-- most. These copies experience the highest demand.
-- ==========================================================

SELECT
    i.inventory_id,
    f.film_id,
    f.title AS film_title,
    COUNT(r.rental_id) AS total_rentals
FROM inventory i
JOIN film f
    ON i.film_id = f.film_id
JOIN rental r
    ON i.inventory_id = r.inventory_id
GROUP BY
    i.inventory_id,
    f.film_id,
    f.title
ORDER BY
    total_rentals DESC
LIMIT 10;

-- ==========================================================
-- Business Question 8: Least Frequently Rented Inventory Items
-- Purpose:
-- Identify inventory copies that have been rented the least.
-- These items may be overstocked or have low demand.
-- ==========================================================

SELECT
    i.inventory_id,
    f.film_id,
    f.title AS film_title,
    COUNT(r.rental_id) AS total_rentals
FROM inventory i
JOIN film f
    ON i.film_id = f.film_id
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id
GROUP BY
    i.inventory_id,
    f.film_id,
    f.title
ORDER BY
    total_rentals ASC,
    film_title
LIMIT 10;

-- ==========================================================
-- Business Question 9: Inventory by Category
-- Purpose:
-- Analyze inventory distribution across movie categories.
-- This helps determine whether stock levels are balanced
-- among different genres.
-- ==========================================================

SELECT
    c.category_id,
    c.name AS category_name,
    COUNT(i.inventory_id) AS total_inventory
FROM inventory i
JOIN film_category fc
    ON i.film_id = fc.film_id
JOIN category c
    ON fc.category_id = c.category_id
GROUP BY
    c.category_id,
    c.name
ORDER BY
    total_inventory DESC;

-- ==========================================================
-- Business Question 10: Average Inventory per Film by Category
-- Purpose:
-- Calculate the average number of inventory copies available
-- for films in each category. This helps compare stocking
-- strategies across genres.
-- ==========================================================

WITH film_inventory AS (
    SELECT
        fc.category_id,
        c.name AS category_name,
        f.film_id,
        COUNT(i.inventory_id) AS inventory_count
    FROM film f
    JOIN inventory i
        ON f.film_id = i.film_id
    JOIN film_category fc
        ON f.film_id = fc.film_id
    JOIN category c
        ON fc.category_id = c.category_id
    GROUP BY
        fc.category_id,
        c.name,
        f.film_id
)

SELECT
    category_id,
    category_name,
    ROUND(AVG(inventory_count), 2) AS average_inventory_per_film
FROM film_inventory
GROUP BY
    category_id,
    category_name
ORDER BY
    average_inventory_per_film DESC;

-- ==========================================================
-- Business Question 11: Inventory Distribution by Film Rating
-- Purpose:
-- Analyze inventory allocation based on movie ratings.
-- This helps determine whether stock levels are aligned
-- with audience classifications.
-- ==========================================================

SELECT
    f.rating,
    COUNT(i.inventory_id) AS total_inventory,
    COUNT(DISTINCT f.film_id) AS total_films,
    ROUND(
        COUNT(i.inventory_id)::numeric /
        COUNT(DISTINCT f.film_id),
        2
    ) AS average_inventory_per_film
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
GROUP BY
    f.rating
ORDER BY
    total_inventory DESC;

-- ==========================================================
-- Business Question 12: Inventory Investment by Replacement Cost
-- Purpose:
-- Calculate the inventory investment for each film using
-- replacement cost. This helps estimate the monetary value
-- of inventory assets.
-- ==========================================================

SELECT
    f.film_id,
    f.title,
    COUNT(i.inventory_id) AS inventory_copies,
    f.replacement_cost,
    ROUND(
        COUNT(i.inventory_id) * f.replacement_cost,
        2
    ) AS total_inventory_value
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
GROUP BY
    f.film_id,
    f.title,
    f.replacement_cost
ORDER BY
    total_inventory_value DESC;

-- ==========================================================
-- Business Question 13: Inventory Turnover Analysis
-- Purpose:
-- Measure how efficiently inventory is utilized by comparing
-- rental activity with available inventory.
-- ==========================================================

SELECT
    f.film_id,
    f.title,
    COUNT(DISTINCT i.inventory_id) AS inventory_copies,
    COUNT(r.rental_id) AS total_rentals,
    ROUND(
        COUNT(r.rental_id)::numeric /
        COUNT(DISTINCT i.inventory_id),
        2
    ) AS turnover_rate
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id
GROUP BY
    f.film_id,
    f.title
ORDER BY
    turnover_rate DESC;

-- ==========================================================
-- Business Question 14: Inventory Health Report
-- Purpose:
-- Classify inventory based on rental demand to identify
-- high-performing and underperforming movies.
-- ==========================================================

SELECT
    f.film_id,
    f.title,
    COUNT(r.rental_id) AS total_rentals,
    CASE
        WHEN COUNT(r.rental_id) >= 35 THEN 'High Demand'
        WHEN COUNT(r.rental_id) >= 20 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS inventory_health
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id
GROUP BY
    f.film_id,
    f.title
ORDER BY
    total_rentals DESC;

-- ==========================================================
-- Business Question 15: Inventory Performance Dashboard
-- Purpose:
-- Create a comprehensive inventory performance report by
-- combining inventory size, rental demand, utilization,
-- and inventory investment into a single business view.
-- ==========================================================

SELECT
    f.film_id,
    f.title,
    COUNT(DISTINCT i.inventory_id) AS inventory_copies,
    COUNT(r.rental_id) AS total_rentals,
    ROUND(
        COUNT(r.rental_id)::numeric /
        COUNT(DISTINCT i.inventory_id),
        2
    ) AS turnover_rate,
    ROUND(
        COUNT(DISTINCT i.inventory_id) * f.replacement_cost,
        2
    ) AS inventory_value,
    CASE
        WHEN COUNT(r.rental_id)::numeric /
             COUNT(DISTINCT i.inventory_id) >= 8
        THEN 'Excellent'

        WHEN COUNT(r.rental_id)::numeric /
             COUNT(DISTINCT i.inventory_id) >= 5
        THEN 'Good'

        ELSE 'Needs Attention'
    END AS inventory_status
FROM film f
JOIN inventory i
    ON f.film_id = i.film_id
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id
GROUP BY
    f.film_id,
    f.title,
    f.replacement_cost
ORDER BY
    turnover_rate DESC,
    inventory_value DESC;