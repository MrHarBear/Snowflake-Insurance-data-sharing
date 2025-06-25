/*
================================================================================
MOUNTAINPEAK INSURANCE - PROGRESSIVE DATA SHARING DEMO
================================================================================
Demo:    MountainPeak Insurance → Alpine Risk Brokers Data Sharing
Purpose: Complete demonstration: Build → Share → Protect
Flow:    Data Integration → Risk Analytics → Data Sharing → Progressive Governance
Duration: 35 minutes (7+5+8+15)

Demo Narrative:
"Today I'll show you how MountainPeak Insurance built their risk analytics on Snowflake,
shared valuable insights with broker partners, and then intelligently protected their 
sensitive data - all without disrupting the business value."

Progressive Demo Flow:
  Section 1: Data Integration (7 min) - Join customer + claims data
  Section 2: Risk Analytics (5 min) - Dynamic Table with automated risk scoring
  Section 3: Data Sharing (8 min) - Initial sharing with full access
  Section 4: Progressive Governance (15 min) - Apply 4 policies step-by-step

Key Message: "Build value first, then protect it intelligently"
Business Value: Real-time risk insights with progressive data protection
================================================================================
*/

-- Demo initialization
USE ROLE ACCOUNTADMIN;
USE DATABASE MOUNTAINPEAK_INSURANCE_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE INSURANCE_COMPUTE_WH;

/*
================================================================================
SECTION 1: DATA INTEGRATION
================================================================================
Duration: 7 minutes
Purpose: Join customer and claims data to create unified analytics dataset

Business Context:
"Let's start by integrating our customer demographics with their claims history.
This unified view will be the foundation for our risk analytics."
================================================================================
*/

CREATE OR REPLACE TABLE ANALYTICS.CUSTOMER_CLAIMS_JOINED AS
SELECT 
    -- Customer identifiers and demographics
    c.POLICY_NUMBER,
    c.AGE,
    c.INSURED_SEX,
    c.INSURED_EDUCATION_LEVEL,
    c.INSURED_OCCUPATION,  
    -- Policy financial details
    c.POLICY_START_DATE,
    c.POLICY_LENGTH_MONTH,
    c.POLICY_DEDUCTABLE,
    c.POLICY_ANNUAL_PREMIUM,
    -- Claims information (NULL if no claims)
    cl.INCIDENT_DATE,
    cl.INCIDENT_TYPE,
    cl.INCIDENT_SEVERITY,
    cl.AUTHORITIES_CONTACTED,
    cl.INCIDENT_HOUR_OF_THE_DAY,
    cl.NUMBER_OF_VEHICLES_INVOLVED,
    cl.BODILY_INJURIES,
    cl.WITNESSES,
    cl.POLICE_REPORT_AVAILABLE,
    cl.CLAIM_AMOUNT,
    cl.FRAUD_REPORTED,
    -- Derived fields for analytics
    CASE WHEN cl.POLICY_NUMBER IS NOT NULL THEN 1 ELSE 0 END as HAS_CLAIM,
    COALESCE(cl.CLAIM_AMOUNT, 0) as CLAIM_AMOUNT_FILLED,
    COALESCE(cl.FRAUD_REPORTED, FALSE) as FRAUD_REPORTED_FILLED
FROM RAW_DATA.CUSTOMER_RAW c
LEFT JOIN RAW_DATA.CLAIMS_RAW cl ON c.POLICY_NUMBER = cl.POLICY_NUMBER;

-- Sample the integrated data for review
SELECT * FROM ANALYTICS.CUSTOMER_CLAIMS_JOINED;

-- Business insight: Risk distribution by occupation
SELECT 
    INSURED_OCCUPATION,
    COUNT(*) as CUSTOMER_COUNT,
    SUM(HAS_CLAIM) as CLAIMS_COUNT,
    ROUND(AVG(CLAIM_AMOUNT_FILLED),2) as AVG_CLAIM_AMOUNT,
    ROUND(100.0 * SUM(HAS_CLAIM) / COUNT(*), 1) as CLAIM_RATE_PCT
FROM ANALYTICS.CUSTOMER_CLAIMS_JOINED
GROUP BY INSURED_OCCUPATION
HAVING COUNT(*) >= 10  -- Only occupations with sufficient sample size
ORDER BY CLAIM_RATE_PCT DESC
LIMIT 10;

