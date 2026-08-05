-- ==========================================================
-- Business Question 1: Customer Lifetime Value (CLV)
-- Purpose:
-- Calculate the lifetime value of each customer based on
-- the total revenue they have generated. This helps identify
-- the most valuable customers for loyalty programs and
-- customer retention strategies.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    ROUND(SUM(p.amount), 2) AS lifetime_value,
    COUNT(p.payment_id) AS total_payments,
    ROUND(AVG(p.amount), 2) AS average_payment_amount
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    lifetime_value DESC
LIMIT 10;

-- ==========================================================
-- Business Question 2: Customer Rental Frequency
-- Purpose:
-- Analyze how frequently each customer rents movies by
-- calculating their total rentals, total revenue, and
-- average revenue generated per rental.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals,
    ROUND(SUM(p.amount), 2) AS total_revenue,
    ROUND(SUM(p.amount) / COUNT(r.rental_id), 2) AS average_revenue_per_rental
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
JOIN rental r
    ON p.rental_id = r.rental_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_rentals DESC
LIMIT 10;

-- ==========================================================
-- Business Question 3: Customer Rental Recency
-- Purpose:
-- Identify customers based on how recently they rented
-- a movie. This helps the business target inactive
-- customers for re-engagement campaigns.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(DATE(r.rental_date)) AS last_rental_date,
    (
        (SELECT MAX(DATE(rental_date)) FROM rental)
        - MAX(DATE(r.rental_date))
    ) AS days_since_last_rental
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    days_since_last_rental DESC;

-- ==========================================================
-- Business Question 4: Customer Rental Duration Analysis
-- Purpose:
-- Analyze the rental duration behavior of customers by
-- calculating their average, maximum, and minimum rental
-- durations. This helps understand customer rental habits.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals,
    ROUND(AVG(DATE(r.return_date) - DATE(r.rental_date)), 2) AS average_rental_duration,
    MAX(DATE(r.return_date) - DATE(r.rental_date)) AS maximum_rental_duration,
    MIN(DATE(r.return_date) - DATE(r.rental_date)) AS minimum_rental_duration
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
WHERE r.return_date IS NOT NULL
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    average_rental_duration DESC;

-- ==========================================================
-- Business Question 5: Customer Spending Segmentation
-- Purpose:
-- Segment customers into spending categories based on
-- their lifetime revenue. This helps the marketing team
-- design targeted loyalty and retention programs.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    ROUND(SUM(p.amount), 2) AS lifetime_value,
    CASE
        WHEN SUM(p.amount) >= 200 THEN 'Platinum'
        WHEN SUM(p.amount) >= 150 THEN 'Gold'
        WHEN SUM(p.amount) >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_segment
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    lifetime_value DESC;

-- ==========================================================
-- Business Question 6: High-Value Repeat Customers
-- Purpose:
-- Identify customers who frequently rent movies while
-- generating high lifetime revenue. This helps the
-- business recognize loyal and profitable customers.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals,
    ROUND(SUM(p.amount), 2) AS lifetime_value,
    CASE
        WHEN SUM(p.amount) >= 200 THEN 'Platinum'
        WHEN SUM(p.amount) >= 150 THEN 'Gold'
        WHEN SUM(p.amount) >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_segment
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
JOIN rental r
    ON p.rental_id = r.rental_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_rentals DESC,
    lifetime_value DESC;

-- ==========================================================
-- Business Question 7: Customer Rental Category Preference
-- Purpose:
-- Identify each customer's favorite movie category based
-- on the number of rentals. This helps the marketing team
-- understand customer preferences and provide personalized
-- recommendations.
-- ==========================================================

WITH customer_category AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        ct.name AS favorite_category,
        COUNT(r.rental_id) AS total_rentals,
        DENSE_RANK() OVER (
            PARTITION BY c.customer_id
            ORDER BY COUNT(r.rental_id) DESC
        ) AS category_rank
    FROM customer c
    JOIN rental r
        ON c.customer_id = r.customer_id
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
    JOIN film_category fc
        ON i.film_id = fc.film_id
    JOIN category ct
        ON fc.category_id = ct.category_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        ct.name
)

SELECT
    customer_id,
    first_name,
    last_name,
    favorite_category,
    total_rentals
FROM customer_category
WHERE category_rank = 1
ORDER BY
    customer_id,
    favorite_category;


-- ==========================================================
-- Business Question 8: Customers Who Rented the Most Unique Movies
-- Purpose:
-- Identify customers with the most diverse movie-watching
-- behavior by calculating the percentage of unique movies
-- they have rented. This helps understand customer
-- engagement and content diversity preferences.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals,
    COUNT(DISTINCT i.film_id) AS total_unique_movies,
    ROUND(
        COUNT(DISTINCT i.film_id) * 100.0 /
        COUNT(r.rental_id),
        2
    ) AS diversity_percentage
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
JOIN inventory i
    ON r.inventory_id = i.inventory_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    diversity_percentage DESC,
    total_unique_movies DESC;

-- ==========================================================
-- Business Question 9: Preferred Rental Day
-- Purpose:
-- Identify each customer's preferred rental day based on
-- the number of movies rented. This helps the marketing
-- team schedule promotions on customers' favorite days.
-- ==========================================================

