/*
==========================================================
Project : DVD Rental Business Analysis
File    : 01_customer_analysis.sql

Objective:
Analyze customer behavior to answer key business questions:
1. How many customers are there?
2. Who are the most valuable customers?
3. Who rents most frequently?
4. Who has become inactive?
5. Which cities and countries have the highest-value customers?

Author : Shubhankar
Database : PostgreSQL - dvdrental
==========================================================
*/

-- ==========================================================
-- Business Question 1: How many customers are registered?
-- Purpose:
-- Determine the total customer base of the business.
-- ==========================================================

SELECT COUNT(*) AS total_customers
FROM customer;


-- ==========================================================
-- Business Question 2: Top 10 customers by total amount spent
-- Purpose:
-- Identify the highest-value customers for loyalty programs
-- and targeted marketing campaigns.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC
LIMIT 10;


-- ==========================================================
-- Business Question 3: Who rented the most movies?
-- Purpose:
-- Identify customers with the highest rental activity.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals
FROM customer c
JOIN rental r
    ON r.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_rentals DESC
LIMIT 10;

-- ==========================================================
-- Business Question 4: Customers who spent above average
-- Purpose:
-- Identify customers whose total spending is greater than
-- the average spending across all customers.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING SUM(p.amount) >
(
    SELECT AVG(total_spent)
    FROM
    (
        SELECT
            customer_id,
            SUM(amount) AS total_spent
        FROM payment
        GROUP BY customer_id
    ) AS customer_totals
)
ORDER BY total_spent DESC;


-- ==========================================================
-- Business Question 5: Which customers have never made a payment?
-- Purpose:
-- Identify customers who have no payment records.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name
FROM customer c
LEFT JOIN payment p
    ON c.customer_id = p.customer_id
WHERE p.payment_id IS NULL;

-- Note:
-- In the dvdrental dataset, this query returns 0 rows
-- because every customer has at least one payment.

-- ==========================================================
-- Business Question 6: Top 10 customers by average payment amount
-- Purpose:
-- Identify customers who tend to make higher-value payments.
-- This helps the business understand which customers
-- consistently make larger payments per transaction.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    ROUND(AVG(p.amount), 2) AS average_payment
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY average_payment DESC
LIMIT 10;

-- ==========================================================
-- Business Question 7: Rank customers by total spending
-- Purpose:
-- Rank customers based on their total spending using
-- the DENSE_RANK() window function.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent,
    DENSE_RANK() OVER (ORDER BY SUM(p.amount) DESC) AS customer_rank
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name;


-- ==========================================================
-- Business Question 8: Top spending customer in each country
-- Purpose:
-- Identify the highest-spending customer in every country
-- using the DENSE_RANK() window function.
-- ==========================================================

SELECT
    country,
    first_name,
    last_name,
    total_spent
FROM
(
    SELECT
        cn.country,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spent,
        DENSE_RANK() OVER (
            PARTITION BY cn.country
            ORDER BY SUM(p.amount) DESC
        ) AS rn
    FROM customer c
    JOIN address a
        ON c.address_id = a.address_id
    JOIN city ct
        ON a.city_id = ct.city_id
    JOIN country cn
        ON ct.country_id = cn.country_id
    JOIN payment p
        ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id,
        cn.country,
        c.first_name,
        c.last_name
) AS customer_ranking
WHERE rn = 1
ORDER BY country;

-- ==========================================================
-- Business Question 9: Customer Contribution to Total Revenue
-- Purpose:
-- Calculate each customer's contribution to the company's
-- total revenue as a percentage.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent,
    ROUND(
        (SUM(p.amount) / (SELECT SUM(amount) FROM payment)) * 100,
        2
    ) AS revenue_percentage
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY revenue_percentage DESC
LIMIT 10;

-- ==========================================================
-- Business Question 10: Customer Segmentation by Spending
-- Purpose:
-- Classify customers into Gold, Silver, and Bronze tiers
-- based on their total spending.
-- This helps the business identify customer segments for
-- targeted marketing and loyalty programs.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent,
    CASE
        WHEN SUM(p.amount) >= 150 THEN 'Gold'
        WHEN SUM(p.amount) >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC;

-- ==========================================================
-- Business Question 11: Customer Spending Category
-- Purpose:
-- Classify customers based on whether their total spending
-- is above or below the average customer spending.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent,
    CASE
        WHEN SUM(p.amount) >
            (
                SELECT
                    SUM(amount) / COUNT(DISTINCT customer_id)
                FROM payment
            )
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC;