/*
================================================================================
SECTION 2: RISK ANALYTICS (DYNAMIC TABLE)
================================================================================
Duration: 5 minutes  
Purpose: Build automated risk scoring matrix using Dynamic Tables

Business Context:
"Now let's create an automated risk scoring system that updates every 4 hours.
This will give Alpine Risk Brokers real-time insights into their portfolio risk."
================================================================================
*/

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.RISK_LEVEL_MATRIX
    TARGET_LAG = '4 hours'
    WAREHOUSE = INSURANCE_COMPUTE_WH
    COMMENT = 'Automated risk scoring matrix - refreshes every 4 hours'
AS
SELECT 
    -- All source data fields
    *,
    -- Simulated customer state (deterministic based on policy number)
    CASE 
        WHEN MOD(HASH(POLICY_NUMBER), 10) <= 2 THEN 'Colorado'
        WHEN MOD(HASH(POLICY_NUMBER), 10) <= 4 THEN 'Utah'  
        WHEN MOD(HASH(POLICY_NUMBER), 10) <= 6 THEN 'Wyoming'
        ELSE 'Other States'
    END as CUSTOMER_STATE,
    -- Risk scoring logic
    CASE 
        WHEN AGE <= 20 OR AGE >= 60 OR CLAIM_AMOUNT_FILLED > 75000 OR FRAUD_REPORTED_FILLED = TRUE THEN 'HIGH'
        WHEN AGE BETWEEN 25 AND 45 AND CLAIM_AMOUNT_FILLED BETWEEN 25000 AND 75000 THEN 'MEDIUM'
        ELSE 'LOW'
    END as RISK_LEVEL,
    -- Numerical risk score (0-100)
    GREATEST(0, LEAST(100,
        (CASE WHEN AGE < 25 THEN 30 ELSE 0 END) +
        (CASE WHEN AGE > 65 THEN 20 ELSE 0 END) +
        (CASE WHEN CLAIM_AMOUNT_FILLED > 50000 THEN 40 ELSE 0 END) +
        (CASE WHEN FRAUD_REPORTED_FILLED = TRUE THEN 30 ELSE 0 END) +
        (CASE WHEN INSURED_OCCUPATION IN ('armed-forces', 'transport-moving', 'handlers-cleaners') THEN 20 ELSE 0 END)
    )) as RISK_SCORE,
    -- Risk factors for transparency
    ARRAY_CONSTRUCT_COMPACT(
        CASE WHEN AGE < 25 THEN 'Young Driver' END,
        CASE WHEN AGE > 65 THEN 'Senior Driver' END,
        CASE WHEN CLAIM_AMOUNT_FILLED > 50000 THEN 'High Claim Amount' END,
        CASE WHEN FRAUD_REPORTED_FILLED = TRUE THEN 'Fraud History' END,
        CASE WHEN INSURED_OCCUPATION IN ('armed-forces', 'transport-moving', 'handlers-cleaners') THEN 'High Risk Occupation' END
    ) as RISK_FACTORS
FROM ANALYTICS.CUSTOMER_CLAIMS_JOINED;

SELECT * FROM ANALYTICS.RISK_LEVEL_MATRIX;

-- Create a Secure View to provide to consumers
CREATE OR REPLACE SECURE VIEW ANALYTICS.VW_RISK_LEVEL_MATRIX AS
SELECT 
    -- Customer identifiers and demographics
    POLICY_NUMBER,
    AGE,
    INSURED_SEX,
    INSURED_EDUCATION_LEVEL,
    INSURED_OCCUPATION,
    POLICY_START_DATE,
    POLICY_LENGTH_MONTH,
    POLICY_DEDUCTABLE,
    POLICY_ANNUAL_PREMIUM,
    CLAIM_AMOUNT_FILLED,  -- Used by masking policy
    FRAUD_REPORTED_FILLED, -- Used by projection policy
    RISK_LEVEL,
    RISK_SCORE,
    RISK_FACTORS,
    CUSTOMER_STATE   
FROM ANALYTICS.RISK_LEVEL_MATRIX;

