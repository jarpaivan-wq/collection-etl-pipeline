-- ============================================================
-- COLLECTION MANAGEMENT ETL PIPELINE
-- ============================================================
-- Author: Ivan Jarpa
-- Purpose: Automated preprocessing of collection management data
-- Database: MySQL 8.0+
-- Impact: Reduces manual processing from 2 hours to 5 minutes
-- GitHub: github.com/jarpaivan-wq/collection-etl-pipeline
-- ============================================================

-- ============================================================
-- LAYER 1: STAGING
-- Purpose: Preserve raw data integrity
-- ============================================================

-- Rename raw tables to staging layer
-- This preserves original data and enables pipeline reruns
ALTER TABLE assignments RENAME TO stg_assignments;
ALTER TABLE contacts RENAME TO stg_contacts;

-- ============================================================
-- LAYER 2: TRANSFORMATION - Assignment Data
-- ============================================================
-- Business Purpose: Standardize account assignment information
-- Data Quality: Direct passthrough from staging (validation upstream)
-- Output: Clean, standardized assignment records
-- ============================================================

CREATE VIEW clean_assignments AS
SELECT
    account_id,
    account_checkdigit,
    customer_name,
    branch_code,
    agent_type,
    agent_name,
    agent_email,
    legal_status,
    risk_segment,
    outstanding_balance,
    settlement_offer,
    discount_percentage,
    discount_amount,
    customer_city
FROM stg_assignments;

-- Validation check
SELECT COUNT(*) AS total_records FROM clean_assignments;

-- ============================================================
-- LAYER 2: TRANSFORMATION - Contact Management Data
-- ============================================================
-- Business Purpose: Enrich contact records with aggregated metrics
-- Key Features:
--   - Date standardization (DD/MM/YYYY → YYYY-MM-DD)
--   - Contact type classification
--   - Channel aggregation metrics
--   - Latest relevant contact identification
-- Output: One row per account with latest contact + full history metrics
-- ============================================================

