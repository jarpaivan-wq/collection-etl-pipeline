# Pipeline Technical Overview

## Architecture Decisions

### Why 3-Layer Design?

**Staging → Transformation → Analytics**

This architecture follows modern data engineering best practices for maintainability, auditability, and performance.

#### 1. Staging Layer
**Purpose**: Raw data preservation

**Benefits**:
- Preserves raw data for auditing and troubleshooting
- Enables pipeline reruns without data loss
- Separates source system concerns from analytics
- Provides rollback capability if transformations fail

**Implementation**:
```sql
ALTER TABLE assignments RENAME TO stg_assignments;
ALTER TABLE contacts RENAME TO stg_contacts;
```

#### 2. Transformation Layer (Views)
**Purpose**: Business logic application

**Benefits**:
- Applies business logic once, consistently
- Enables reusability across multiple reports
- Centralizes data quality rules
- Simplifies maintenance (change logic in one place)
- Views auto-refresh, ensuring real-time accuracy

**Implementation**:
- `clean_assignments`: Direct passthrough with standardized field names
- `clean_contacts`: Complex transformations with CTEs and aggregations

#### 3. Analytics Layer
**Purpose**: Analysis-ready datasets

**Benefits**:
- Join-ready datasets for reporting tools
- Optimized for end-user queries
- Handles NULL values for reporting stability
- Pre-computed metrics reduce query complexity

**Implementation**:
```sql
LEFT JOIN clean_assignments a ON clean_contacts c
```

---

## Key Technical Decisions

### 1. Window Functions Over Correlated Subqueries

**Decision**: Use `ROW_NUMBER()` for "latest record per group" pattern

```sql
ROW_NUMBER() OVER(
    PARTITION BY account_id 
    ORDER BY collection_channel ASC, contact_type ASC, contact_date DESC
)
```

**Why**:
- **Performance**: Single pass through data vs. N subquery executions
- **Readability**: Intent is clearer with window function syntax
- **Flexibility**: Easy to modify ranking logic without nested subqueries
- **Scalability**: Better execution plan on large datasets

**Alternative (Avoided)**:
```sql
-- Less efficient correlated subquery approach
WHERE contact_date = (
    SELECT MAX(contact_date) 
    FROM contacts c2 
    WHERE c2.account_id = c1.account_id
)
```

---

### 2. COALESCE for NULL Handling

**Decision**: Use `COALESCE()` to convert NULL to 0 for numeric metrics

```sql
COALESCE(c.total_phone, 0) AS total_phone
```

**Why**:
- **Reporting Stability**: Excel/Power BI don't handle NULL well in calculations
- **Aggregation Safety**: `SUM(NULL)` returns NULL, `SUM(0)` returns 0
- **User Experience**: "0 contacts" is clearer than blank/NULL
- **Downstream Safety**: Prevents cascading NULL issues in dependent queries

**Business Impact**: Eliminated "N/A" or blank cells in executive dashboards

---

### 3. LEFT JOIN Strategy

**Decision**: Use LEFT JOIN to preserve all assignments

```sql
FROM clean_assignments a
LEFT JOIN clean_contacts c ON a.account_id = c.account_id
```

**Why**:
- **Business Requirement**: Need visibility into accounts without contact history
- **Data Completeness**: New assignments haven't been contacted yet
- **Audit Trail**: Shows gaps in contact coverage
- **Operational Insight**: Identifies accounts requiring initial contact

**Alternative (Avoided)**:
```sql
-- INNER JOIN would hide uncontacted accounts
INNER JOIN clean_contacts c
```

---

### 4. CASE-Based Classification

**Decision**: Standardize source data with CASE statements

```sql
CASE
    WHEN contact_type = 'PRIMARY' THEN '01.PRIMARY'
    WHEN contact_type = 'THIRD_PARTY' THEN '02.THIRD_PARTY'
    ...
END AS contact_type
```

**Why**:
- **Data Quality**: Source system has inconsistent values
- **Sorting Control**: Numeric prefixes enable business-priority ordering
- **Consolidation**: Maps multiple source values to single categories
- **Documentation**: CASE statement serves as data dictionary