SELECT * FROM ANALYTICS.VW_RISK_LEVEL_MATRIX;
SELECT 
    RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM,
    ROUND(AVG(CLAIM_AMOUNT_FILLED),2) as AVG_CLAIM_AMOUNT
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
GROUP BY RISK_LEVEL
ORDER BY 
    CASE RISK_LEVEL 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;

SELECT 
    'High Risk Customers Sample' as INSIGHT_TYPE,
    POLICY_NUMBER,
    AGE, 
    INSURED_OCCUPATION,
    CLAIM_AMOUNT_FILLED,
    RISK_SCORE,
    RISK_FACTORS
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
WHERE RISK_LEVEL = 'HIGH'
ORDER BY RISK_SCORE DESC
LIMIT 5;

/*
================================================================================
SECTION 3: DATA SHARING SETUP  
================================================================================
Duration: 8 minutes
Purpose: Create initial data share with full access to demonstrate business value

Business Context:
"Now let's share this valuable risk intelligence with Alpine Risk Brokers.
Initially, they'll get full access to see the complete business value."
================================================================================
*/

-- Set context for sharing operations
USE SCHEMA ANALYTICS;

-- Zero-Copy Cloning demonstration
CREATE OR REPLACE TRANSIENT TABLE SHARING.BROKER_DATA_CLONE 
CLONE ANALYTICS.RISK_LEVEL_MATRIX;

-- Create the actual data share (simulated for single account)
-- Note: In real demo, this would be cross-account sharing
-- Demonstrate current "broker perspective" (full access before governance)
USE ROLE MOUNTAINPEAK_ANALYST;
SELECT 
    'MOUNTAINPEAK_ANALYST Role: Simulating Consumer Experience' as ACCESS_STATUS,
    '(This role mimics what Alpine Risk Brokers will see)' as DEMO_NOTE,
    POLICY_NUMBER,
    CLAIM_AMOUNT_FILLED,
    FRAUD_REPORTED_FILLED,
    RISK_LEVEL
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
LIMIT 5;

USE ROLE ACCOUNTADMIN;

-- Create a secure share from your table (if not already exists)
-- This step is required as the share must exist before creating the listing
CREATE SHARE IF NOT EXISTS BROKER_DATA_SHARE
    COMMENT = 'Share for broker data to be used in listing';

-- Grant access to the database and schema to the share
GRANT USAGE ON DATABASE MOUNTAINPEAK_INSURANCE_DB TO SHARE BROKER_DATA_SHARE;
GRANT USAGE ON SCHEMA ANALYTICS TO SHARE BROKER_DATA_SHARE;

-- Grant access to the specific table to the share
GRANT SELECT ON TABLE ANALYTICS.VW_RISK_LEVEL_MATRIX TO SHARE BROKER_DATA_SHARE;

-- Create the external listing targeting the specific consumer account
CREATE EXTERNAL LISTING BROKER_DATA_LISTING 
SHARE BROKER_DATA_SHARE 
AS $$
title: "Broker Data Sharing"
subtitle: "Secure access to broker data"
description: "This listing provides secure access for authorized consumers. The data includes processed claims information suitable for analysis and integration."
listing_terms:
  type: "OFFLINE"
targets:
  accounts:
  - "SFSENORTHAMERICA.HCHEN_HORIZON_LAB_AWS_CONSUMER"
$$
PUBLISH = FALSE
REVIEW = FALSE
COMMENT = 'Listing for HCHEN_HORIZON_LAB_AWS_CONSUMER to access data';
describe listing DOCAI_CLAIM_CONSUMER_LISTING;

ALTER LISTING DOCAI_CLAIM_CONSUMER_LISTING PUBLISH;
/*
================================================================================
SECTION 4: PROGRESSIVE GOVERNANCE PROTECTION
================================================================================
Duration: 15 minutes (4 policies × ~4 minutes each)
Purpose: Apply governance policies step-by-step without breaking business value

Business Context:
"Now let's protect sensitive data step-by-step. Watch as we add governance controls 
without breaking the broker's ability to get valuable insights."
================================================================================
*/

-- Set governance context
USE SCHEMA GOVERNANCE;

