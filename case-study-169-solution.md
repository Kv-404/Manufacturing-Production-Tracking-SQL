# Case Study 169: Manufacturing Production Tracking

**B.Tech CSE 2025-29 · Database Management Systems · Semester III · SQL & NoSQL**

**Title:** Manufacturing Production and Output Database Using SQL

**Syllabus focus:** `GROUP BY`, `SUM`, and date analysis

Runnable script: `case-study-169.sql` (verified with SQLite).

---

## 1. Problem

A manufacturing company records products and daily output. Managers need reports of how many units were produced, by product and by date, and how many of those units were rejected.

## 2. What this solution builds

Two tables, as the brief asks:

| Table | What it stores |
| --- | --- |
| `products` | Chair Model A, Table Model B, Cabinet Model C |
| `production_logs` | Product, production date, quantity produced, rejected units, shift (Morning or Evening) |

**Accepted units** = quantity produced − rejected units. Rejected units are already inside the produced count. A row is rejected by the database if rejected units exceed quantity produced.

**Rejection %** = rejected ÷ produced × 100

**Efficiency %** = accepted ÷ produced × 100

## 3. Schema

```sql
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
```

## 4. Sample data

Three days, both shifts. Quantities include 120, 80 and 60, with different reject counts. Cabinet has no morning row on 29 Sep and Chair has no morning row on 30 Sep, so the `GROUP BY` still has to add whatever rows exist.

| Date | Product | Shift | Produced | Rejected |
| --- | --- | --- | --- | --- |
| 2026-09-28 | Chair Model A | Morning | 120 | 6 |
| 2026-09-28 | Table Model B | Morning | 80 | 4 |
| 2026-09-28 | Cabinet Model C | Morning | 60 | 5 |
| 2026-09-28 | Chair Model A | Evening | 85 | 8 |
| 2026-09-28 | Table Model B | Evening | 50 | 3 |
| 2026-09-28 | Cabinet Model C | Evening | 40 | 2 |
| 2026-09-29 | Chair Model A | Morning | 120 | 4 |
| 2026-09-29 | Table Model B | Morning | 80 | 7 |
| 2026-09-29 | Cabinet Model C | Evening | 60 | 3 |
| 2026-09-29 | Chair Model A | Evening | 100 | 10 |
| 2026-09-30 | Table Model B | Morning | 80 | 2 |
| 2026-09-30 | Cabinet Model C | Morning | 60 | 6 |
| 2026-09-30 | Chair Model A | Evening | 95 | 5 |
| 2026-09-30 | Table Model B | Evening | 65 | 4 |
| 2026-09-30 | Cabinet Model C | Evening | 45 | 1 |

## 5. Queries and results

`SUM` adds the numeric column inside each group. `GROUP BY` decides what one result row means: one product, one date, or one shift. Dividing two sums (not averaging the daily percentages) gives the true rejection rate for the whole group.

### Q1. Total production by product

```sql
SELECT
    p.product_name,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.quantity_produced - l.rejected_units) AS total_accepted
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_produced DESC;
```

| Product | Total produced | Total accepted |
| --- | ---: | ---: |
| Chair Model A | 520 | 487 |
| Table Model B | 355 | 335 |
| Cabinet Model C | 265 | 248 |

Chair Model A is the highest-volume product.

### Q2. Total rejected units

```sql
SELECT
    p.product_name,
    SUM(l.rejected_units) AS total_rejected
FROM products AS p
JOIN production_logs AS l ON l.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_rejected DESC;
```

| Product | Total rejected |
| --- | ---: |
| Chair Model A | 33 |
| Table Model B | 20 |
| Cabinet Model C | 17 |

Shop-wide:

```sql
SELECT
    SUM(rejected_units) AS grand_total_rejected,
    SUM(quantity_produced) AS grand_total_produced
FROM production_logs;
```

| Grand total rejected | Grand total produced |
| ---: | ---: |
| 70 | 1140 |

### Q3. Rejection percentage

Percentage is computed from the sums, so a big day weighs more than a small day.

```sql
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
GROUP BY p.product_id, p.product_name
ORDER BY rejection_pct DESC;
```