CREATE VIEW clean_contacts AS
WITH contact_preprocessing AS (
    -- Step 1: Standardize and classify contact records
    -- Transforms raw contact data into consistent, categorized format
    SELECT
        account_id,
        -- Date transformation: DD/MM/YYYY → YYYY-MM-DD (ISO format)
        DATE(
            SUBSTR(contact_date,7,4) || '-' ||
            SUBSTR(contact_date,4,2) || '-' ||
            SUBSTR(contact_date,1,2)
        ) AS contact_date,
        -- Collection channel classification
        -- Standardizes channel names and adds priority prefixes for sorting
        CASE
            WHEN collection_channel = 'PHONE' THEN '01.PHONE'
            WHEN collection_channel IN('AGENT','EMAIL') THEN '04.EMAIL'
            WHEN collection_channel = 'SMS' THEN '03.SMS'
            WHEN collection_channel = 'IVR' THEN '05.IVR'
            WHEN collection_channel = 'FIELD' THEN '02.FIELD'
            WHEN collection_channel = 'MAIL' THEN '06.MAIL'
        END AS collection_channel,
        -- Contact type standardization
        -- Classifies contacts by who was reached and how
        CASE
            WHEN contact_type = 'PRIMARY' THEN '01.PRIMARY'
            WHEN contact_type = 'THIRD_PARTY' THEN '02.THIRD_PARTY'
            WHEN contact_type = 'RELATIVE' THEN '02.THIRD_PARTY'
            WHEN contact_type = 'NO_CONTACT' AND contact_agent = 'AUTO_DIALER' THEN '04.AUTO'
            WHEN contact_type = 'NO_CONTACT' THEN '03.NO_CONTACT'
            WHEN contact_type = 'EMAIL' THEN 'EMAIL'
            ELSE 'UNCLASSIFIED'
        END AS contact_type,
        contact_outcome,
        non_payment_reason,
        contact_agent
    FROM stg_contacts
),
contact_aggregations AS (
    -- Step 2: Aggregate contact metrics by account
    -- Calculates total attempts per channel and contact type
    SELECT
        account_id,
        COUNT(CASE WHEN collection_channel = '03.SMS' THEN 1 END) AS total_sms,
        COUNT(CASE WHEN collection_channel = '05.IVR' THEN 1 END) AS total_ivr,
        COUNT(CASE WHEN collection_channel = '02.FIELD' THEN 1 END) AS total_field,
        COUNT(CASE WHEN collection_channel = '06.MAIL' THEN 1 END) AS total_mail,
        COUNT(CASE WHEN collection_channel = '04.EMAIL' THEN 1 END) AS total_email,
        COUNT(CASE WHEN collection_channel = '01.PHONE' THEN 1 END) AS total_phone,
        COUNT(CASE WHEN contact_outcome = 'PAYMENT_PROMISE' THEN 1 END) AS total_promises,
        COUNT(CASE WHEN contact_type = '01.PRIMARY' THEN 1 END) AS total_primary,
        COUNT(CASE WHEN contact_type = '02.THIRD_PARTY' THEN 1 END) AS total_third_party,
        COUNT(CASE WHEN contact_type = '03.NO_CONTACT' THEN 1 END) AS total_no_contact,
        COUNT(CASE WHEN contact_type = '04.AUTO' THEN 1 END) AS total_auto_dialer
    FROM contact_preprocessing
    GROUP BY account_id
),
ranked_contacts AS (
    -- Step 3: Identify latest relevant contact per account
    -- Logic: Prioritize by channel effectiveness, then contact type, then recency
    -- ROW_NUMBER ensures exactly one row per account
    SELECT 
        account_id,
        contact_date,
        collection_channel,
        contact_type,
        contact_outcome,
        non_payment_reason,
        contact_agent,
        ROW_NUMBER() OVER(
            PARTITION BY account_id 
            ORDER BY collection_channel ASC, contact_type ASC, contact_date DESC
        ) AS row_num
    FROM contact_preprocessing
)
-- Final output: Latest contact details + aggregated metrics
-- COALESCE ensures NULL-safe numeric values for reporting
SELECT
    rc.account_id,
    rc.contact_date,
    rc.collection_channel,
    rc.contact_type,
    rc.contact_outcome,
    rc.non_payment_reason,
    rc.contact_agent,
    COALESCE(ca.total_sms,0) AS total_sms,
    COALESCE(ca.total_ivr,0) AS total_ivr,
    COALESCE(ca.total_field,0) AS total_field,
    COALESCE(ca.total_mail,0) AS total_mail,
    COALESCE(ca.total_email,0) AS total_email,
    COALESCE(ca.total_phone,0) AS total_phone,
    COALESCE(ca.total_promises,0) AS total_promises,
    COALESCE(ca.total_primary,0) AS total_primary,
    COALESCE(ca.total_third_party,0) AS total_third_party,
    COALESCE(ca.total_no_contact,0) AS total_no_contact,
    COALESCE(ca.total_auto_dialer,0) AS total_auto_dialer,
    COALESCE(
        ca.total_sms + ca.total_ivr + ca.total_field + 
        ca.total_mail + ca.total_email + ca.total_phone, 0
    ) AS total_contacts
FROM ranked_contacts rc
LEFT JOIN contact_aggregations ca ON rc.account_id = ca.account_id
WHERE rc.row_num = 1;

-- Validation check
SELECT COUNT(*) AS total_records FROM clean_contacts;

-- ============================================================
-- LAYER 3: ANALYTICS - Final Dataset
-- ============================================================
-- Business Purpose: Unified view of assignments with contact history
-- Join Strategy: LEFT JOIN preserves all assignments (even without contacts)
-- Data Quality: COALESCE handles missing contact metrics
-- Use Case: Executive dashboards, operational reports, agent performance
-- ============================================================