-- STEP 1: DYNAMIC MASKING POLICY
-- Create masking policy for claim amounts with account-aware logic
CREATE OR REPLACE MASKING POLICY GOVERNANCE.MASK_CLAIM_AMOUNT AS 
    (claim_amount NUMBER) RETURNS NUMBER ->
    CASE
        -- Internal ACCOUNTADMIN gets full access
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN') THEN claim_amount  
        -- MOUNTAINPEAK_ANALYST role simulates consumer experience (masked)
        WHEN CURRENT_ROLE() IN ('MOUNTAINPEAK_ANALYST') OR 
             CURRENT_ACCOUNT_NAME() IN ('HCHEN_HORIZON_LAB_AWS_CONSUMER') THEN FLOOR(claim_amount / 10000) * 10000
        ELSE FLOOR(claim_amount / 10000) * 10000
    END;

-- Apply masking policy to the shared view's source table
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX 
    MODIFY COLUMN CLAIM_AMOUNT_FILLED 
    SET MASKING POLICY GOVERNANCE.MASK_CLAIM_AMOUNT;

-- Test masking with different roles
SELECT 
    'ACCOUNTADMIN View (Full Access)' as ROLE_VIEW,
    POLICY_NUMBER,
    CLAIM_AMOUNT_FILLED as CLAIM_AMOUNT,
    RISK_LEVEL
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
WHERE CLAIM_AMOUNT_FILLED > 50000
LIMIT 5;

USE ROLE MOUNTAINPEAK_ANALYST;

SELECT 
    'MOUNTAINPEAK_ANALYST View (Consumer Simulation - Masked)' as ROLE_VIEW,
    POLICY_NUMBER,
    CLAIM_AMOUNT_FILLED as CLAIM_AMOUNT,  -- Should be masked now
    RISK_LEVEL
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
WHERE CLAIM_AMOUNT_FILLED > 50000
LIMIT 5;

-- Simulate external account view (would see masked values)
USE ROLE ACCOUNTADMIN;

-- STEP 2: ROW ACCESS POLICY
-- Create account-based territory mapping for broker access
CREATE OR REPLACE TABLE GOVERNANCE.BROKER_TERRITORY_MAP (
    ACCOUNT_NAME VARCHAR(100),
    ALLOWED_STATE VARCHAR(50)
);

-- Insert territory mappings with account names
INSERT INTO GOVERNANCE.BROKER_TERRITORY_MAP VALUES
    -- External consumer accounts (examples)
    ('HCHEN_HORIZON_LAB_AWS_CONSUMER', 'Colorado'),
    ('HCHEN_HORIZON_LAB_AWS_CONSUMER', 'Utah'),
    ('HCHEN_HORIZON_LAB_AWS_CONSUMER', 'Wyoming'),
    -- Any consumer account gets limited access
    ('CONSUMER_SIMULATION', 'Colorado'),
    ('CONSUMER_SIMULATION', 'Utah'),
    ('CONSUMER_SIMULATION', 'Wyoming'),
    -- Internal access sees all
    ('INTERNAL_ACCESS', 'ALL_STATES');

SELECT * FROM GOVERNANCE.BROKER_TERRITORY_MAP;

-- Create account-aware row access policy for geographic restrictions
CREATE OR REPLACE ROW ACCESS POLICY GOVERNANCE.ALPINE_BROKER_ACCESS AS
    (customer_state STRING) RETURNS BOOLEAN ->
    CASE
        -- Internal ACCOUNTADMIN sees all states
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN') THEN TRUE
        WHEN CURRENT_ROLE() IN ('MOUNTAINPEAK_ANALYST') 
            THEN customer_state IN ('Colorado', 'Utah', 'Wyoming')
        -- External consumer accounts see only allowed territories
        WHEN CURRENT_ACCOUNT_NAME() IN (
            SELECT ACCOUNT_NAME FROM GOVERNANCE.BROKER_TERRITORY_MAP 
            WHERE ALLOWED_STATE = customer_state OR ALLOWED_STATE = 'ALL_STATES'
        ) THEN TRUE
        -- Default: restrict access
        ELSE FALSE
    END;

-- Apply row access policy
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX
    ADD ROW ACCESS POLICY GOVERNANCE.ALPINE_BROKER_ACCESS ON (CUSTOMER_STATE);

