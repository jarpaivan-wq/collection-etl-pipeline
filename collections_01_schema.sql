-- =====================================================
-- COLLECTIONS MANAGEMENT DATABASE - SCHEMA
-- =====================================================
-- Purpose: Schema for debt collections and account management system
-- Database: SQLite
-- Author: Data Analytics Pipeline
-- =====================================================

-- =====================================================
-- STAGING TABLES
-- =====================================================

-- Collections Activity Staging Table
-- Stores raw collections activity data from daily CSV imports
DROP TABLE IF EXISTS stg_collections_activity;

CREATE TABLE stg_collections_activity (
    debtor_name VARCHAR(50),
    account_id INTEGER,
    activity_date TEXT(50),
    activity_time TEXT(50),
    next_activity_date TEXT(50),
    next_activity_time TEXT(50),
    collection_type VARCHAR(50),
    contact_type VARCHAR(50),
    contact_response VARCHAR(50),
    non_payment_reason VARCHAR(50),
    contact_location VARCHAR(50),
    next_action VARCHAR(50),
    comments VARCHAR(50),
    phone INTEGER,
    area_code INTEGER,
    committed_amount INTEGER,
    collector_name VARCHAR(50),
    address INTEGER,
    latitude VARCHAR(50),
    longitude VARCHAR(50),
    address_type VARCHAR(50)
);

-- Account Assignment Staging Table
-- Stores account portfolio assignments from daily CSV imports
DROP TABLE IF EXISTS stg_account_assignment;

CREATE TABLE stg_account_assignment (
    account_id INTEGER,
    check_digit INTEGER,
    debtor_name VARCHAR(100),
    total_debt VARCHAR(50),
    debt_tier VARCHAR(50),
    assignment_tier VARCHAR(50),
    branch VARCHAR(100)
);

-- =====================================================
-- ANALYTICAL VIEWS
-- =====================================================

-- Primary Collections Analytics View
-- Pre-aggregates collections data by account with activity metrics
DROP VIEW IF EXISTS vw_collections_summary;

CREATE VIEW vw_collections_summary AS
WITH prep_activities AS (
    SELECT
        account_id,
        DATE(
            SUBSTR(activity_date, 7, 4) || '-' ||
            SUBSTR(activity_date, 4, 2) || '-' ||
            SUBSTR(activity_date, 1, 2)
        ) AS activity_date,
        CASE 
            WHEN collection_type = 'PHONE' THEN '01.PHONE'
            WHEN collection_type IN ('BANK_REP', 'EMAIL') THEN '04.EMAIL'
            ELSE 'NOT_REGISTERED'
        END AS collection_type,
        CASE
            WHEN contact_type = 'PRIMARY' THEN '01.DIRECT'
            WHEN contact_type = 'THIRD_PARTY' THEN '02.INDIRECT'
            WHEN contact_type = 'FAMILY' THEN '02.INDIRECT'
            WHEN contact_type = 'NO_CONTACT' AND collector_name = 'AUTO_DIALER' THEN '04.DIALER'
            WHEN contact_type = 'NO_CONTACT' THEN '03.NO_CONTACT'
            WHEN contact_type = 'EMAIL' THEN 'EMAIL'
            ELSE 'NOT_REGISTERED'
        END AS contact_type,
        contact_response,
        non_payment_reason,
        collector_name
    FROM stg_collections_activity
),
activity_aggregation AS (
    SELECT
        account_id,
        COUNT(CASE WHEN collection_type = '03.SMS' THEN 1 END) AS total_sms,
        COUNT(CASE WHEN collection_type = '05.IVR' THEN 1 END) AS total_ivr,
        COUNT(CASE WHEN collection_type = '02.FIELD' THEN 1 END) AS total_field,
        COUNT(CASE WHEN collection_type = '06.LETTER' THEN 1 END) AS total_letter,
        COUNT(CASE WHEN collection_type = '04.EMAIL' THEN 1 END) AS total_email,
        COUNT(CASE WHEN collection_type = '01.PHONE' THEN 1 END) AS total_phone,
        COUNT(CASE WHEN contact_response = 'PAYMENT_PROMISE' THEN 1 END) AS total_promises,
        COUNT(CASE WHEN contact_type = '01.DIRECT' THEN 1 END) AS total_direct,
        COUNT(CASE WHEN contact_type = '02.INDIRECT' THEN 1 END) AS total_indirect,
        COUNT(CASE WHEN contact_type = '03.NO_CONTACT' THEN 1 END) AS total_no_contact,
        COUNT(CASE WHEN contact_type = '04.DIALER' THEN 1 END) AS total_dialer
    FROM prep_activities
    GROUP BY account_id
),
contact_flags AS (
    SELECT 
        account_id,
        CASE WHEN total_direct > 0 THEN 1 ELSE 0 END AS flag_direct,
        CASE WHEN total_indirect > 0 AND total_direct = 0 THEN 1 ELSE 0 END AS flag_indirect,
        CASE WHEN total_no_contact > 0 AND total_indirect = 0 AND total_direct = 0 THEN 1 ELSE 0 END AS flag_no_contact,
        CASE WHEN total_dialer > 0 AND total_no_contact = 0 AND total_indirect = 0 AND total_direct = 0 THEN 1 ELSE 0 END AS flag_dialer
    FROM activity_aggregation
),
ranked_activities AS (
    SELECT 
        account_id,
        activity_date,
        collection_type,
        contact_type,
        contact_response,
        non_payment_reason,
        collector_name,
        ROW_NUMBER() OVER(
            PARTITION BY account_id 
            ORDER BY collection_type ASC, contact_type ASC, activity_date DESC
        ) AS rn
    FROM prep_activities
)
SELECT
    ra.account_id,
    ra.activity_date,
    ra.collection_type,
    ra.contact_type,
    ra.contact_response,
    ra.non_payment_reason,
    ra.collector_name,
    COALESCE(aa.total_sms, 0) AS total_sms,
    COALESCE(aa.total_ivr, 0) AS total_ivr,
    COALESCE(aa.total_field, 0) AS total_field,
    COALESCE(aa.total_letter, 0) AS total_letter,
    COALESCE(aa.total_email, 0) AS total_email,
    COALESCE(aa.total_phone, 0) AS total_phone,
    COALESCE(aa.total_promises, 0) AS total_promises,
    COALESCE(aa.total_direct, 0) AS total_direct,
    COALESCE(aa.total_indirect, 0) AS total_indirect,
    COALESCE(aa.total_no_contact, 0) AS total_no_contact,
    COALESCE(aa.total_dialer, 0) AS total_dialer,
    COALESCE(
        aa.total_sms + aa.total_ivr + aa.total_field + 
        aa.total_letter + aa.total_email + aa.total_phone, 0
    ) AS total_activities,
    COALESCE(cf.flag_direct, 0) AS flag_direct,
    COALESCE(cf.flag_indirect, 0) AS flag_indirect,
    COALESCE(cf.flag_no_contact, 0) AS flag_no_contact,
    COALESCE(cf.flag_dialer, 0) AS flag_dialer,
    COALESCE(aa.total_direct + aa.total_indirect + aa.total_no_contact, 0) AS total_attempts
FROM ranked_activities ra
LEFT JOIN activity_aggregation aa ON ra.account_id = aa.account_id
LEFT JOIN contact_flags cf ON ra.account_id = cf.account_id
WHERE ra.rn = 1;