| Product | Produced | Rejected | Rejection % | Efficiency % |
| --- | ---: | ---: | ---: | ---: |
| Cabinet Model C | 265 | 17 | 6.42 | 93.58 |
| Chair Model A | 520 | 33 | 6.35 | 93.65 |
| Table Model B | 355 | 20 | 5.63 | 94.37 |

Chair rejects the most units (33) because it produces the most. Cabinet has the worst rejection rate (6.42%). Table Model B is the most efficient (94.37%).

### Q4. Daily production summaries

**4a. One row per date**

```sql
SELECT
    l.production_date,
    SUM(l.quantity_produced) AS daily_produced,
    SUM(l.rejected_units) AS daily_rejected,
    SUM(l.quantity_produced - l.rejected_units) AS daily_accepted,
    ROUND(100.0 * SUM(l.rejected_units) / SUM(l.quantity_produced), 2) AS daily_rejection_pct
FROM production_logs AS l
GROUP BY l.production_date
ORDER BY l.production_date;
```

| Date | Produced | Rejected | Accepted | Rejection % |
| --- | ---: | ---: | ---: | ---: |
| 2026-09-28 | 435 | 28 | 407 | 6.44 |
| 2026-09-29 | 360 | 24 | 336 | 6.67 |
| 2026-09-30 | 345 | 18 | 327 | 5.22 |

Output falls each day. 29 Sep has the highest rejection rate. 30 Sep is the cleanest day.

**4b. Quantity by product and date** (morning and evening added). This is the report in the problem statement.

```sql
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
```

| Date | Product | Produced | Rejected | Accepted |
| --- | --- | ---: | ---: | ---: |
| 2026-09-28 | Cabinet Model C | 100 | 7 | 93 |
| 2026-09-28 | Chair Model A | 205 | 14 | 191 |
| 2026-09-28 | Table Model B | 130 | 7 | 123 |
| 2026-09-29 | Cabinet Model C | 60 | 3 | 57 |
| 2026-09-29 | Chair Model A | 220 | 14 | 206 |
| 2026-09-29 | Table Model B | 80 | 7 | 73 |
| 2026-09-30 | Cabinet Model C | 105 | 7 | 98 |
| 2026-09-30 | Chair Model A | 95 | 5 | 90 |
| 2026-09-30 | Table Model B | 145 | 6 | 139 |

**4c. Date filter.** Same grouping, limited to 28–29 Sep with `WHERE production_date BETWEEN '2026-09-28' AND '2026-09-29'`. 30 Sep drops out. That is the date-analysis part: filter on the date column, then aggregate.

### Q5. Shift with the highest production

```sql
SELECT
    l.shift,
    SUM(l.quantity_produced) AS total_produced,
    SUM(l.rejected_units) AS total_rejected
FROM production_logs AS l
GROUP BY l.shift
ORDER BY total_produced DESC;
```

| Shift | Produced | Rejected |
| --- | ---: | ---: |
| Morning | 600 | 34 |
| Evening | 540 | 36 |

The winning shift, using `HAVING` so a tie would return both shifts:

```sql
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
```

**Morning**, with **600** units. Evening produced 540. Morning also rejected fewer units (34 vs 36), so it leads on volume and on reject count.

## 6. Efficiency report

One result that combines Q1–Q3:

| Product | Log rows | Produced | Rejected | Accepted | Rejection % | Efficiency % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Table Model B | 5 | 355 | 20 | 335 | 5.63 | 94.37 |
| Chair Model A | 5 | 520 | 33 | 487 | 6.35 | 93.65 |
| Cabinet Model C | 5 | 265 | 17 | 248 | 6.42 | 93.58 |

## 7. Reading for the viva

- `GROUP BY product` answers “how much did each product make?”
- `GROUP BY production_date` answers “how much did the shop make each day?”
- `GROUP BY production_date, product` answers the manager’s report: quantity by product and date.
- `GROUP BY shift` answers which shift produced more.
- `SUM` is the right aggregate because production and rejects add up. `COUNT` would only count log rows, not units.
- Rejection percentage uses `SUM(rejected) / SUM(produced)`, not `AVG` of each row’s percentage. A 10% reject on 120 units must count more than a 10% reject on 40 units.
- `WHERE production_date BETWEEN ...` is the date filter. It runs before `GROUP BY`, so only those days enter the sums.
- The check constraint `rejected_units <= quantity_produced` stops a bad insert from making efficiency go above 100% or rejection go negative.