-- ==========================================================
-- Business Question 12: Most Recent Rental for Each Customer
-- Purpose:
-- Determine the latest rental date for every customer.
-- This provides a complete customer activity report and
-- serves as a foundation for customer recency and inactivity
-- analysis.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(r.rental_date) AS last_rental_date
FROM customer c
JOIN rental r
    ON r.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    c.customer_id;
-- ==========================================================
-- Business Question 13: Customer Inactivity Period
-- Purpose:
-- Calculate the number of days since each customer's
-- most recent rental.
-- This helps identify inactive customers for
-- re-engagement campaigns.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(DATE(r.rental_date)) AS last_rental_date,
    CURRENT_DATE - MAX(DATE(r.rental_date)) AS inactive_days
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    inactive_days DESC;

-- ==========================================================
-- Business Question 14: First Rental Date for Each Customer
-- Purpose:
-- Identify when each customer made their first rental.
-- This helps understand customer acquisition history
-- and supports customer lifecycle analysis.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    MIN(DATE(r.rental_date)) AS first_rental_date
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    first_rental_date ASC;


-- ==========================================================
-- Business Question 15: Days Between Consecutive Rentals
-- Purpose:
-- Calculate the number of days between consecutive rentals
-- for each customer.
-- This helps analyze customer rental frequency and
-- engagement patterns.
-- ==========================================================

WITH customer_rentals AS
(
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        DATE(r.rental_date) AS rental_date,
        LAG(DATE(r.rental_date)) OVER
        (
            PARTITION BY c.customer_id
            ORDER BY r.rental_date
        ) AS previous_rental_date
    FROM customer c
    JOIN rental r
        ON c.customer_id = r.customer_id
)

SELECT
    customer_id,
    first_name,
    last_name,
    rental_date,
    previous_rental_date,
    rental_date - previous_rental_date AS days_between_rentals
FROM customer_rentals
ORDER BY
    customer_id,
    rental_date;

-- ==========================================================
-- Business Question 16: Monthly Rental Trend
-- Purpose:
-- Analyze the number of rentals made each month.
-- This helps identify seasonal demand patterns and
-- customer rental trends over time.
-- ==========================================================

SELECT
    TO_CHAR(rental_date, 'YYYY-MM') AS rental_month,
    COUNT(*) AS total_rentals
FROM rental
GROUP BY
    TO_CHAR(rental_date, 'YYYY-MM')
ORDER BY
    rental_month;

-- ==========================================================
-- Business Question 17: Top 5 Busiest Rental Days
-- Purpose:
-- Identify the days with the highest rental activity.
-- This helps the business understand peak demand periods
-- and optimize staffing and inventory planning.
-- ==========================================================

SELECT
    DATE(rental_date) AS rental_date,
    COUNT(*) AS total_rentals
FROM rental
GROUP BY
    DATE(rental_date)
ORDER BY
    total_rentals DESC
LIMIT 5;

-- ==========================================================
-- Business Question 18: Top Spending Customer in Each Country
-- (Using ROW_NUMBER)
-- Purpose:
-- Identify the highest-spending customer in each country
-- using the ROW_NUMBER() window function.
-- This demonstrates how ROW_NUMBER() differs from
-- DENSE_RANK() when handling ties.
-- ==========================================================

SELECT
    country,
    customer_id,
    first_name,
    last_name,
    total_spent
FROM
(
    SELECT
        cn.country,
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spent,
        ROW_NUMBER() OVER
        (
            PARTITION BY cn.country
            ORDER BY SUM(p.amount) DESC
        ) AS rn
    FROM customer c
    JOIN address a
        ON c.address_id = a.address_id
    JOIN city ct
        ON a.city_id = ct.city_id
    JOIN country cn
        ON ct.country_id = cn.country_id
    JOIN payment p
        ON c.customer_id = p.customer_id
    GROUP BY
        cn.country,
        c.customer_id,
        c.first_name,
        c.last_name
) AS customer_ranking
WHERE rn = 1
ORDER BY country;

-- ==========================================================
-- Business Question 19: Top 10 Customers by Number of Payments
-- Purpose:
-- Identify customers who make payments most frequently.
-- This helps understand customer purchasing behavior
-- and transaction frequency.
-- ==========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(p.payment_id) AS total_payments
FROM customer c
JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_payments DESC
LIMIT 10;

-- ==========================================================
-- Business Question 20: Customer Spending Quartiles
-- Purpose:
-- Divide customers into four spending groups based on
-- their total spending using the NTILE() window function.
-- ==========================================================

WITH customer_spending AS
(
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spent
    FROM customer c
    JOIN payment p
        ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
)

SELECT
    customer_id,
    first_name,
    last_name,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_quartile
FROM customer_spending
ORDER BY
    total_spent DESC;





