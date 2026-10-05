-- =============================================================================
-- CASE STUDY 169: Manufacturing Production Tracking
-- B.Tech CSE 2025-29 | DBMS | Semester III | SQL & NoSQL
-- Title: Manufacturing Production and Output Database Using SQL
-- Focus: GROUP BY, SUM, and date analysis
-- =============================================================================
-- A manufacturing company records products and daily output. Managers need
-- production quantity by product and by date, plus efficiency (how many units
-- were rejected).
--
-- Tables required by the brief:
--   products         product catalogue
--   production_logs  one row per product, per date, per shift
--
-- Rejected units are units that failed inspection. They are already included
-- in quantity_produced. Accepted units = quantity_produced - rejected_units.
-- Rejection %  = rejected / produced * 100
-- Efficiency % = accepted / produced * 100

DROP TABLE IF EXISTS production_logs;
DROP TABLE IF EXISTS products;

-- -----------------------------------------------------------------------------
-- SCHEMA
-- -----------------------------------------------------------------------------

CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE production_logs (
    log_id             INTEGER PRIMARY KEY,
    product_id         INTEGER      NOT NULL,
    production_date    DATE         NOT NULL,
    quantity_produced  INTEGER      NOT NULL,
    rejected_units     INTEGER      NOT NULL,
    shift              VARCHAR(20)  NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products (product_id),
    CHECK (quantity_produced >= 0),
    CHECK (rejected_units >= 0),
    CHECK (rejected_units <= quantity_produced),
    CHECK (shift IN ('Morning', 'Evening'))
);

-- -----------------------------------------------------------------------------
-- SAMPLE DATA
-- Products: Chair Model A, Table Model B, Cabinet Model C
-- Shifts: Morning and Evening
-- Quantities include 120, 80 and 60, with different reject counts
-- Dates: 28, 29 and 30 September 2026 so daily summaries are meaningful
-- -----------------------------------------------------------------------------

INSERT INTO products (product_id, product_name) VALUES
    (1, 'Chair Model A'),
    (2, 'Table Model B'),
    (3, 'Cabinet Model C');

INSERT INTO production_logs
    (log_id, product_id, production_date, quantity_produced, rejected_units, shift)
VALUES
    -- 28 Sep 2026
    (1,  1, '2026-09-28', 120, 6, 'Morning'),
    (2,  2, '2026-09-28',  80, 4, 'Morning'),
    (3,  3, '2026-09-28',  60, 5, 'Morning'),
    (4,  1, '2026-09-28',  85, 8, 'Evening'),
    (5,  2, '2026-09-28',  50, 3, 'Evening'),
    (6,  3, '2026-09-28',  40, 2, 'Evening'),
    -- 29 Sep 2026
    (7,  1, '2026-09-29', 120, 4, 'Morning'),
    (8,  2, '2026-09-29',  80, 7, 'Morning'),
    (9,  3, '2026-09-29',  60, 3, 'Evening'),
    (10, 1, '2026-09-29', 100,10, 'Evening'),
    -- 30 Sep 2026
    (11, 2, '2026-09-30',  80, 2, 'Morning'),
    (12, 3, '2026-09-30',  60, 6, 'Morning'),
    (13, 1, '2026-09-30',  95, 5, 'Evening'),
    (14, 2, '2026-09-30',  65, 4, 'Evening'),
    (15, 3, '2026-09-30',  45, 1, 'Evening');

-- -----------------------------------------------------------------------------
-- CHECK: raw log the reports are built from
-- -----------------------------------------------------------------------------

SELECT
    l.log_id,
    p.product_name,
    l.production_date,
    l.shift,
    l.quantity_produced,
    l.rejected_units,
    l.quantity_produced - l.rejected_units AS accepted_units
FROM production_logs AS l
JOIN products AS p ON p.product_id = l.product_id
ORDER BY l.production_date, l.shift, p.product_name;

-- =============================================================================
-- Q1. Total production by product
--     SUM of quantity_produced, one row per product.
-- =============================================================================

SELECT
    p.product_name,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.quantity_produced - l.rejected_units) AS total_accepted
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_produced DESC;