WITH customer_rental_day AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        CASE
            WHEN EXTRACT(DOW FROM r.rental_date) = 0 THEN 'Sunday'
            WHEN EXTRACT(DOW FROM r.rental_date) = 1 THEN 'Monday'
            WHEN EXTRACT(DOW FROM r.rental_date) = 2 THEN 'Tuesday'
            WHEN EXTRACT(DOW FROM r.rental_date) = 3 THEN 'Wednesday'
            WHEN EXTRACT(DOW FROM r.rental_date) = 4 THEN 'Thursday'
            WHEN EXTRACT(DOW FROM r.rental_date) = 5 THEN 'Friday'
            ELSE 'Saturday'
        END AS preferred_rental_day,
        COUNT(r.rental_id) AS total_rentals,
        DENSE_RANK() OVER (
            PARTITION BY c.customer_id
            ORDER BY COUNT(r.rental_id) DESC
        ) AS rental_day_rank
    FROM customer c
    JOIN rental r
        ON c.customer_id = r.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        EXTRACT(DOW FROM r.rental_date)
)

SELECT
    customer_id,
    first_name,
    last_name,
    preferred_rental_day,
    total_rentals
FROM customer_rental_day
WHERE rental_day_rank = 1
ORDER BY
    customer_id,
    preferred_rental_day;

-- ==========================================================
-- Business Question 10: Most Frequently Rented Actor by Customer
-- Purpose:
-- Identify each customer's favorite actor based on the
-- number of rentals. This helps build personalized movie
-- recommendation systems.
-- ==========================================================

WITH customer_actor_preference AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        a.actor_id,
        a.first_name || ' ' || a.last_name AS favorite_actor,
        COUNT(r.rental_id) AS total_rentals,
        DENSE_RANK() OVER (
            PARTITION BY c.customer_id
            ORDER BY COUNT(r.rental_id) DESC
        ) AS actor_rank
    FROM customer c
    JOIN rental r
        ON c.customer_id = r.customer_id
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
    JOIN film_actor fa
        ON i.film_id = fa.film_id
    JOIN actor a
        ON fa.actor_id = a.actor_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        a.actor_id,
        a.first_name,
        a.last_name
)

SELECT
    customer_id,
    first_name,
    last_name,
    favorite_actor,
    total_rentals
FROM customer_actor_preference
WHERE actor_rank = 1
ORDER BY
    customer_id,
    favorite_actor;

-- ==========================================================
-- Business Question 11: Customer Genre Diversity Score
-- Purpose:
-- Measure how diverse each customer's movie preferences are
-- by calculating the number of unique genres they have
-- watched. This helps identify customers with broad
-- entertainment interests.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals,
    COUNT(DISTINCT ct.category_id) AS total_genres_watched,
    ROUND(
        COUNT(DISTINCT ct.category_id) * 100.0 /
        COUNT(r.rental_id),
        2
    ) AS genre_diversity_score
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
JOIN inventory i
    ON r.inventory_id = i.inventory_id
JOIN film_category fc
    ON i.film_id = fc.film_id
JOIN category ct
    ON fc.category_id = ct.category_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    genre_diversity_score DESC,
    total_genres_watched DESC;

-- ==========================================================
-- Business Question 12: Customer Loyalty Classification
-- Purpose:
-- Classify customers into loyalty tiers based on the total
-- number of rentals they have made. This helps identify
-- highly engaged customers for loyalty and reward programs.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals,
    CASE
        WHEN COUNT(r.rental_id) >= 40 THEN 'Platinum'
        WHEN COUNT(r.rental_id) >= 30 THEN 'Gold'
        WHEN COUNT(r.rental_id) >= 20 THEN 'Silver'
        ELSE 'Bronze'
    END AS loyalty_tier
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_rentals DESC;

-- ==========================================================
-- Business Question 13: High-Value Customers by Store
-- Purpose:
-- Identify the top 5 highest-value customers in each store
-- based on their lifetime revenue. This helps store managers
-- recognize and reward their most valuable customers.
-- ==========================================================

WITH customer_revenue AS (
    SELECT
        s.store_id,
        c.customer_id,
        c.first_name,
        c.last_name,
        ROUND(SUM(p.amount), 2) AS lifetime_value,
        DENSE_RANK() OVER (
            PARTITION BY s.store_id
            ORDER BY SUM(p.amount) DESC
        ) AS store_rank
    FROM customer c
    JOIN store s
        ON c.store_id = s.store_id
    JOIN payment p
        ON c.customer_id = p.customer_id
    GROUP BY
        s.store_id,
        c.customer_id,
        c.first_name,
        c.last_name
)

SELECT
    store_id,
    customer_id,
    first_name,
    last_name,
    lifetime_value,
    store_rank
FROM customer_revenue
WHERE store_rank <= 5
ORDER BY
    store_id,
    store_rank,
    lifetime_value DESC;

-- ==========================================================
-- Business Question 14: Customer Payment Consistency
-- Purpose:
-- Measure how consistently customers make payments by
-- analyzing their payment statistics. Customers with a
-- smaller payment range tend to have more consistent
-- purchasing behavior.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(p.payment_id) AS total_payments,
    ROUND(AVG(p.amount), 2) AS average_payment_amount,
    ROUND(MIN(p.amount), 2) AS minimum_payment,
    ROUND(MAX(p.amount), 2) AS maximum_payment,
    ROUND(MAX(p.amount) - MIN(p.amount), 2) AS payment_range
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    payment_range ASC,
    total_payments DESC;

-- ==========================================================
-- Business Question 15: Customer Revenue Contribution
-- Purpose:
-- Calculate the percentage contribution of each customer
-- to the company's total revenue. This helps identify
-- the customers who generate the highest share of revenue.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    ROUND(SUM(p.amount), 2) AS lifetime_revenue,
    ROUND(
        SUM(p.amount) * 100.0 /
        (SELECT SUM(amount) FROM payment),
        2
    ) AS revenue_contribution_percentage
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    revenue_contribution_percentage DESC;