/* 
Example query for final analytics dataset:

This query combines all assignment data with contact history,
ensuring every account appears even if they have no contact records.

SELECT
    a.account_id,
    a.account_checkdigit,
    a.customer_name,
    a.branch_code,
    a.agent_type,
    a.agent_name,
    a.agent_email,
    a.legal_status,
    a.risk_segment,
    a.outstanding_balance,
    a.settlement_offer,
    a.discount_percentage,
    a.discount_amount,
    a.customer_city,
    COALESCE(c.contact_date, 'no_contact') AS contact_date,
    COALESCE(c.collection_channel, 'no_contact') AS collection_channel,
    COALESCE(c.contact_type, 'no_contact') AS contact_type,
    COALESCE(c.contact_outcome, 'no_contact') AS contact_outcome,
    COALESCE(c.non_payment_reason, 'no_contact') AS non_payment_reason,
    COALESCE(c.contact_agent, 'no_contact') AS contact_agent,
    COALESCE(c.total_sms,0) AS total_sms,
    COALESCE(c.total_ivr,0) AS total_ivr,
    COALESCE(c.total_field,0) AS total_field,
    COALESCE(c.total_mail,0) AS total_mail,
    COALESCE(c.total_email,0) AS total_email,
    COALESCE(c.total_phone,0) AS total_phone,
    COALESCE(c.total_promises,0) AS total_promises,
    COALESCE(c.total_primary,0) AS total_primary,
    COALESCE(c.total_third_party,0) AS total_third_party,
    COALESCE(c.total_no_contact,0) AS total_no_contact,
    COALESCE(c.total_auto_dialer,0) AS total_auto_dialer,
    COALESCE(c.total_contacts,0) AS total_contacts
FROM clean_assignments a
LEFT JOIN clean_contacts c ON a.account_id = c.account_id
ORDER BY a.account_id ASC;
*/

-- ============================================================
-- ADDITIONAL EXAMPLE QUERIES
-- ============================================================

-- Example 1: Accounts with high contact attempts but no promises
/*
SELECT 
    a.account_id,
    a.customer_name,
    a.outstanding_balance,
    c.total_contacts,
    c.total_promises,
    c.collection_channel AS last_channel,
    c.contact_date AS last_contact_date
FROM clean_assignments a
INNER JOIN clean_contacts c ON a.account_id = c.account_id
WHERE c.total_contacts >= 5
  AND c.total_promises = 0
ORDER BY c.total_contacts DESC;
*/

-- Example 2: Channel effectiveness by promise conversion
/*
SELECT 
    c.collection_channel,
    COUNT(DISTINCT c.account_id) AS accounts_contacted,
    SUM(c.total_promises) AS total_promises_made,
    ROUND(AVG(c.total_promises), 2) AS avg_promises_per_account,
    ROUND(SUM(c.total_promises) / COUNT(DISTINCT c.account_id) * 100, 2) AS promise_conversion_rate_pct
FROM clean_contacts c
GROUP BY c.collection_channel
ORDER BY promise_conversion_rate_pct DESC;
*/

-- Example 3: Accounts requiring follow-up (promises made but old last contact)
/*
SELECT 
    a.account_id,
    a.customer_name,
    a.agent_name AS assigned_agent,
    c.total_promises,
    c.contact_date AS last_contact,
    DATEDIFF(CURDATE(), c.contact_date) AS days_since_contact,
    a.outstanding_balance
FROM clean_assignments a
INNER JOIN clean_contacts c ON a.account_id = c.account_id
WHERE c.total_promises > 0
  AND DATEDIFF(CURDATE(), c.contact_date) > 7
ORDER BY days_since_contact DESC, a.outstanding_balance DESC;
*/

-- ============================================================
-- DATA QUALITY VALIDATION QUERIES
-- ============================================================

-- Check for orphaned contacts (contacts without assignments)
/*
SELECT COUNT(*) AS orphaned_contacts
FROM clean_contacts c
LEFT JOIN clean_assignments a ON c.account_id = a.account_id
WHERE a.account_id IS NULL;
*/

-- Verify aggregation logic consistency
/*
SELECT 
    account_id,
    total_contacts,
    (total_phone + total_sms + total_email + total_ivr + total_field + total_mail) AS calculated_total
FROM clean_contacts
WHERE total_contacts != (total_phone + total_sms + total_email + total_ivr + total_field + total_mail);
*/

-- Check for NULL critical fields
/*
SELECT 
    'clean_assignments' AS table_name,
    COUNT(*) AS null_account_ids
FROM clean_assignments
WHERE account_id IS NULL
UNION ALL
SELECT 
    'clean_contacts' AS table_name,
    COUNT(*) AS null_account_ids
FROM clean_contacts
WHERE account_id IS NULL;
*/

-- ============================================================
-- END OF ETL PIPELINE
-- ============================================================
-- Next Steps:
-- 1. Schedule this pipeline to run daily/hourly based on data refresh needs
-- 2. Add error logging table for production monitoring
-- 3. Create Power BI/Tableau connection to clean_assignments + clean_contacts
-- 4. Set up alerts for data quality check failures
-- ============================================================