-- =============================================================================
-- Q2. Total rejected units
--     Per product, and one grand total for the whole shop.
-- =============================================================================

SELECT
    p.product_name,
    SUM(l.rejected_units) AS total_rejected
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_rejected DESC;

SELECT
    SUM(rejected_units) AS grand_total_rejected,
    SUM(quantity_produced) AS grand_total_produced
FROM production_logs;

-- =============================================================================
-- Q3. Rejection percentage
--     rejection % = total rejected / total produced * 100
--     Also show efficiency % (accepted / produced), which is the complement.
-- =============================================================================

SELECT
    p.product_name,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.rejected_units) AS total_rejected,
    ROUND(
        100.0 * SUM(l.rejected_units) / SUM(l.quantity_produced),
        2
    ) AS rejection_pct,
    ROUND(
        100.0 * SUM(l.quantity_produced - l.rejected_units) / SUM(l.quantity_produced),
        2
    ) AS efficiency_pct
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY rejection_pct DESC;

-- =============================================================================
-- Q4. Daily production summaries
--     4a. One row per date (shop-wide).
--     4b. One row per date AND product. This is the report named in the
--         problem statement: production quantity by product and date.
--     4c. Date filter: only 28 and 29 Sep, to show a date-range analysis.
-- =============================================================================

-- 4a. Shop-wide daily summary
SELECT
    l.production_date,
    SUM(l.quantity_produced) AS daily_produced,
    SUM(l.rejected_units) AS daily_rejected,
    SUM(l.quantity_produced - l.rejected_units) AS daily_accepted,
    ROUND(
        100.0 * SUM(l.rejected_units) / SUM(l.quantity_produced),
        2
    ) AS daily_rejection_pct
FROM production_logs AS l
GROUP BY l.production_date
ORDER BY l.production_date;

-- 4b. Quantity by product and date (morning + evening added together)
SELECT
    l.production_date,
    p.product_name,
    SUM(l.quantity_produced) AS quantity_produced,
    SUM(l.rejected_units) AS rejected_units,
    SUM(l.quantity_produced - l.rejected_units) AS accepted_units
FROM production_logs AS l
JOIN products AS p ON p.product_id = l.product_id
GROUP BY l.production_date, p.product_id, p.product_name
ORDER BY l.production_date, p.product_name;

-- 4c. Date-range slice
SELECT
    l.production_date,
    p.product_name,
    SUM(l.quantity_produced) AS quantity_produced
FROM production_logs AS l
JOIN products AS p ON p.product_id = l.product_id
WHERE l.production_date BETWEEN '2026-09-28' AND '2026-09-29'
GROUP BY l.production_date, p.product_id, p.product_name
ORDER BY l.production_date, p.product_name;

-- =============================================================================
-- Q5. Shift with the highest production
--     5a. Totals for every shift (so the comparison is visible).
--     5b. Only the winning shift. HAVING keeps both shifts if they tie.
-- =============================================================================

-- 5a. Production by shift
SELECT
    l.shift,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.rejected_units) AS total_rejected
FROM production_logs AS l
GROUP BY l.shift
ORDER BY total_produced DESC;

-- 5b. The shift (or shifts) with the highest production
SELECT
    l.shift,
    SUM(l.quantity_produced) AS total_produced
FROM production_logs AS l
GROUP BY l.shift
HAVING SUM(l.quantity_produced) = (
    SELECT MAX(shift_total)
    FROM (
        SELECT SUM(quantity_produced) AS shift_total
        FROM production_logs
        GROUP BY shift
    ) AS shift_totals
);

-- =============================================================================
-- EFFICIENCY REPORT (puts Q1-Q3 in one result managers can read)
-- =============================================================================

SELECT
    p.product_name,
    COUNT(l.log_id) AS log_rows,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.rejected_units) AS total_rejected,
    SUM(l.quantity_produced - l.rejected_units) AS total_accepted,
    ROUND(100.0 * SUM(l.rejected_units) / SUM(l.quantity_produced), 2) AS rejection_pct,
    ROUND(
        100.0 * SUM(l.quantity_produced - l.rejected_units) / SUM(l.quantity_produced),
        2
    ) AS efficiency_pct
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY efficiency_pct DESC;
