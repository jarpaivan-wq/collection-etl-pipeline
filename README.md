# Collection Management ETL Pipeline

Automated data preprocessing pipeline for debt collection operations, reducing manual reporting time from 2 hours to 5 minutes.

## Overview

This ETL pipeline processes raw collection management data through a structured 3-layer architecture:
- **Staging Layer**: Preserves raw data integrity
- **Transformation Layer**: Applies business logic and data quality rules
- **Analytics Layer**: Produces analysis-ready datasets

## Business Impact

- ✅ **100% automated** - Zero manual intervention
- ✅ **2 hours → 5 minutes** - 96% reduction in processing time
- ✅ **Data quality guaranteed** - Built-in validation at each layer
- ✅ **Error elimination** - Removed manual cross-referencing errors

## Technical Stack

- **Database**: MySQL 8.0+
- **Key Techniques**: 
  - CTEs (Common Table Expressions)
  - Window Functions (ROW_NUMBER)
  - CASE-based classification
  - NULL handling with COALESCE
  - Multi-source data integration

## Pipeline Architecture

### 1. Staging Layer
```sql
-- Rename raw tables to preserve original data
ALTER TABLE assignments RENAME TO stg_assignments;
ALTER TABLE contacts RENAME TO stg_contacts;
```

### 2. Transformation Layer
- **clean_assignments**: Standardized assignment data
- **clean_contacts**: Enriched contact management data with aggregated metrics

### 3. Analytics Layer
Final joined dataset combining assignments with latest relevant contact information.

## Key Features

**Data Quality**
- NULL handling with COALESCE for reliable reporting
- Date standardization (DD/MM/YYYY → YYYY-MM-DD)
- Contact type classification (PRIMARY, THIRD_PARTY, NO_CONTACT, AUTO)

**Business Logic**
- Automated collection channel classification (PHONE, EMAIL, SMS, IVR, FIELD, MAIL)
- Contact effectiveness metrics per account
- Latest relevant contact identification using ROW_NUMBER

**Aggregations**
- Total contacts by channel (phone, SMS, email, IVR, field, mail)
- Payment promise tracking
- Contact type distribution (primary, third-party, no-contact, auto-dialer)

## Data Model

**Input Tables:**
- `stg_assignments`: Account assignments and financial details
- `stg_contacts`: Contact management records

**Output Views:**
- `clean_assignments`: Standardized assignment data
- `clean_contacts`: Enriched contact data with metrics

**Final Dataset**: Left join preserving all assignments with optional contact history

## Usage

```sql
-- Execute the full pipeline
source etl_pipeline.sql;

-- Query the final analytics dataset
SELECT * 
FROM clean_assignments a
LEFT JOIN clean_contacts c ON a.account_id = c.account_id
ORDER BY a.account_id ASC;
```

## Field Definitions

### Assignments Table
- `account_id`: Unique account identifier
- `account_checkdigit`: Verification digit for account ID
- `customer_name`: Customer full name
- `branch_code`: Branch/location code
- `agent_type`: Collection agent type/category
- `agent_name`: Assigned agent name
- `agent_email`: Agent contact email
- `legal_status`: Legal action status
- `risk_segment`: Risk classification segment
- `outstanding_balance`: Total debt amount
- `settlement_offer`: Single payment offer amount
- `discount_percentage`: Applied discount percentage
- `discount_amount`: Discount amount in currency
- `customer_city`: Customer city location

### Contacts Table (Transformed Output)
- `contact_date`: Date of contact attempt
- `collection_channel`: Channel used (PHONE, EMAIL, SMS, IVR, FIELD, MAIL)
- `contact_type`: Contact classification (PRIMARY, THIRD_PARTY, NO_CONTACT, AUTO)
- `contact_outcome`: Result of contact attempt
- `non_payment_reason`: Reason provided for non-payment
- `contact_agent`: Agent who made contact
- `total_*`: Aggregated counts by channel/type
- `total_contacts`: Total contact attempts across all channels

## Requirements

- MySQL 8.0 or higher
- Tables: `assignments` and `contacts` must exist before execution

