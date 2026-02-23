# Collections Management ETL Pipeline

![SQL](https://img.shields.io/badge/SQL-SQLite-blue)
![Status](https://img.shields.io/badge/Status-Production-green)
![Daily](https://img.shields.io/badge/Execution-Daily-orange)

## Overview

Production ETL pipeline for debt collections portfolio analytics, processing 700+ accounts daily with automated activity tracking and KPI generation. Built for real-world operations where data structure requirements often prioritize business integration over theoretical optimization.

**Key Metrics:**
- **Accounts Processed:** 700+ daily
- **Data Sources:** 2 CSV files (assignments + activity)
- **Output:** 80+ column analytical report
- **Execution Time:** <1 second
- **Use Case:** Executive reporting, collector performance, portfolio risk assessment

## Project Structure

```
collections-etl/
├── collections_01_schema.sql          # Database schema + analytical view
├── collections_02_sample_data.sql     # Sample dataset for testing
├── collections_03_analytical_query.sql # Main reporting query
└── PIPELINE_OVERVIEW.md               # This file
```

## Business Context

### The Reality of Enterprise Reporting

This project demonstrates a common scenario in data analytics: **business requirements drive structure**. The 80+ column output format exists because:

1. **Legacy System Integration:** Downstream BI tools expect specific column names and positions
2. **Regulatory Compliance:** Certain fields required for audit trails even if currently unpopulated
3. **Historical Continuity:** Report structure maintained for year-over-year comparisons
4. **Multi-Department Use:** Different teams extract different column subsets

**This is production-grade SQL** — not textbook-perfect, but battle-tested and delivering value daily.

## Technical Approach

### Data Flow

```
Daily CSV Files
      ↓
Staging Tables (stg_*)
      ↓
Analytical View (vw_collections_summary)
      ↓
Final Report Query
      ↓
BI Dashboard / Executive Report
```

### Key Design Decisions

#### 1. View-Based Aggregation
```sql
CREATE VIEW vw_collections_summary AS
WITH prep_activities AS (...)
```
**Why:** Pre-aggregates activity metrics by account, enabling simple LEFT JOIN in final query. Significantly faster than subquery approach for 700+ accounts.

#### 2. Defensive NULL Handling
```sql
CASE
    WHEN COALESCE(cs.total_phone, 0) = 0 THEN 1
    ELSE 0
END AS q_no_phone_activity
```
**Why:** LEFT JOIN can return NULL when account has no activity. Must handle both `NULL` and `0` scenarios.

#### 3. Standardized Contact Classification
```sql
ROW_NUMBER() OVER(
    PARTITION BY account_id 
    ORDER BY collection_type ASC, contact_type ASC, activity_date DESC
) AS rn
```
**Why:** Determines "best contact achieved" per account using business-defined ranking (Phone > Field > Email, Direct > Indirect > No Contact).

## SQL Techniques Demonstrated

### Window Functions
- `ROW_NUMBER()` for identifying best activity per account
- Partitioning by account_id with multi-column ordering

### CTEs (Common Table Expressions)
- Multi-level CTEs for complex aggregation logic
- Improved readability vs nested subqueries
- Better performance for repeated calculations

### Data Type Handling
```sql
CAST(REPLACE(REPLACE(aa.total_debt, '.', ''), '.', '') AS INTEGER)
```
Handling Chilean currency format (dots as thousand separators) from CSV import.

### Date Transformation
```sql
DATE(
    SUBSTR(activity_date, 7, 4) || '-' ||
    SUBSTR(activity_date, 4, 2) || '-' ||
    SUBSTR(activity_date, 1, 2)
)
```
Converting DD/MM/YYYY text to ISO date format for proper sorting.

### Conditional Aggregation
```sql
COUNT(CASE WHEN collection_type = '01.PHONE' THEN 1 END) AS total_phone
```
Pivot-style aggregation without PIVOT function (SQLite limitation).

## Daily Workflow

### Step 1: Clear Staging Tables
```sql
DELETE FROM stg_collections_activity;
DELETE FROM stg_account_assignment;
```

### Step 2: Import Fresh Data
- Use DBeaver's "Import Data" feature
- Load updated CSV files into staging tables
- ~30 seconds manual process

### Step 3: Execute Report Query
- Run `collections_03_analytical_query.sql`
- Results exported to BI tool or executive dashboard

## Sample Queries

### Portfolio Summary
```sql
SELECT 
    debt_tier,
    COUNT(*) AS accounts,
    SUM(total_debt) AS total_balance,
    SUM(q_phone) AS phone_attempts,
    SUM(q_direct_contact) AS direct_contacts
FROM (
    -- Main query here
)
GROUP BY debt_tier
ORDER BY total_balance DESC;
```

### Collector Performance
```sql
SELECT 
    collector_name,
    COUNT(*) AS accounts_worked,
    SUM(q_direct_contact) AS direct_contacts,
    ROUND(100.0 * SUM(q_direct_contact) / COUNT(*), 2) AS contact_rate
FROM (
    -- Main query here
)
WHERE collector_name != 'NO_MATCH'
GROUP BY collector_name
ORDER BY contact_rate DESC;
```

### Accounts Without Phone Contact
```sql
SELECT 
    account_id,
    debtor_name,
    total_debt,
    total_activities,
    contact_classification
FROM (
    -- Main query here
)
WHERE q_no_phone_activity = 1
ORDER BY total_debt DESC;
```

## Technical Challenges Solved

### Challenge 1: NULL vs Zero Distinction
**Problem:** LEFT JOIN returns NULL for accounts without activity, but business logic treats "no activity" and "zero of specific activity type" differently.

**Solution:** Explicit NULL handling in CASE statements:
```sql
WHEN COALESCE(cs.total_phone, 0) = 0 THEN 1
```

### Challenge 2: Multiple Activity Types per Account
**Problem:** Account can have 10+ activities; need to identify single "best" contact.

**Solution:** ROW_NUMBER() with business-driven ordering logic in view.

### Challenge 3: CSV Date Format Conversion
**Problem:** Source CSVs use DD/MM/YYYY text format; need proper dates for sorting.

**Solution:** SUBSTR() + concatenation to build ISO format strings, wrapped in DATE().

## Performance Optimization

- **Indexing:** account_id indexed on both staging tables
- **View Materialization:** Pre-aggregation reduces final query complexity
- **Selective Columns:** Despite 80+ output columns, view only calculates necessary metrics
- **Minimal JOINs:** Single LEFT JOIN in final query

## Real-World Lessons

### What This Project Teaches

1. **Business Requirements Trump Optimization:** Sometimes you need 80 columns even if 20 would be "cleaner"
2. **Documentation Matters:** Complex business logic needs clear comments
3. **Defensive Coding:** Handle NULLs explicitly; assume data will be messy
4. **Iterative Approach:** Started simple, added complexity as business needs evolved

### What Makes This Production-Ready

- ✅ Handles missing data gracefully
- ✅ Clear comments explaining business logic
- ✅ Consistent naming conventions
- ✅ Proven to run reliably for months
- ✅ Integrated with existing workflows

## Setup Instructions

### Prerequisites
- SQLite 3.x
- DBeaver (or similar SQL client)

### Installation

```bash
# 1. Create database
sqlite3 collections.db

# 2. Run schema
.read collections_01_schema.sql

# 3. Load sample data
.read collections_02_sample_data.sql

# 4. Test report query
.read collections_03_analytical_query.sql
```

### Using with DBeaver

1. Create new SQLite connection pointing to your .db file
2. Execute schema script
3. Use "Import Data" to load your CSV files
4. Run analytical query
5. Export results to CSV/Excel for BI consumption

## Contributing

This is a portfolio project demonstrating real-world SQL patterns. The structure reflects actual business requirements, not idealized examples.

## Author

**Data Analytics Professional**
- 12+ years experience in collections analytics
- Specialized in SQL optimization and ETL pipeline development
- Focus on translating business requirements into scalable data solutions

## License

Sample data and structure provided for educational/portfolio purposes. All data is fictional.

---

## Why This Portfolio Project Stands Out

Most SQL portfolios show clean, optimized queries on perfect datasets. This project shows the messy reality:

- Working with CSV imports (data analysts' daily bread)
- Meeting inflexible reporting requirements
- Handling NULL values defensively
- Balancing performance with readability
- Documenting business context, not just technical implementation

**This is what data analysis actually looks like in production.**