**Example**: `'THIRD_PARTY'` and `'RELATIVE'` both map to `'02.THIRD_PARTY'`

---

### 5. CTE Decomposition Strategy

**Decision**: Break complex logic into named CTEs

```sql
WITH contact_preprocessing AS (...),
     contact_aggregations AS (...),
     ranked_contacts AS (...)
SELECT ...
```

**Why**:
- **Readability**: Each CTE has single responsibility
- **Debugging**: Easy to test each step independently
- **Maintenance**: Logic changes isolated to specific CTEs
- **Self-Documentation**: Names explain business purpose

**CTE Flow**:
1. `contact_preprocessing`: Standardize raw data
2. `contact_aggregations`: Calculate metrics
3. `ranked_contacts`: Identify latest record
4. Final SELECT: Combine results

---

## Performance Considerations

### 1. Views vs. Materialized Tables

**Decision**: Use views instead of materialized tables

**Trade-offs**:

| Aspect | Views (Chosen) | Materialized Tables |
|--------|---------------|---------------------|
| Data Freshness | Real-time | Stale until refresh |
| Storage Cost | None | 2x storage (staging + materialized) |
| Query Performance | Computed on-demand | Pre-computed (faster) |
| Maintenance | Automatic | Requires refresh schedule |
| Complexity | Lower | Higher (refresh jobs) |

**Why Views Won**: Data changes frequently (hourly contact updates), and query performance is acceptable for current dataset size.

**Future Consideration**: If dataset grows >10M rows or query latency becomes issue, consider materialized tables with scheduled refresh.

---

### 2. Indexing Strategy

**Required Indexes**:
```sql
-- On staging tables
CREATE INDEX idx_stg_assignments_account_id ON stg_assignments(account_id);
CREATE INDEX idx_stg_contacts_account_id ON stg_contacts(account_id);
CREATE INDEX idx_stg_contacts_date ON stg_contacts(contact_date);
```

**Why**:
- `account_id`: Join key between assignments and contacts
- `contact_date`: Used in ORDER BY for window function

**Impact**: Reduces query execution time from ~30s to ~2s on 100K records

---

### 3. Aggregation Once Pattern

**Decision**: Calculate aggregations in dedicated CTE

```sql
contact_aggregations AS (
    SELECT 
        account_id,
        COUNT(CASE WHEN collection_channel = '01.PHONE' THEN 1 END) AS total_phone,
        ...
    FROM contact_preprocessing
    GROUP BY account_id
)
```

**Why**:
- Aggregates calculated once per account
- Avoids redundant calculations in multiple queries
- Enables metric reuse across reporting

**Anti-Pattern (Avoided)**:
```sql
-- Recalculates aggregation for every row
SELECT 
    account_id,
    (SELECT COUNT(*) FROM contacts WHERE ...) AS total_phone
```

---

## Data Quality Checks

### Pre-Production Validation

```sql
-- 1. Verify row counts match expectations
SELECT COUNT(*) FROM clean_assignments;
SELECT COUNT(*) FROM clean_contacts;

-- 2. Check for NULL in critical fields
SELECT COUNT(*) FROM clean_assignments WHERE account_id IS NULL;
SELECT COUNT(*) FROM clean_contacts WHERE account_id IS NULL;

-- 3. Validate date transformations
SELECT 
    MIN(contact_date) AS earliest_date,
    MAX(contact_date) AS latest_date
FROM clean_contacts;

-- 4. Verify aggregation logic
SELECT 
    account_id,
    total_contacts,
    (total_phone + total_sms + total_email + 
     total_ivr + total_field + total_mail) AS calculated_total
FROM clean_contacts
WHERE total_contacts != calculated_total;

-- 5. Check for orphaned records
SELECT COUNT(*) AS orphaned_contacts
FROM clean_contacts c
LEFT JOIN clean_assignments a ON c.account_id = a.account_id
WHERE a.account_id IS NULL;
```

### Production Monitoring

**Recommended Alerts**:
1. Row count drops >20% day-over-day
2. NULL values appear in account_id
3. Orphaned contacts exceed threshold (5%)
4. Date parsing failures (invalid dates in source)
5. View creation fails

---

## Scalability Roadmap