## Installation

1. Clone this repository
```bash
git clone https://github.com/jarpaivan-wq/collection-etl-pipeline.git
cd collection-etl-pipeline
```

2. Execute the pipeline
```bash
mysql -u your_user -p your_database < etl_pipeline.sql
```

3. Verify execution
```sql
SELECT COUNT(*) FROM clean_assignments;
SELECT COUNT(*) FROM clean_contacts;
```

## Performance Considerations

- **Views over Tables**: Data changes frequently; views ensure real-time accuracy
- **Indexed Join Keys**: `account_id` column should be indexed on staging tables
- **Aggregation Once**: CTEs calculate metrics once, not per row
- **Efficient Window Functions**: ROW_NUMBER with proper PARTITION BY reduces query cost

## Data Quality Checks

```sql
-- Verify row counts match expectations
SELECT COUNT(*) FROM clean_assignments;
SELECT COUNT(*) FROM clean_contacts;

-- Check for NULL in critical fields
SELECT COUNT(*) FROM clean_assignments WHERE account_id IS NULL;

-- Validate date transformations
SELECT contact_date FROM clean_contacts LIMIT 10;

-- Verify aggregation logic
SELECT 
    account_id,
    total_contacts,
    total_phone + total_sms + total_email + total_ivr + total_field + total_mail AS calculated_total
FROM clean_contacts
WHERE total_contacts != calculated_total;
```

## Example Queries

### Top 10 Accounts by Contact Attempts
```sql
SELECT 
    a.account_id,
    a.customer_name,
    a.outstanding_balance,
    c.total_contacts,
    c.total_promises
FROM clean_assignments a
INNER JOIN clean_contacts c ON a.account_id = c.account_id
ORDER BY c.total_contacts DESC
LIMIT 10;
```

### Accounts with Payment Promises but No Recent Contact
```sql
SELECT 
    a.account_id,
    a.customer_name,
    c.total_promises,
    c.contact_date,
    DATEDIFF(CURDATE(), c.contact_date) AS days_since_contact
FROM clean_assignments a
INNER JOIN clean_contacts c ON a.account_id = c.account_id
WHERE c.total_promises > 0
  AND DATEDIFF(CURDATE(), c.contact_date) > 7
ORDER BY days_since_contact DESC;
```

### Channel Effectiveness Analysis
```sql
SELECT 
    c.collection_channel,
    COUNT(*) AS total_accounts,
    SUM(c.total_promises) AS total_promises,
    ROUND(SUM(c.total_promises) / COUNT(*) * 100, 2) AS promise_rate_pct
FROM clean_contacts c
GROUP BY c.collection_channel
ORDER BY promise_rate_pct DESC;
```

## Project Structure

```
collection-etl-pipeline/
├── README.md                 # This file
├── etl_pipeline.sql          # Main ETL script
├── docs/
│   └── PIPELINE_OVERVIEW.md  # Technical deep-dive
└── .gitignore                # Git ignore rules
```

## Future Enhancements

- [ ] Add error logging table for failed transformations
- [ ] Implement incremental processing (only new records)
- [ ] Add data quality metrics dashboard
- [ ] Create stored procedure wrapper for scheduled execution
- [ ] Add unit tests for transformation logic
- [ ] Implement data lineage tracking

## Contributing

This is a portfolio project demonstrating ETL design patterns. Suggestions for improvements are welcome via issues.

## Author

**Ivan Jarpa**  
Senior Data Analyst | SQL · ETL · Business Intelligence  
- LinkedIn: [linkedin.com/in/biexcel](https://linkedin.com/in/biexcel)
- GitHub: [github.com/jarpaivan-wq](https://github.com/jarpaivan-wq)
- Email: jarpa.ivan@gmail.com

## License

This project demonstrates ETL design patterns for portfolio purposes. The code structure and techniques are open for educational use. Sample data structure shown; actual business data removed for confidentiality.

---

**Keywords**: ETL Pipeline, MySQL, Data Engineering, SQL, Business Intelligence, Collection Management, Window Functions, CTEs, Data Quality, Automation
