-- =====================================================
-- COLLECTIONS MANAGEMENT DATABASE - SAMPLE DATA
-- =====================================================
-- Purpose: Sample dataset for testing collections analytics
-- Note: All data is fictional and for demonstration purposes
-- =====================================================

-- =====================================================
-- ACCOUNT ASSIGNMENT DATA
-- =====================================================

INSERT INTO stg_account_assignment (account_id, check_digit, debtor_name, total_debt, debt_tier, assignment_tier, branch)
VALUES
    (12345678, 9, 'ACME Corporation Ltd', '5.250.000', 'T3: 3M-5M', 'T3: 3M-5M', 'Central Branch'),
    (23456789, 0, 'Global Services Inc', '8.750.000', 'T4: 5M-10M', 'T4: 5M-10M', 'North Branch'),
    (34567890, 1, 'Tech Solutions SA', '2.100.000', 'T2: 1M-3M', 'T2: 1M-3M', 'South Branch'),
    (45678901, 2, 'Retail Partners Co', '1.500.000', 'T2: 1M-3M', 'T2: 1M-3M', 'East Branch'),
    (56789012, 3, 'Manufacturing Plus', '12.500.000', 'T5: >10M', 'T5: >10M', 'Central Branch'),
    (67890123, 4, 'Logistics Express', '750.000', 'T1: <1M', 'T1: <1M', 'West Branch'),
    (78901234, 5, 'Digital Marketing Pro', '4.250.000', 'T3: 3M-5M', 'T3: 3M-5M', 'North Branch');

-- =====================================================
-- COLLECTIONS ACTIVITY DATA
-- =====================================================

-- Account 12345678 - Multiple phone contacts with payment promises
INSERT INTO stg_collections_activity 
(debtor_name, account_id, activity_date, activity_time, next_activity_date, next_activity_time, 
 collection_type, contact_type, contact_response, non_payment_reason, contact_location, 
 next_action, comments, phone, area_code, committed_amount, collector_name, 
 address, latitude, longitude, address_type)
VALUES
    ('ACME Corporation Ltd', 12345678, '15/02/2026', '09:30', '20/02/2026', '10:00', 
     'PHONE', 'PRIMARY', 'PAYMENT_PROMISE', 'CASH_FLOW', 'OFFICE', 
     'FOLLOW_UP', 'Committed to pay 50% by Friday', 912345678, 56, 2625000, 'John Smith',
     1, '-33.4489', '-70.6693', 'BUSINESS'),
    ('ACME Corporation Ltd', 12345678, '10/02/2026', '14:15', '15/02/2026', '09:00',
     'PHONE', 'PRIMARY', 'WILL_EVALUATE', 'AWAITING_PAYMENT', 'OFFICE',
     'CALL_BACK', 'Requested time to review outstanding balance', 912345678, 56, 0, 'John Smith',
     1, '-33.4489', '-70.6693', 'BUSINESS'),
    ('ACME Corporation Ltd', 12345678, '05/02/2026', '11:00', '10/02/2026', '14:00',
     'EMAIL', 'PRIMARY', 'NO_RESPONSE', NULL, 'EMAIL',
     'PHONE_CALL', 'Sent payment reminder email', 912345678, 56, 0, 'John Smith',
     1, '-33.4489', '-70.6693', 'BUSINESS');

-- Account 23456789 - Mix of contacts, some no-contact scenarios
INSERT INTO stg_collections_activity 
(debtor_name, account_id, activity_date, activity_time, next_activity_date, next_activity_time,
 collection_type, contact_type, contact_response, non_payment_reason, contact_location,
 next_action, comments, phone, area_code, committed_amount, collector_name,
 address, latitude, longitude, address_type)
VALUES
    ('Global Services Inc', 23456789, '18/02/2026', '16:45', '22/02/2026', '09:30',
     'PHONE', 'THIRD_PARTY', 'WILL_INFORM', 'OUT_OF_OFFICE', 'RECEPTION',
     'WAIT_CALLBACK', 'Spoke with secretary, will pass message', 923456789, 56, 0, 'Maria Garcia',
     2, '-33.4372', '-70.6506', 'BUSINESS'),
    ('Global Services Inc', 23456789, '12/02/2026', '10:20', '18/02/2026', '16:00',
     'PHONE', 'NO_CONTACT', 'NO_ANSWER', NULL, 'PHONE',
     'RETRY', 'No answer after 3 attempts', 923456789, 56, 0, 'Maria Garcia',
     2, '-33.4372', '-70.6506', 'BUSINESS'),
    ('Global Services Inc', 23456789, '08/02/2026', '15:30', '12/02/2026', '10:00',
     'EMAIL', 'PRIMARY', 'NO_RESPONSE', NULL, 'EMAIL',
     'PHONE_CALL', 'Sent formal notice', 923456789, 56, 0, 'Maria Garcia',
     2, '-33.4372', '-70.6506', 'BUSINESS');

-- Account 34567890 - Successful direct contact with payment promise
INSERT INTO stg_collections_activity
(debtor_name, account_id, activity_date, activity_time, next_activity_date, next_activity_time,
 collection_type, contact_type, contact_response, non_payment_reason, contact_location,
 next_action, comments, phone, area_code, committed_amount, collector_name,
 address, latitude, longitude, address_type)
