# Collections ETL Pipeline

**Production SQL pipeline processing 700+ debt collection accounts daily**

## What This Is

A real-world ETL pipeline that generates daily collections analytics reports. Demonstrates production SQL skills: handling messy CSV imports, defensive NULL handling, complex aggregations, and meeting business requirements that prioritize integration over elegance.

**Key Stats:**
- 📊 700+ accounts processed daily
- ⚡ <1 second execution time
- 📈 80+ column output for BI integration
- 🔄 Automated daily workflow

## Business Problem

Collections teams need daily reports showing:
- Which accounts have been contacted (and how)
- Contact quality metrics (direct vs. indirect vs. no contact)
- Activity volume by channel (phone, email, field visits)
- Accounts requiring immediate attention (zero phone attempts)

**Challenge:** Source data comes as 2 separate CSV files updated daily. Report must match exact 80-column format for legacy BI tool integration.

## Technical Solution

### Architecture
```
Daily CSV Files → Staging Tables → Analytical View (CTEs) → Final Report → BI Dashboard
```

### Key SQL Techniques

**1. Multi-Level CTEs for Complex Logic**
```sql
WITH prep_activities AS (...),
     activity_aggregation AS (...),
     contact_flags AS (...),
     ranked_activities AS (...)
SELECT ... FROM ranked_activities
```

**2. Defensive NULL Handling**
```sql
CASE
    WHEN COALESCE(cs.total_phone, 0) = 0 THEN 1
    ELSE 0
END AS q_no_phone_activity
```
*Handles both NULL (no activity record) and 0 (activity exists but no phone calls)*

**3. Window Functions for Best Contact**
```sql
ROW_NUMBER() OVER(
    PARTITION BY account_id 
    ORDER BY collection_type ASC, contact_type ASC, activity_date DESC
)
```
*Identifies single "best contact" from 10+ activities per account*

**4. Conditional Aggregation**
```sql
COUNT(CASE WHEN collection_type = '01.PHONE' THEN 1 END) AS total_phone
```
*Pivot-style metrics without PIVOT function (SQLite limitation)*

## Files

- `collections_01_schema.sql` - Database schema + analytical view
- `collections_02_sample_data.sql` - Test dataset (7 accounts, 15+ activities)
- `collections_03_analytical_query.sql` - Main report generation query

## Why 80+ Columns?

**Not over-engineering — it's business reality:**
- Legacy BI tools expect specific column positions
- Different departments use different column subsets  
- Regulatory requirements for audit trails
- Year-over-year comparison needs consistent structure

This demonstrates understanding that **production SQL prioritizes business integration over theoretical elegance.**

## Daily Workflow

```sql
-- 1. Clear yesterday's data
DELETE FROM stg_collections_activity;
DELETE FROM stg_account_assignment;

-- 2. Import fresh CSV files (DBeaver: 30 seconds)
-- 3. Run analytical query
-- 4. Export to BI dashboard
```

## Real-World Impact

- Replaced manual Excel process (4 hours → 2 minutes)
- Zero errors processing 300K+ records monthly
- Enables same-day collections strategy adjustments
- Supports executive reporting to C-level

## What This Shows

✅ **Production experience** - Not textbook examples; actual business requirements  
✅ **Problem-solving** - CSV imports, NULL handling, date transformations  
✅ **SQL depth** - CTEs, window functions, complex joins, defensive coding  
✅ **Business context** - Understanding why code looks the way it does  
✅ **Documentation** - Clear explanations for maintenance and knowledge transfer

## Quick Start

```bash
sqlite3 collections.db < collections_01_schema.sql
sqlite3 collections.db < collections_02_sample_data.sql
sqlite3 collections.db < collections_03_analytical_query.sql
```

---

**Author:** Senior BI Analyst | 12 years experience | SQL • Power BI • Process Automation

*All data is fictional. Structure based on real production system.*
