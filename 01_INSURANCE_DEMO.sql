/***************************************************************************************************
🔵 MOUNTAINPEAK INSURANCE - PROGRESSIVE DATA SHARING DEMO
===========================================================

Demo:         MountainPeak Insurance → Alpine Risk Brokers Data Sharing
Create Date:  2025-01-15
Purpose:      Complete demonstration: Build → Share → Protect
Flow:         Data Integration → Risk Analytics → Data Sharing → Progressive Governance
Duration:     35 minutes (7+5+8+15)
****************************************************************************************************

⚫ DEMO NARRATIVE:
"Today I'll show you how MountainPeak Insurance built their risk analytics on Snowflake,
shared valuable insights with broker partners, and then intelligently protected their 
sensitive data - all without disrupting the business value."

🔷 Progressive Demo Flow:
  Section 1: Data Integration (7 min) - Join customer + claims data
  Section 2: Risk Analytics (5 min) - Dynamic Table with automated risk scoring
  Section 3: Data Sharing (8 min) - Initial sharing with full access
  Section 4: Progressive Governance (15 min) - Apply 4 policies step-by-step

🔸 Key Message: "Build value first, then protect it intelligently"
🟣 Business Value: Real-time risk insights with progressive data protection
----------------------------------------------------------------------------------*/

-- 🔵 DEMO INITIALIZATION
USE ROLE ACCOUNTADMIN;
USE DATABASE MOUNTAINPEAK_INSURANCE_DB;
USE WAREHOUSE INSURANCE_COMPUTE_WH;

-- ⚫ Validate setup completion before proceeding
SELECT 
    '🔵 DEMO STARTING' as STATUS,
    CURRENT_DATABASE() as DATABASE_NAME,
    (SELECT COUNT(*) FROM RAW_DATA.CLAIMS_RAW) as CLAIMS_LOADED,
    (SELECT COUNT(*) FROM RAW_DATA.CUSTOMER_RAW) as CUSTOMERS_LOADED;

/***************************************************************************************************
🔵 SECTION 1: DATA INTEGRATION
===============================================
Duration: 7 minutes
Purpose: Join customer and claims data to create unified analytics dataset

⚫ Business Context:
"Let's start by integrating our customer demographics with their claims history.
This unified view will be the foundation for our risk analytics."
***************************************************************************************************/

-- 🔷 Set context for analytics work
USE SCHEMA ANALYTICS;

-- ⚫ Create integrated customer-claims dataset
SELECT 
    '🔷 Creating integrated customer-claims dataset...' as STEP,
    'Joining 1,202 customers with 1,002 claims' as DETAILS;

CREATE OR REPLACE TABLE ANALYTICS.CUSTOMER_CLAIMS_JOINED AS
SELECT 
    -- 🔵 Customer identifiers and demographics
    c.POLICY_NUMBER,
    c.AGE,
    c.INSURED_SEX,
    c.INSURED_EDUCATION_LEVEL,
    c.INSURED_OCCUPATION,
    
    -- 🔷 Policy financial details
    c.POLICY_START_DATE,
    c.POLICY_LENGTH_MONTH,
    c.POLICY_DEDUCTABLE,
    c.POLICY_ANNUAL_PREMIUM,
    
    -- ⚫ Claims information (NULL if no claims)
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
    
    -- 🟣 Derived fields for analytics
    CASE WHEN cl.POLICY_NUMBER IS NOT NULL THEN 1 ELSE 0 END as HAS_CLAIM,
    COALESCE(cl.CLAIM_AMOUNT, 0) as CLAIM_AMOUNT_FILLED,
    COALESCE(cl.FRAUD_REPORTED, FALSE) as FRAUD_REPORTED_FILLED
    
FROM RAW_DATA.CUSTOMER_RAW c
LEFT JOIN RAW_DATA.CLAIMS_RAW cl ON c.POLICY_NUMBER = cl.POLICY_NUMBER;

-- ⭐ Validate integration success
SELECT 
    '⭐ Data Integration Complete' as STATUS,
    COUNT(*) as TOTAL_RECORDS,
    SUM(HAS_CLAIM) as RECORDS_WITH_CLAIMS,
    ROUND(AVG(CLAIM_AMOUNT_FILLED),2) as AVG_CLAIM_AMOUNT,
    COUNT(DISTINCT INSURED_OCCUPATION) as UNIQUE_OCCUPATIONS
