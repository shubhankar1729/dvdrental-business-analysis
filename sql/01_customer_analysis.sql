/*
==========================================================
Project : DVD Rental Business Analysis
File    : 01_customer_analysis.sql

Description:
This script analyzes customer behavior and purchasing patterns.

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






