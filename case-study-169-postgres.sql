-- Case Study 169: Manufacturing Production Tracking
-- PostgreSQL. Database name: case_study_169
-- Load with: psql -d case_study_169 -f case-study-169-postgres.sql

DROP VIEW IF EXISTS v_highest_shift;
DROP VIEW IF EXISTS v_shift_totals;
DROP VIEW IF EXISTS v_daily_by_product;
DROP VIEW IF EXISTS v_daily_summary;
DROP VIEW IF EXISTS v_rejection_percentage;
DROP VIEW IF EXISTS v_shop_totals;
DROP VIEW IF EXISTS v_rejected_by_product;
DROP VIEW IF EXISTS v_production_by_product;

DROP TABLE IF EXISTS production_logs;
DROP TABLE IF EXISTS products;

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

INSERT INTO products (product_id, product_name) VALUES
    (1, 'Chair Model A'),
    (2, 'Table Model B'),
    (3, 'Cabinet Model C');

INSERT INTO production_logs
    (log_id, product_id, production_date, quantity_produced, rejected_units, shift)
VALUES
    (1,  1, '2026-09-28', 120, 6,  'Morning'),
    (2,  2, '2026-09-28',  80, 4,  'Morning'),
    (3,  3, '2026-09-28',  60, 5,  'Morning'),
    (4,  1, '2026-09-28',  85, 8,  'Evening'),
    (5,  2, '2026-09-28',  50, 3,  'Evening'),
    (6,  3, '2026-09-28',  40, 2,  'Evening'),
    (7,  1, '2026-09-29', 120, 4,  'Morning'),
    (8,  2, '2026-09-29',  80, 7,  'Morning'),
    (9,  3, '2026-09-29',  60, 3,  'Evening'),
    (10, 1, '2026-09-29', 100, 10, 'Evening'),
    (11, 2, '2026-09-30',  80, 2,  'Morning'),
    (12, 3, '2026-09-30',  60, 6,  'Morning'),
    (13, 1, '2026-09-30',  95, 5,  'Evening'),
    (14, 2, '2026-09-30',  65, 4,  'Evening'),
    (15, 3, '2026-09-30',  45, 1,  'Evening');

CREATE VIEW v_production_by_product AS
SELECT
    p.product_name,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.quantity_produced - l.rejected_units) AS total_accepted
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

CREATE VIEW v_rejected_by_product AS
SELECT
    p.product_name,
    SUM(l.rejected_units) AS total_rejected
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

CREATE VIEW v_shop_totals AS
SELECT
    SUM(rejected_units) AS grand_total_rejected,
    SUM(quantity_produced) AS grand_total_produced,
    SUM(quantity_produced - rejected_units) AS grand_total_accepted
FROM production_logs;

CREATE VIEW v_rejection_percentage AS
SELECT
    p.product_name,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.rejected_units) AS total_rejected,
    ROUND(100.0 * SUM(l.rejected_units) / SUM(l.quantity_produced), 2) AS rejection_pct,
    ROUND(
        100.0 * SUM(l.quantity_produced - l.rejected_units) / SUM(l.quantity_produced),
        2
    ) AS efficiency_pct
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

CREATE VIEW v_daily_summary AS
SELECT
    l.production_date,
    SUM(l.quantity_produced) AS daily_produced,
    SUM(l.rejected_units) AS daily_rejected,
    SUM(l.quantity_produced - l.rejected_units) AS daily_accepted,
    ROUND(100.0 * SUM(l.rejected_units) / SUM(l.quantity_produced), 2) AS daily_rejection_pct
FROM production_logs AS l
GROUP BY l.production_date;

CREATE VIEW v_daily_by_product AS
SELECT
    l.production_date,
    p.product_name,
    SUM(l.quantity_produced) AS quantity_produced,
    SUM(l.rejected_units) AS rejected_units,
    SUM(l.quantity_produced - l.rejected_units) AS accepted_units
FROM production_logs AS l
JOIN products AS p ON p.product_id = l.product_id
GROUP BY l.production_date, p.product_id, p.product_name;

CREATE VIEW v_shift_totals AS
SELECT
    l.shift,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.rejected_units) AS total_rejected
FROM production_logs AS l
GROUP BY l.shift;

CREATE VIEW v_highest_shift AS
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

-- Answers. These are the five reports from the case study.
SELECT * FROM v_production_by_product ORDER BY total_produced DESC;
SELECT * FROM v_rejected_by_product ORDER BY total_rejected DESC;
SELECT * FROM v_shop_totals;
SELECT * FROM v_rejection_percentage ORDER BY rejection_pct DESC;
SELECT * FROM v_daily_summary ORDER BY production_date;
SELECT * FROM v_daily_by_product ORDER BY production_date, product_name;
SELECT * FROM v_shift_totals ORDER BY total_produced DESC;
SELECT * FROM v_highest_shift;