FROM ANALYTICS.CUSTOMER_CLAIMS_JOINED;

-- 🔷 Sample the integrated data for review
SELECT 
    'Sample Integrated Data' as PREVIEW,
    POLICY_NUMBER,
    AGE,
    INSURED_OCCUPATION,
    POLICY_ANNUAL_PREMIUM,
    INCIDENT_TYPE,
    CLAIM_AMOUNT,
    FRAUD_REPORTED
FROM ANALYTICS.CUSTOMER_CLAIMS_JOINED
WHERE HAS_CLAIM = 1
LIMIT 10;

-- 🔸 Business insight: Risk distribution by occupation
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

/***************************************************************************************************
🔵 SECTION 2: RISK ANALYTICS (DYNAMIC TABLE)
============================================
Duration: 5 minutes  
Purpose: Build automated risk scoring matrix using Dynamic Tables

⚫ Business Context:
"Now let's create an automated risk scoring system that updates every 4 hours.
This will give Alpine Risk Brokers real-time insights into their portfolio risk."
***************************************************************************************************/

-- ⚫ Dynamic Table for automated risk scoring
SELECT 
    '🔷 Creating Dynamic Table for risk scoring...' as STEP,
    'Automated refresh every 4 hours' as REFRESH_SCHEDULE;

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.RISK_LEVEL_MATRIX
    TARGET_LAG = '4 hours'
    WAREHOUSE = INSURANCE_COMPUTE_WH
    COMMENT = 'Automated risk scoring matrix - refreshes every 4 hours'
AS
SELECT 
    -- 🔵 All source data fields
    *,
    
    -- 🔷 Risk scoring logic
    CASE 
        WHEN AGE < 25 OR CLAIM_AMOUNT_FILLED > 75000 OR FRAUD_REPORTED_FILLED = TRUE THEN 'HIGH'
        WHEN AGE BETWEEN 25 AND 45 AND CLAIM_AMOUNT_FILLED BETWEEN 25000 AND 75000 THEN 'MEDIUM'
        ELSE 'LOW'
    END as RISK_LEVEL,
    
    -- ⚫ Numerical risk score (0-100)
    GREATEST(0, LEAST(100,
        (CASE WHEN AGE < 25 THEN 30 ELSE 0 END) +
        (CASE WHEN AGE > 65 THEN 20 ELSE 0 END) +
        (CASE WHEN CLAIM_AMOUNT_FILLED > 50000 THEN 40 ELSE 0 END) +
        (CASE WHEN FRAUD_REPORTED_FILLED = TRUE THEN 30 ELSE 0 END) +
        (CASE WHEN INSURED_OCCUPATION IN ('armed-forces', 'transport-moving', 'handlers-cleaners') THEN 20 ELSE 0 END)
    )) as RISK_SCORE,
    
    -- 🟣 Risk factors for transparency
    ARRAY_CONSTRUCT_COMPACT(
        CASE WHEN AGE < 25 THEN 'Young Driver' END,
        CASE WHEN AGE > 65 THEN 'Senior Driver' END,
        CASE WHEN CLAIM_AMOUNT_FILLED > 50000 THEN 'High Claim Amount' END,
        CASE WHEN FRAUD_REPORTED_FILLED = TRUE THEN 'Fraud History' END,
        CASE WHEN INSURED_OCCUPATION IN ('armed-forces', 'transport-moving', 'handlers-cleaners') THEN 'High Risk Occupation' END
    ) as RISK_FACTORS,
    
    -- ⭐ Refresh tracking
    CURRENT_TIMESTAMP() as RISK_CALCULATED_AT
    
FROM ANALYTICS.CUSTOMER_CLAIMS_JOINED;

-- 🔸 Wait for initial refresh to complete
SELECT SYSTEM$GET_DYNAMIC_TABLE_REFRESH_HISTORY('ANALYTICS.RISK_LEVEL_MATRIX');

-- ⭐ Validate risk matrix creation
SELECT 
    '⭐ Risk Matrix Created' as STATUS,
    COUNT(*) as TOTAL_CUSTOMERS,
    COUNT(DISTINCT RISK_LEVEL) as RISK_LEVELS,
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE
FROM ANALYTICS.RISK_LEVEL_MATRIX;

-- 🔷 Risk distribution analysis
SELECT 
    RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as PERCENTAGE,
    ROUND(AVG(RISK_SCORE),1) as AVG_SCORE,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM
