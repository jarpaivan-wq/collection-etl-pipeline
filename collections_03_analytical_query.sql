-- =====================================================
-- COLLECTIONS PORTFOLIO ANALYTICAL REPORT
-- =====================================================
-- Purpose: Daily collections activity report with KPIs
-- Output: 80+ columns for executive reporting and BI integration
-- Usage: Run daily after importing fresh CSV data
-- =====================================================

/* 
WORKFLOW:
1. DELETE FROM stg_collections_activity;
2. DELETE FROM stg_account_assignment;  
3. Import updated CSV files via DBeaver (Import Data)
4. Execute this query to generate analytical report
*/

-- =====================================================
-- MAIN ANALYTICAL QUERY
-- =====================================================

SELECT
    -- Account Identifiers
    aa.account_id,
    aa.check_digit,
    
    -- Source Identification
    'COLLECTIONS' AS channel,
    'COMPANY_NAME' AS company,
    STRFTIME('%Y', 'now') AS year,
    STRFTIME('%m', 'now') AS month,
    STRFTIME('%d', 'now', '-1 days') AS day,
    aa.debtor_name,
    
    -- Portfolio Classification
    '' AS business_days_adjusted,
    'NO_INFO' AS division,
    'NO_INFO' AS branch_name,
    'CHARGE_OFF' AS portfolio_type,
    
    -- Collector Information (defaults when no activity match)
    'NO_MATCH' AS collector_name,
    'NO_MATCH' AS collector_type,
    'CHARGE_OFF_COLLECTIONS' AS collection_campaign,
    
    -- Contact Details
    '' AS retention_flag,
    'DEBTOR' AS contact_target,
    '' AS guarantor_id,
    '' AS guarantor_check_digit,
    
    -- Product Mix
    '' AS commercial_product,
    '' AS mortgage_product,
    '' AS consumer_product,
    
    -- Debt Information
    aa.debt_tier,
    CAST(REPLACE(REPLACE(aa.total_debt, '.', ''), '.', '') AS INTEGER) AS total_debt,
    aa.assignment_tier AS initial_tier,
    DATE('2026-02-02') AS assignment_date,
    
    -- Activity Classification (defaults for accounts without activity)
    'NO_MATCH' AS activity_type,
    'NO_MATCH' AS best_activity,
    'NO_MATCH' AS contact_type,
    'NO_MATCH' AS contact_response,
    'NO_MATCH' AS non_payment_reason,
    
    -- Payment Promises
    0 AS accounts_with_promise,
    0 AS balance_with_promise,
    0 AS promise_date,
    0 AS promises_kept,
    0 AS promises_taken,
    
    -- Location Data
    aa.branch AS activity_location,
    '' AS restructure_offer,
    
    -- Contact Metadata (defaults for no activity match)
    'NO_MATCH' AS area,
    'NO_MATCH' AS phone,
    'NO_MATCH' AS comments,
    '' AS email,
    '' AS address,
    'NO_MATCH' AS activity_time,
    'NO_MATCH' AS activity_date,
    'NO_MATCH' AS collector_id,
    'NO_MATCH' AS operation_id,
    
    -- Product Type
    '04.CHARGE_OFF' AS product_type,
    '' AS geographic_zone,
    '' AS commercial_zone,
    
    -- Activity Counters by Channel
    COALESCE(cs.total_sms, 0) AS q_sms,
    COALESCE(cs.total_ivr, 0) AS q_ivr,
    0 AS restructure_count,
    COALESCE(cs.total_field, 0) AS q_field_visit,
    COALESCE(cs.total_letter, 0) AS q_letters,
    COALESCE(cs.total_email, 0) AS q_email,
    COALESCE(cs.total_phone, 0) AS q_phone,
    
    -- Payment Promises Detail
    0 AS q_payment_promise,
    0 AS q_promise_activity,
    
    -- Contact Quality Flags
    COALESCE(cs.flag_direct, 0) AS q_direct_contact,
    COALESCE(cs.flag_indirect, 0) AS q_indirect_contact,
    COALESCE(cs.flag_no_contact, 0) AS q_no_contact,
    COALESCE(cs.flag_dialer, 0) AS q_dialer,
    
    -- Phone Activity Flag (1 if account has zero phone attempts)
    CASE
        WHEN COALESCE(cs.total_phone, 0) = 0 THEN 1
        ELSE 0
    END AS q_no_phone_activity,
    
    -- Best Contact Type
    COALESCE(cs.contact_type, '05.NO_PHONE') AS contact_classification,
    
    -- Account Metrics
    1 AS account_count,
    0 AS contained_operations,
    0 AS contained_amount,
    0 AS contained_ops_factoring,
    0 AS inhibited_cases,
    0 AS active_cases,
    0 AS decanting_payments,
    0 AS promise_cases,
    0 AS promise_kept_cases,
    0 AS promise_kept_contained,
    
    -- Activity Summary
    COALESCE(cs.total_activities, 0) AS total_activities,
    COALESCE(cs.total_direct, 0) AS total_direct_contact,
    COALESCE(cs.total_indirect, 0) AS total_indirect_contact,
    COALESCE(cs.total_no_contact, 0) AS total_no_contact,
    COALESCE(cs.total_dialer, 0) AS total_dialer,
    
    -- Additional Flags
    0 AS guarantor_flag,
    0 AS whatsapp_flag,
    1 AS unique_account_id,
    1 AS unique_operation,
    'NO_MATCH' AS primary_key,
    
    -- Goals & Targets
    0 AS containment_goal,
    0 AS operation_goal_amount,
    aa.debt_tier AS account_tier_carryover,
    0 AS amount_goal,
    0 AS contained_account_id,
    aa.total_debt AS debt_carryover,
    aa.total_debt AS debt_total,
    0 AS contained_amount_carryover,
    aa.assignment_tier AS debt_tier,
    
    -- Status
    'ACTIVE' AS status,
    COALESCE(cs.total_attempts, 0) AS total_contact_attempts

FROM stg_account_assignment aa
LEFT JOIN vw_collections_summary cs
    ON aa.account_id = cs.account_id;

-- =====================================================
-- QUERY NOTES
-- =====================================================
/*
TECHNICAL NOTES:

1. NULL Handling:
   - COALESCE used extensively to handle accounts without activity
   - Critical for q_no_phone_activity flag logic
   
2. LEFT JOIN Strategy:
   - All assigned accounts included even without activity
   - Enables reporting on "not yet contacted" portfolio segment
   
3. Column Structure:
   - 80+ columns meet corporate reporting requirements
   - Many default values ('NO_MATCH', 'NO_INFO', 0) indicate 
     data not available in source systems
   - Structure required for BI tool integration
   
4. Performance:
   - View (vw_collections_summary) pre-aggregates activity data
   - Single LEFT JOIN to main assignment table
   - Runs in <1 second for 10K+ accounts
   
5. Business Logic Examples:
   - q_no_phone_activity: Flags accounts never contacted by phone
     (1 if total_phone is 0 or NULL, else 0)
   - contact_classification: Best contact achieved for the account
     (ranked by contact quality in view's ROW_NUMBER)
   - debt_tier: Standardized debt buckets for portfolio analysis

BUSINESS CONTEXT:

This report structure is designed for:
- Daily executive dashboards
- Collection team performance tracking
- Portfolio risk assessment
- Regulatory compliance reporting
- Integration with enterprise BI systems

The seemingly redundant columns (e.g., debt_total, debt_carryover) 
serve specific purposes in downstream systems and historical 
trend analysis.
*/