VALUES
    ('Tech Solutions SA', 34567890, '19/02/2026', '11:15', '25/02/2026', '11:00',
     'PHONE', 'PRIMARY', 'PAYMENT_PROMISE', 'TEMPORARY_ISSUES', 'MOBILE',
     'VERIFY_PAYMENT', 'Confirmed payment for full amount by Feb 25', 934567890, 56, 2100000, 'Carlos Ruiz',
     3, '-33.4569', '-70.6483', 'BUSINESS'),
    ('Tech Solutions SA', 34567890, '14/02/2026', '09:45', '19/02/2026', '11:00',
     'PHONE', 'PRIMARY', 'WILL_EVALUATE', 'NEEDS_APPROVAL', 'OFFICE',
     'FOLLOW_UP', 'Will confirm payment date after board meeting', 934567890, 56, 0, 'Carlos Ruiz',
     3, '-33.4569', '-70.6483', 'BUSINESS');

-- Account 45678901 - No contact attempts
INSERT INTO stg_collections_activity
(debtor_name, account_id, activity_date, activity_time, next_activity_date, next_activity_time,
 collection_type, contact_type, contact_response, non_payment_reason, contact_location,
 next_action, comments, phone, area_code, committed_amount, collector_name,
 address, latitude, longitude, address_type)
VALUES
    ('Retail Partners Co', 45678901, '17/02/2026', '13:20', '21/02/2026', '10:00',
     'PHONE', 'NO_CONTACT', 'BUSY_LINE', NULL, 'PHONE',
     'RETRY', 'Line constantly busy', 945678901, 56, 0, 'AUTO_DIALER',
     4, '-33.4258', '-70.6102', 'BUSINESS'),
    ('Retail Partners Co', 45678901, '13/02/2026', '10:00', '17/02/2026', '13:00',
     'PHONE', 'NO_CONTACT', 'NO_ANSWER', NULL, 'PHONE',
     'RETRY', 'Multiple attempts, no answer', 945678901, 56, 0, 'AUTO_DIALER',
     4, '-33.4258', '-70.6102', 'BUSINESS');

-- Account 56789012 - High value account, direct contact
INSERT INTO stg_collections_activity
(debtor_name, account_id, activity_date, activity_time, next_activity_date, next_activity_time,
 collection_type, contact_type, contact_response, non_payment_reason, contact_location,
 next_action, comments, phone, area_code, committed_amount, collector_name,
 address, latitude, longitude, address_type)
VALUES
    ('Manufacturing Plus', 56789012, '20/02/2026', '10:30', '27/02/2026', '10:00',
     'PHONE', 'PRIMARY', 'PAYMENT_PROMISE', 'AWAITING_INVOICE', 'OFFICE',
     'SEND_DOCUMENTS', 'Requested updated invoice, will pay within 7 days', 956789012, 56, 12500000, 'Ana Torres',
     5, '-33.4150', '-70.6069', 'BUSINESS'),
    ('Manufacturing Plus', 56789012, '15/02/2026', '14:00', '20/02/2026', '10:00',
     'EMAIL', 'PRIMARY', 'RESPONSE', 'DOCUMENTATION_ISSUE', 'EMAIL',
     'PHONE_CALL', 'CFO requested invoice copy', 956789012, 56, 0, 'Ana Torres',
     5, '-33.4150', '-70.6069', 'BUSINESS');

-- Account 67890123 - Small debt, automated dialer attempts
INSERT INTO stg_collections_activity
(debtor_name, account_id, activity_date, activity_time, next_activity_date, next_activity_time,
 collection_type, contact_type, contact_response, non_payment_reason, contact_location,
 next_action, comments, phone, area_code, committed_amount, collector_name,
 address, latitude, longitude, address_type)
VALUES
    ('Logistics Express', 67890123, '16/02/2026', '09:00', '19/02/2026', '09:00',
     'PHONE', 'NO_CONTACT', 'NO_ANSWER', NULL, 'PHONE',
     'AUTO_RETRY', 'Automated dialer - no answer', 967890123, 56, 0, 'AUTO_DIALER',
     6, '-33.3869', '-70.5475', 'BUSINESS'),
    ('Logistics Express', 67890123, '11/02/2026', '15:30', '16/02/2026', '09:00',
     'PHONE', 'NO_CONTACT', 'DISCONNECTED', NULL, 'PHONE',
     'UPDATE_INFO', 'Phone number appears disconnected', 967890123, 56, 0, 'AUTO_DIALER',
     6, '-33.3869', '-70.5475', 'BUSINESS');

-- Account 78901234 - No collections activity (assigned but not yet worked)
-- Intentionally left blank to test LEFT JOIN logic

-- =====================================================
-- DATA VALIDATION
-- =====================================================

-- Verify record counts
SELECT 'Account Assignments' AS table_name, COUNT(*) AS record_count 
FROM stg_account_assignment
UNION ALL
SELECT 'Collections Activities', COUNT(*) 
FROM stg_collections_activity;

-- Verify view population
SELECT 'Collections Summary View' AS view_name, COUNT(*) AS record_count 
FROM vw_collections_summary;