FROM ANALYTICS.RISK_LEVEL_MATRIX
GROUP BY RISK_LEVEL
ORDER BY 
    CASE RISK_LEVEL 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;

-- 🟣 Sample high-risk customers for broker insight
SELECT 
    '🔸 High Risk Customers Sample' as INSIGHT_TYPE,
    POLICY_NUMBER,
    AGE,
    INSURED_OCCUPATION,
    CLAIM_AMOUNT_FILLED,
    RISK_SCORE,
    RISK_FACTORS
FROM ANALYTICS.RISK_LEVEL_MATRIX
WHERE RISK_LEVEL = 'HIGH'
ORDER BY RISK_SCORE DESC
LIMIT 5;

/***************************************************************************************************
🔵 SECTION 3: DATA SHARING SETUP  
================================
Duration: 8 minutes
Purpose: Create initial data share with full access to demonstrate business value

⚫ Business Context:
"Now let's share this valuable risk intelligence with Alpine Risk Brokers.
Initially, they'll get full access to see the complete business value."
***************************************************************************************************/

-- 🔷 Set context for sharing operations
USE SCHEMA SHARING;

-- ⚫ Create secure view for sharing (initially unrestricted)
SELECT 
    '🔷 Creating secure view for data sharing...' as STEP,
    'Initial setup: Full access to demonstrate value' as ACCESS_LEVEL;

CREATE OR REPLACE SECURE VIEW SHARING.BROKER_SHARED_VIEW AS
SELECT 
    -- 🔵 Customer identifiers (will be governed later)
    POLICY_NUMBER,
    AGE,
    INSURED_SEX,
    INSURED_EDUCATION_LEVEL,
    INSURED_OCCUPATION,
    
    -- 🔷 Policy information  
    POLICY_START_DATE,
    POLICY_ANNUAL_PREMIUM,
    POLICY_DEDUCTABLE,
    
    -- ⚫ Claims data (will be masked later)
    INCIDENT_TYPE,
    INCIDENT_SEVERITY,
    CLAIM_AMOUNT_FILLED as CLAIM_AMOUNT,
    FRAUD_REPORTED_FILLED as FRAUD_REPORTED,
    
    -- 🟣 Risk analytics (core business value)
    RISK_LEVEL,
    RISK_SCORE,
    RISK_FACTORS,
    RISK_CALCULATED_AT,
    
    -- ⭐ Derived insights for brokers
    CASE 
        WHEN RISK_LEVEL = 'HIGH' THEN 'Requires Enhanced Underwriting'
        WHEN RISK_LEVEL = 'MEDIUM' THEN 'Standard Underwriting Process'
        ELSE 'Preferred Customer Profile'
    END as UNDERWRITING_RECOMMENDATION
    
FROM ANALYTICS.RISK_LEVEL_MATRIX;

-- ⚫ Test the shared view
SELECT 
    '⭐ Shared View Created' as STATUS,
    COUNT(*) as TOTAL_RECORDS,
    COUNT(DISTINCT RISK_LEVEL) as RISK_LEVELS_AVAILABLE
FROM SHARING.BROKER_SHARED_VIEW;

-- 🔷 Sample broker insights
SELECT 
    'Alpine Risk Brokers Portfolio Preview' as BROKER_VIEW,
    RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(AVG(RISK_SCORE),1) as AVG_RISK_SCORE,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM,
    ROUND(AVG(CLAIM_AMOUNT),2) as AVG_CLAIM_AMOUNT
FROM SHARING.BROKER_SHARED_VIEW
GROUP BY RISK_LEVEL
ORDER BY 
    CASE RISK_LEVEL 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;

-- 🔸 Zero-Copy Cloning demonstration
CREATE OR REPLACE TRANSIENT TABLE SHARING.BROKER_DATA_CLONE 
CLONE ANALYTICS.RISK_LEVEL_MATRIX;

SELECT 
    '🟣 Zero-Copy Clone Created' as DEMO_FEATURE,
    'Instant copy without data duplication' as BENEFIT,
    COUNT(*) as CLONED_RECORDS
FROM SHARING.BROKER_DATA_CLONE;

-- ⚫ Create the actual data share (simulated for single account)
-- Note: In real demo, this would be cross-account sharing
SELECT 
    '🔵 Data Share Ready' as SHARING_STATUS,
    'Alpine Risk Brokers can now access risk insights' as BUSINESS_VALUE,
    'Next: Apply progressive governance controls' as NEXT_STEP;