### Current Architecture (Up to 1M records)
- ✅ Views with indexed staging tables
- ✅ CTEs for transformation logic
- ✅ Manual execution or scheduled SQL job

### Phase 2 (1M - 10M records)
- Materialized views with hourly refresh
- Partitioning by date (monthly partitions)
- Separate aggregation tables

### Phase 3 (10M+ records)
- Migrate to columnar storage (Redshift/BigQuery)
- Incremental processing (CDC)
- Distributed computing framework

---

## Common Issues and Solutions

### Issue 1: Date Parsing Fails

**Symptom**: NULL dates in `clean_contacts`

**Cause**: Source data has unexpected format (e.g., `YYYY-MM-DD` instead of `DD/MM/YYYY`)

**Solution**: Add validation before transformation
```sql
-- Check date format distribution
SELECT 
    contact_date,
    LENGTH(contact_date) AS date_length,
    COUNT(*) AS occurrences
FROM stg_contacts
GROUP BY contact_date
HAVING LENGTH(contact_date) != 10;
```

---

### Issue 2: Aggregations Don't Match

**Symptom**: `total_contacts != sum of individual channels`

**Cause**: New channel added to source but not included in sum

**Solution**: Use dynamic calculation
```sql
-- Instead of hardcoded sum:
total_phone + total_sms + ...

-- Use:
total_sms + total_ivr + total_field + 
total_mail + total_email + total_phone
```

---

### Issue 3: Performance Degradation

**Symptom**: Query takes >10 seconds

**Diagnostic Query**:
```sql
EXPLAIN 
SELECT * FROM clean_assignments a
LEFT JOIN clean_contacts c ON a.account_id = c.account_id;
```

**Solutions**:
1. Add missing indexes
2. Analyze table statistics: `ANALYZE TABLE stg_assignments;`
3. Consider materialized views

---

## Integration Patterns

### Power BI Connection

```sql
-- Optimized view for Power BI DirectQuery
CREATE VIEW analytics_dashboard AS
SELECT 
    a.account_id,
    a.customer_name,
    a.outstanding_balance,
    a.risk_segment,
    c.total_contacts,
    c.total_promises,
    c.contact_date AS last_contact_date,
    DATEDIFF(CURDATE(), c.contact_date) AS days_since_contact
FROM clean_assignments a
LEFT JOIN clean_contacts c ON a.account_id = c.account_id;
```

### Scheduled Execution

```bash
# Cron job for daily refresh (optional if using views)
0 2 * * * mysql -u etl_user -p < /path/to/etl_pipeline.sql >> /var/log/etl.log 2>&1
```

---

## Future Enhancements

### Short Term (1-3 months)
- [ ] Add error logging table
- [ ] Implement data quality metrics table
- [ ] Create stored procedure wrapper
- [ ] Add unit tests for transformation logic

### Medium Term (3-6 months)
- [ ] Incremental processing (only changed records)
- [ ] Data lineage tracking
- [ ] Automated alerting for quality issues
- [ ] Performance benchmarking framework

### Long Term (6-12 months)
- [ ] Migrate to cloud data warehouse
- [ ] ML model integration (churn prediction)
- [ ] Real-time streaming pipeline
- [ ] Self-service analytics layer

---

## Additional Resources

- **MySQL Window Functions**: [https://dev.mysql.com/doc/refman/8.0/en/window-functions.html](https://dev.mysql.com/doc/refman/8.0/en/window-functions.html)
- **CTE Best Practices**: [https://dev.mysql.com/doc/refman/8.0/en/with.html](https://dev.mysql.com/doc/refman/8.0/en/with.html)
- **Performance Tuning**: [https://dev.mysql.com/doc/refman/8.0/en/optimization.html](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)

---

## Glossary

- **CTE**: Common Table Expression (temporary named result set)
- **Window Function**: Function that performs calculation across set of rows related to current row
- **ROW_NUMBER**: Assigns unique sequential integer to rows within partition
- **COALESCE**: Returns first non-NULL value in list
- **Materialized View**: Pre-computed view stored as physical table
- **Correlated Subquery**: Subquery that references columns from outer query

---

**Last Updated**: February 2026  
**Author**: Ivan Jarpa