-- Test geographic filtering
SELECT 
    'Geographic Distribution' as ANALYSIS,
    CUSTOMER_STATE,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as PERCENTAGE
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
GROUP BY CUSTOMER_STATE
ORDER BY CUSTOMER_COUNT DESC;

USE ROLE MOUNTAINPEAK_ANALYST;
-- Test geographic filtering
SELECT 
    'Geographic Distribution' as ANALYSIS,
    CUSTOMER_STATE,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as PERCENTAGE
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
GROUP BY CUSTOMER_STATE
ORDER BY CUSTOMER_COUNT DESC;

USE ROLE ACCOUNTADMIN;

-- STEP 3: AGGREGATION POLICY
-- Create account-aware aggregation policy for privacy protection
CREATE OR REPLACE AGGREGATION POLICY GOVERNANCE.MIN_GROUP_POLICY AS
    () RETURNS AGGREGATION_CONSTRAINT ->
    CASE
        -- Internal ACCOUNTADMIN has no aggregation constraints
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN') THEN NO_AGGREGATION_CONSTRAINT()
        -- MOUNTAINPEAK_ANALYST simulates consumer constraints (min 20 records)
        WHEN CURRENT_ROLE() IN ('MOUNTAINPEAK_ANALYST') OR 
             CURRENT_ACCOUNT_NAME() IN ('HCHEN_HORIZON_LAB_AWS_CONSUMER') THEN AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 20)
        -- Default: require aggregation for privacy
        ELSE AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 20)
    END;

-- Apply aggregation policy to the table
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX
    SET AGGREGATION POLICY GOVERNANCE.MIN_GROUP_POLICY;

-- Test aggregation policy
SELECT 
    'Testing Aggregation Policy - This Should Work' as TEST_TYPE,
    RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
GROUP BY RISK_LEVEL;

-- This would fail for external accounts (individual record access)
USE ROLE MOUNTAINPEAK_ANALYST;
SELECT * FROM ANALYTICS.VW_RISK_LEVEL_MATRIX LIMIT 10;

USE ROLE ACCOUNTADMIN;

-- STEP 4: PROJECTION POLICY
-- Create account-aware projection policy for sensitive columns
CREATE OR REPLACE PROJECTION POLICY GOVERNANCE.HIDE_FRAUD_INDICATOR AS
    () RETURNS PROJECTION_CONSTRAINT ->
    CASE
        -- Internal ACCOUNTADMIN can see fraud indicators
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN') THEN PROJECTION_CONSTRAINT(ALLOW => true)
        -- MOUNTAINPEAK_ANALYST simulates consumer restrictions (hidden fraud data)
        WHEN CURRENT_ROLE() IN ('MOUNTAINPEAK_ANALYST') OR 
             CURRENT_ACCOUNT_NAME() IN ('HCHEN_HORIZON_LAB_AWS_CONSUMER') THEN PROJECTION_CONSTRAINT(ALLOW => false)
        -- Default: hide sensitive data
        ELSE PROJECTION_CONSTRAINT(ALLOW => false)
    END;

-- Apply projection policy to fraud column
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX
    MODIFY COLUMN FRAUD_REPORTED_FILLED
    SET PROJECTION POLICY GOVERNANCE.HIDE_FRAUD_INDICATOR;

-- Test projection policy
SELECT 
    'Internal Access - Can See Fraud Data' as ACCESS_TYPE,
    POLICY_NUMBER,
    FRAUD_REPORTED_FILLED as FRAUD_REPORTED,
    RISK_LEVEL
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
WHERE FRAUD_REPORTED_FILLED = TRUE
LIMIT 5;

-- This would fail for external accounts trying to SELECT fraud column
-- But they can still filter by it in WHERE clauses

/*
================================================================================
GOVERNANCE VALIDATION & FINAL DEMONSTRATION
================================================================================
Purpose: Validate all policies working together and show final broker experience
================================================================================
*/

-- Test role switching to show different access levels
USE ROLE MOUNTAINPEAK_ANALYST;

SELECT * FROM ANALYTICS.VW_RISK_LEVEL_MATRIX;

DESC VIEW ANALYTICS.VW_RISK_LEVEL_MATRIX;