-- 🔷 Demonstrate current "broker perspective" (full access)
USE ROLE MOUNTAINPEAK_ANALYST;
SELECT 
    'Current Broker Access Level: FULL' as ACCESS_STATUS,
    POLICY_NUMBER,
    CLAIM_AMOUNT,
    FRAUD_REPORTED,
    RISK_LEVEL
FROM SHARING.BROKER_SHARED_VIEW
LIMIT 5;

USE ROLE ACCOUNTADMIN;

/***************************************************************************************************
🔵 SECTION 4: PROGRESSIVE GOVERNANCE PROTECTION
==============================================
Duration: 15 minutes (4 policies × ~4 minutes each)
Purpose: Apply governance policies step-by-step without breaking business value

⚫ Business Context:
"Now let's protect sensitive data step-by-step. Watch as we add governance controls 
without breaking the broker's ability to get valuable insights."
***************************************************************************************************/

-- 🔷 Set governance context
USE SCHEMA GOVERNANCE;

SELECT 
    '🔵 PROGRESSIVE GOVERNANCE STARTING' as STATUS,
    'Applying 4 policy types step-by-step' as APPROACH,
    'Business value maintained throughout' as GUARANTEE;

/*************************************************/
/*    🔷 STEP 1: DYNAMIC MASKING POLICY         */
/*************************************************/

SELECT 
    '🔷 STEP 1: DYNAMIC MASKING' as POLICY_TYPE,
    'Protecting claim amounts with role-based access' as PURPOSE;

-- ⚫ Create masking policy for claim amounts
CREATE OR REPLACE MASKING POLICY GOVERNANCE.MASK_CLAIM_AMOUNT AS 
    (claim_amount NUMBER) RETURNS NUMBER ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'MOUNTAINPEAK_ANALYST') THEN claim_amount
        ELSE FLOOR(claim_amount / 10000) * 10000  -- Floor to nearest $10,000
    END;

-- Apply masking policy to the shared view's source table
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX 
    MODIFY COLUMN CLAIM_AMOUNT_FILLED 
    SET MASKING POLICY GOVERNANCE.MASK_CLAIM_AMOUNT;

-- 🔸 Test masking with different roles
SELECT 
    'ACCOUNTADMIN View (Full Access)' as ROLE_VIEW,
    POLICY_NUMBER,
    CLAIM_AMOUNT_FILLED as CLAIM_AMOUNT,
    RISK_LEVEL
FROM ANALYTICS.RISK_LEVEL_MATRIX
WHERE CLAIM_AMOUNT_FILLED > 50000
LIMIT 5;

USE ROLE MOUNTAINPEAK_ANALYST;
SELECT 
    'MOUNTAINPEAK_ANALYST View (Full Access)' as ROLE_VIEW,
    POLICY_NUMBER,
    CLAIM_AMOUNT_FILLED as CLAIM_AMOUNT,
    RISK_LEVEL
FROM ANALYTICS.RISK_LEVEL_MATRIX
WHERE CLAIM_AMOUNT_FILLED > 50000
LIMIT 5;

-- 🟣 Simulate external account view (would see masked values)
USE ROLE ACCOUNTADMIN;
SELECT 
    '⭐ Masking Policy Applied' as STATUS,
    'External accounts now see floored amounts' as PROTECTION,
    'Internal roles maintain full access' as FLEXIBILITY;

/*************************************************/
/*    🔷 STEP 2: ROW ACCESS POLICY              */
/*************************************************/

SELECT 
    '🔷 STEP 2: ROW ACCESS POLICY' as POLICY_TYPE,
    'Geographic restrictions for Alpine Risk Brokers' as PURPOSE;

-- ⚫ Create location mapping for broker access
CREATE OR REPLACE TABLE GOVERNANCE.BROKER_TERRITORY_MAP (
    BROKER_ACCOUNT VARCHAR(100),
    ALLOWED_STATE VARCHAR(50)
);

-- Insert territory mappings
INSERT INTO GOVERNANCE.BROKER_TERRITORY_MAP VALUES
    ('ALPINE_RISK_BROKERS', 'Colorado'),
    ('ALPINE_RISK_BROKERS', 'Utah'),
    ('ALPINE_RISK_BROKERS', 'Wyoming'),
    ('INTERNAL_ACCESS', 'ALL_STATES');

