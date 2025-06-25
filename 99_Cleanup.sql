/*
================================================================================
🧹 MOUNTAINPEAK INSURANCE DATA SHARING DEMO - CLEANUP SCRIPT
================================================================================
🎯 Purpose: Remove all artifacts created during the insurance data sharing demo
🏢 Scenario: MountainPeak Insurance → Alpine Risk Brokers
📅 Created: December 2024
🎨 Branding: Snowflake Colors
   • Main Blue: #29B5E8    • Midnight: #000000
   • Mid-Blue: #11567F     • Medium Gray: #5B5B5B

⚠️  WARNING: This script will permanently delete all demo artifacts!
================================================================================
*/

-- Set context
USE ROLE ACCOUNTADMIN;

/*
================================================================================
🎯 SECTION 1: REMOVE DATA SHARING ARTIFACTS
================================================================================
*/

-- Remove shares (if they exist)
DROP SHARE IF EXISTS MOUNTAINPEAK_RISK_SHARE;

-- Remove outbound share recipients (if any were created)
-- Note: These would be removed automatically when share is dropped

/*
================================================================================
🎯 SECTION 2: REMOVE GOVERNANCE POLICIES
================================================================================
*/

-- Remove masking policies
ALTER TABLE MOUNTAINPEAK_INSURANCE_DB.ANALYTICS.RISK_LEVEL_MATRIX 
    MODIFY COLUMN CLAIM_AMOUNT_FILLED 
    UNSET MASKING POLICY;

DROP MASKING POLICY IF EXISTS MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.MASK_CLAIM_AMOUNT;

-- Remove row access policies  
ALTER TABLE MOUNTAINPEAK_INSURANCE_DB.ANALYTICS.RISK_LEVEL_MATRIX
    DROP ROW ACCESS POLICY MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.ALPINE_BROKER_ACCESS;

DROP ROW ACCESS POLICY IF EXISTS MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.ALPINE_BROKER_ACCESS;

-- Remove aggregation policies
ALTER TABLE MOUNTAINPEAK_INSURANCE_DB.ANALYTICS.RISK_LEVEL_MATRIX
    UNSET AGGREGATION POLICY;

DROP AGGREGATION POLICY IF EXISTS MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.MIN_GROUP_POLICY;

-- Remove projection policies
ALTER TABLE MOUNTAINPEAK_INSURANCE_DB.ANALYTICS.RISK_LEVEL_MATRIX
    MODIFY COLUMN FRAUD_REPORTED_FILLED
    UNSET PROJECTION POLICY;

DROP PROJECTION POLICY IF EXISTS MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.HIDE_FRAUD_INDICATOR;

/*
================================================================================
🎯 SECTION 3: REMOVE DYNAMIC TABLES AND VIEWS
================================================================================
*/

-- Remove secure views
DROP VIEW IF EXISTS MOUNTAINPEAK_INSURANCE_DB.ANALYTICS.VW_RISK_LEVEL_MATRIX;

-- Remove dynamic tables
DROP DYNAMIC TABLE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.ANALYTICS.RISK_LEVEL_MATRIX;

/*
================================================================================
🎯 SECTION 4: REMOVE TABLES
================================================================================
*/

-- Remove tables in dependency order
DROP TABLE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.SHARING.BROKER_DATA_CLONE;
DROP TABLE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.BROKER_TERRITORY_MAP;
DROP TABLE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.ANALYTICS.CUSTOMER_CLAIMS_JOINED;
DROP TABLE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.RAW_DATA.CLAIMS_RAW;
DROP TABLE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.RAW_DATA.CUSTOMER_RAW;

/*
================================================================================
🎯 SECTION 5: REMOVE STAGES AND GIT INTEGRATION
================================================================================
*/

-- Remove stages
DROP STAGE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.RAW_DATA.INSURANCE_CSV_STAGE;
DROP STAGE IF EXISTS MOUNTAINPEAK_INSURANCE_DB.RAW_DATA.INSURANCE_WORK_STAGE;

-- Remove Git repository integration
DROP GIT REPOSITORY IF EXISTS MOUNTAINPEAK_INSURANCE_DB.RAW_DATA.INSURANCE_DEMO_REPO;

-- Remove Git API integration
DROP API INTEGRATION IF EXISTS INSURANCE_GIT_INTEGRATION;

/*
================================================================================
🎯 SECTION 6: REMOVE WAREHOUSES
================================================================================
*/

-- Remove warehouses
DROP WAREHOUSE IF EXISTS INSURANCE_COMPUTE_WH;
DROP WAREHOUSE IF EXISTS INSURANCE_SHARING_WH;

/*
================================================================================
🎯 SECTION 7: REMOVE ROLES AND PRIVILEGES
================================================================================
*/

-- Remove role grants from users (replace with actual usernames if needed)
-- REVOKE ROLE MOUNTAINPEAK_ANALYST FROM USER your_username;

-- Remove custom roles
DROP ROLE IF EXISTS MOUNTAINPEAK_ANALYST;

/*
================================================================================
🎯 SECTION 8: REMOVE DATABASE AND SCHEMAS
================================================================================
*/

-- Remove database (this will also remove all schemas and their contents)
DROP DATABASE IF EXISTS MOUNTAINPEAK_INSURANCE_DB;

/*
================================================================================
🎯 SECTION 9: REMOVE TAGS (if any were created)
================================================================================
*/

-- Remove any custom tags that might have been created
-- DROP TAG IF EXISTS MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.SENSITIVITY_LEVEL;
-- DROP TAG IF EXISTS MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE.DATA_CLASSIFICATION;

/*
================================================================================
🎯 SECTION 10: CLEANUP VERIFICATION
================================================================================
*/

-- Verify cleanup by checking for remaining objects
SELECT 'Checking for remaining MountainPeak objects...' AS cleanup_status;

-- Check for remaining databases
SHOW DATABASES LIKE 'MOUNTAINPEAK%';

-- Check for remaining warehouses  
SHOW WAREHOUSES LIKE '%INSURANCE%';

-- Check for remaining roles
SHOW ROLES LIKE 'MOUNTAINPEAK%';

-- Check for remaining shares
SHOW SHARES LIKE 'MOUNTAINPEAK%';

-- Check for remaining integrations
SHOW INTEGRATIONS LIKE '%INSURANCE%';