SELECT 
    CUSTOMER_STATE,                                         -- Row Access: Only CO/UT/WY visible
    --fraud_reported_filled,
    --RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,                             -- Aggregation: Minimum 20 records required
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM,
    ROUND(AVG(CLAIM_AMOUNT_FILLED),0) as AVG_CLAIM_AMOUNT   -- Dynamic Masking: Floored to $10K increments
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
WHERE FRAUD_REPORTED_FILLED = FALSE
GROUP BY CUSTOMER_STATE
-- HAVING COUNT(*) >= 20                                    -- Aggregation Policy: Min group size enforcement
ORDER BY CUSTOMER_STATE;

USE ROLE ACCOUNTADMIN;
SELECT * FROM ANALYTICS.VW_RISK_LEVEL_MATRIX;

-- Final broker view simulation
SELECT 
    'FINAL BROKER EXPERIENCE' as DEMO_CONCLUSION,
    'Valuable insights maintained, sensitive data protected' as BUSINESS_OUTCOME;

SELECT 
    'Alpine Risk Brokers Final View' as PERSPECTIVE,
    RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM
    -- Note: CLAIM_AMOUNT would be masked to $10K increments
    -- Note: Only CO/UT/WY customers would be visible  
    -- Note: Fraud column would be hidden
    -- Note: Aggregate queries required (20+ records)
FROM ANALYTICS.RISK_LEVEL_MATRIX
GROUP BY RISK_LEVEL
ORDER BY 
    CASE RISK_LEVEL 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;

USE ROLE MOUNTAINPEAK_ANALYST;

-- ANALYTICS QUERY 1: Risk-Based Portfolio Analysis
SELECT 
    'QUERY 1: Portfolio Risk Distribution' as ANALYSIS_TYPE;

SELECT 
    RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as PORTFOLIO_PERCENTAGE,
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_ANNUAL_PREMIUM,
    ROUND(AVG(CLAIM_AMOUNT_FILLED),0) as AVG_CLAIM_AMOUNT_MASKED,  -- Masked to $10K increments
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
GROUP BY RISK_LEVEL
ORDER BY 
    CASE RISK_LEVEL WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 3 END;

SELECT 
    CUSTOMER_STATE,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as STATE_PERCENTAGE,
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE,
    ROUND(SUM(POLICY_ANNUAL_PREMIUM),2) as TOTAL_PREMIUM_VOLUME,
    'Shows only CO/UT/WY due to geographic restrictions' as GOVERNANCE_NOTE
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
GROUP BY CUSTOMER_STATE
-- HAVING COUNT(*) >= 20  -- Aggregation policy compliance
ORDER BY CUSTOMER_COUNT DESC;

SELECT 
    CASE 
        WHEN AGE <= 25 THEN '18-25 (Young Drivers)'
        WHEN AGE <= 35 THEN '26-35 (Young Adults)'
        WHEN AGE <= 45 THEN '36-45 (Prime Age)'
        WHEN AGE <= 55 THEN '46-55 (Experienced)'
        WHEN AGE <= 65 THEN '56-65 (Pre-Senior)'
        ELSE '65+ (Senior Drivers)'
    END as AGE_GROUP,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as PERCENTAGE
FROM ANALYTICS.VW_RISK_LEVEL_MATRIX
GROUP BY 
    CASE 
        WHEN AGE <= 25 THEN '18-25 (Young Drivers)'
        WHEN AGE <= 35 THEN '26-35 (Young Adults)'
        WHEN AGE <= 45 THEN '36-45 (Prime Age)'
        WHEN AGE <= 55 THEN '46-55 (Experienced)'
        WHEN AGE <= 65 THEN '56-65 (Pre-Senior)'
        ELSE '65+ (Senior Drivers)'
    END
--HAVING COUNT(*) >= 20  -- Aggregation policy compliance
ORDER BY AVG_RISK_SCORE DESC;

/*
================================================================================
DEMO COMPLETE!
================================================================================
The progressive governance demo is now complete. 

To clean up all demo artifacts, run the 99_Cleanup.sql script.

Key Takeaways:
- Built value first with data integration and risk analytics
- Shared data with full business value to partners
- Applied governance progressively without breaking functionality
- Maintained analytical insights while protecting sensitive data
================================================================================
*/