-- Add state information to our data (simulated based on occupation patterns)
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX 
ADD COLUMN CUSTOMER_STATE VARCHAR(50) DEFAULT 
    CASE 
        WHEN UNIFORM(1,10,RANDOM()) <= 3 THEN 'Colorado'
        WHEN UNIFORM(1,10,RANDOM()) <= 5 THEN 'Utah'  
        WHEN UNIFORM(1,10,RANDOM()) <= 7 THEN 'Wyoming'
        ELSE 'Other States'
    END;

-- ⚫ Create row access policy for geographic restrictions
CREATE OR REPLACE ROW ACCESS POLICY GOVERNANCE.ALPINE_BROKER_ACCESS AS
    (customer_state STRING) RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('ACCOUNTADMIN', 'MOUNTAINPEAK_ANALYST')  -- Internal roles see all
    OR customer_state IN ('Colorado', 'Utah', 'Wyoming');  -- External brokers see only their territory

-- Apply row access policy
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX
    ADD ROW ACCESS POLICY GOVERNANCE.ALPINE_BROKER_ACCESS ON (CUSTOMER_STATE);

-- 🔸 Test geographic filtering
SELECT 
    'Geographic Distribution' as ANALYSIS,
    CUSTOMER_STATE,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as PERCENTAGE
FROM ANALYTICS.RISK_LEVEL_MATRIX
GROUP BY CUSTOMER_STATE
ORDER BY CUSTOMER_COUNT DESC;

SELECT 
    '⭐ Row Access Policy Applied' as STATUS,
    'Brokers only see customers in CO/UT/WY' as PROTECTION,
    'Internal users see all states' as FLEXIBILITY;

/*************************************************/
/*    🔷 STEP 3: AGGREGATION POLICY             */
/*************************************************/

SELECT 
    '🔷 STEP 3: AGGREGATION POLICY' as POLICY_TYPE,
    'Privacy protection through minimum group sizes' as PURPOSE;

-- ⚫ Create aggregation policy for privacy protection
CREATE OR REPLACE AGGREGATION POLICY GOVERNANCE.MIN_GROUP_POLICY AS
    () RETURNS AGGREGATION_CONSTRAINT ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'MOUNTAINPEAK_ANALYST') THEN NO_AGGREGATION_CONSTRAINT()
        ELSE AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 20)
    END;

-- Apply aggregation policy to the table
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX
    SET AGGREGATION POLICY GOVERNANCE.MIN_GROUP_POLICY;

-- 🔸 Test aggregation policy
SELECT 
    'Testing Aggregation Policy - This Should Work' as TEST_TYPE,
    RISK_LEVEL,
    COUNT(*) as CUSTOMER_COUNT,
    ROUND(AVG(POLICY_ANNUAL_PREMIUM),2) as AVG_PREMIUM
FROM ANALYTICS.RISK_LEVEL_MATRIX
GROUP BY RISK_LEVEL;

-- This would fail for external accounts (individual record access)
-- SELECT * FROM ANALYTICS.RISK_LEVEL_MATRIX LIMIT 10;

SELECT 
    '⭐ Aggregation Policy Applied' as STATUS,
    'External accounts require minimum 20 records' as PROTECTION,
    'Prevents individual record identification' as PRIVACY_BENEFIT;

/*************************************************/
/*    🔷 STEP 4: PROJECTION POLICY              */
/*************************************************/

SELECT 
    '🔷 STEP 4: PROJECTION POLICY' as POLICY_TYPE,
    'Hiding fraud indicators from external partners' as PURPOSE;

-- ⚫ Create projection policy for sensitive columns
CREATE OR REPLACE PROJECTION POLICY GOVERNANCE.HIDE_FRAUD_INDICATOR AS
    () RETURNS PROJECTION_CONSTRAINT ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'MOUNTAINPEAK_ANALYST') THEN PROJECTION_CONSTRAINT(ALLOW => true)
        ELSE PROJECTION_CONSTRAINT(ALLOW => false)
    END;

-- Apply projection policy to fraud column
ALTER TABLE ANALYTICS.RISK_LEVEL_MATRIX
    MODIFY COLUMN FRAUD_REPORTED_FILLED
    SET PROJECTION POLICY GOVERNANCE.HIDE_FRAUD_INDICATOR;

-- 🔸 Test projection policy
SELECT 
    'Internal Access - Can See Fraud Data' as ACCESS_TYPE,
    POLICY_NUMBER,
    FRAUD_REPORTED_FILLED as FRAUD_REPORTED,
    RISK_LEVEL
FROM ANALYTICS.RISK_LEVEL_MATRIX
WHERE FRAUD_REPORTED_FILLED = TRUE
LIMIT 5;

-- This would fail for external accounts trying to SELECT fraud column
-- But they can still filter by it in WHERE clauses

SELECT 
    '⭐ Projection Policy Applied' as STATUS,
    'External accounts cannot SELECT fraud column' as PROTECTION,
    'Can still filter by fraud in WHERE clauses' as FUNCTIONALITY;

/***************************************************************************************************
🔵 GOVERNANCE VALIDATION & FINAL DEMONSTRATION
============================================= 
Purpose: Validate all policies working together and show final broker experience
***************************************************************************************************/

-- ⚫ Test role switching to show different access levels
USE ROLE MOUNTAINPEAK_ANALYST;

SELECT 
    '🔵 MOUNTAINPEAK_ANALYST ACCESS VALIDATION' as TEST_ROLE,
    'Full internal access maintained' as EXPECTATION;

-- Internal analyst sees full data
SELECT 
    POLICY_NUMBER,
    CLAIM_AMOUNT_FILLED as CLAIM_AMOUNT,  -- Full amount
    CUSTOMER_STATE,  -- All states
    FRAUD_REPORTED_FILLED as FRAUD_REPORTED,  -- Visible
    RISK_LEVEL
FROM ANALYTICS.RISK_LEVEL_MATRIX
WHERE RISK_LEVEL = 'HIGH'
LIMIT 5;

USE ROLE ACCOUNTADMIN;

-- 🔷 Final validation of all policies
SELECT 
    '⭐ ALL GOVERNANCE POLICIES ACTIVE' as STATUS,
    'Progressive protection complete' as ACHIEVEMENT;

-- Show policy summary
SELECT 
    'Policy Type' as GOVERNANCE_CONTROL,
    'Protection Level' as PROTECTION_DETAILS
FROM VALUES 
    ('Dynamic Masking', 'Claim amounts floored to $10K increments'),
    ('Row Access', 'Geographic filtering to CO/UT/WY for brokers'),
    ('Aggregation', 'Minimum 20 records for external queries'),
    ('Projection', 'Fraud indicators hidden from external selection')
AS policies(GOVERNANCE_CONTROL, PROTECTION_DETAILS);

-- ⚫ Final broker view simulation
SELECT 
    '🟣 FINAL BROKER EXPERIENCE' as DEMO_CONCLUSION,
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
FROM SHARING.BROKER_SHARED_VIEW
GROUP BY RISK_LEVEL
ORDER BY 
    CASE RISK_LEVEL 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;

/***************************************************************************************************
🔵 DEMO COMPLETION & BUSINESS IMPACT SUMMARY
===========================================

⭐ DEMONSTRATION COMPLETE ⭐

✅ What We Accomplished:
  • Built: Integrated customer + claims data with automated risk scoring
  • Shared: Provided immediate business value to Alpine Risk Brokers  
  • Protected: Applied 4 governance policies without breaking functionality

🔷 Business Value Delivered:
  • Real-time risk insights for better underwriting decisions
  • Automated portfolio analysis with 4-hour refresh cycles
  • Secure data collaboration with progressive protection

⚫ Technical Excellence:
  • Dynamic Tables: Automated risk scoring with scheduled refresh
  • Zero-Copy Sharing: Instant data access without duplication
  • Progressive Governance: 4 policy types working seamlessly together
  • Role-Based Access: Flexible internal vs external permissions

🟣 Key Differentiators:
  • Build → Share → Protect workflow maintains business value
  • Governance applied progressively without disrupting access
  • Internal MOUNTAINPEAK_ANALYST role shows flexible control
  • External brokers get valuable insights with protected data

🔸 Next Steps:
  • Scale to additional broker partners
  • Implement ML-enhanced risk scoring
  • Expand to real-time fraud detection
  • Add Marketplace listing for self-service access

"Alpine Risk Brokers gets valuable risk insights for better business decisions,
while MountainPeak's sensitive data stays fully protected. This is the power
of Snowflake's intelligent data sharing with progressive governance."
***************************************************************************************************/ 