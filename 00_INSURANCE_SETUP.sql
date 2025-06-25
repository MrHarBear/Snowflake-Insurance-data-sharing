/*
================================================================================
MOUNTAINPEAK INSURANCE - ENVIRONMENT SETUP
================================================================================
Demo:    MountainPeak Insurance Risk Analytics & Secure Data Sharing  
Purpose: Complete environment setup for insurance data sharing demonstration
Data:    Customer and Claims CSV files via Git integration
================================================================================
*/

-- Initial setup and enable Cortex
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- Clean start - remove any existing demo objects
DROP DATABASE IF EXISTS MOUNTAINPEAK_INSURANCE_DB;

/*
================================================================================
DATABASE & WAREHOUSE CREATION
================================================================================
*/

-- Create main database and schemas
CREATE DATABASE MOUNTAINPEAK_INSURANCE_DB
    COMMENT = 'MountainPeak Insurance - Risk Analytics and Data Sharing Demo Database';

CREATE SCHEMA MOUNTAINPEAK_INSURANCE_DB.RAW_DATA 
    COMMENT = 'Raw insurance data from CSV sources';

CREATE SCHEMA MOUNTAINPEAK_INSURANCE_DB.ANALYTICS 
    COMMENT = 'Processed analytics and risk scoring tables';
    
CREATE SCHEMA MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE 
    COMMENT = 'Data governance policies and controls';
    
CREATE SCHEMA MOUNTAINPEAK_INSURANCE_DB.SHARING 
    COMMENT = 'Views and objects for secure data sharing';

-- Set working context
USE DATABASE MOUNTAINPEAK_INSURANCE_DB;
USE SCHEMA RAW_DATA;

-- Create compute warehouses for demo workloads
CREATE OR REPLACE WAREHOUSE INSURANCE_COMPUTE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    RESOURCE_CONSTRAINT = 'STANDARD_GEN_2'
    COMMENT = 'Main compute warehouse for insurance demo operations';

CREATE OR REPLACE WAREHOUSE INSURANCE_SHARING_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    COMMENT = 'Dedicated warehouse for data sharing operations';

USE WAREHOUSE INSURANCE_COMPUTE_WH;

/*
================================================================================
ROLE-BASED ACCESS CONTROL SETUP
================================================================================
*/

-- Create internal analyst role for demonstrating role-based governance
USE ROLE USERADMIN;
CREATE OR REPLACE ROLE MOUNTAINPEAK_ANALYST
    COMMENT = 'Internal analyst role - demonstrates governance policies';

-- Grant warehouse and database privileges
USE ROLE SECURITYADMIN;
GRANT USAGE, OPERATE ON WAREHOUSE INSURANCE_COMPUTE_WH TO ROLE MOUNTAINPEAK_ANALYST;
GRANT USAGE ON WAREHOUSE INSURANCE_SHARING_WH TO ROLE MOUNTAINPEAK_ANALYST;

GRANT USAGE ON DATABASE MOUNTAINPEAK_INSURANCE_DB TO ROLE MOUNTAINPEAK_ANALYST;
GRANT USAGE ON SCHEMA MOUNTAINPEAK_INSURANCE_DB.RAW_DATA TO ROLE MOUNTAINPEAK_ANALYST;
GRANT USAGE ON SCHEMA MOUNTAINPEAK_INSURANCE_DB.ANALYTICS TO ROLE MOUNTAINPEAK_ANALYST;
GRANT USAGE ON SCHEMA MOUNTAINPEAK_INSURANCE_DB.GOVERNANCE TO ROLE MOUNTAINPEAK_ANALYST;
GRANT USAGE ON SCHEMA MOUNTAINPEAK_INSURANCE_DB.SHARING TO ROLE MOUNTAINPEAK_ANALYST;

-- Grant object creation privileges needed for demo
GRANT CREATE TABLE, CREATE VIEW, CREATE DYNAMIC TABLE ON SCHEMA MOUNTAINPEAK_INSURANCE_DB.RAW_DATA TO ROLE MOUNTAINPEAK_ANALYST;
GRANT CREATE TABLE, CREATE VIEW, CREATE DYNAMIC TABLE ON SCHEMA MOUNTAINPEAK_INSURANCE_DB.ANALYTICS TO ROLE MOUNTAINPEAK_ANALYST;
GRANT CREATE VIEW ON SCHEMA MOUNTAINPEAK_INSURANCE_DB.SHARING TO ROLE MOUNTAINPEAK_ANALYST;

-- Grant role to current user
SET MY_USER_ID = CURRENT_USER();
GRANT ROLE MOUNTAINPEAK_ANALYST TO USER identifier($MY_USER_ID);

USE ROLE ACCOUNTADMIN;

/*
================================================================================
GIT INTEGRATION FOR DATA SOURCES
================================================================================
*/

-- Create Git API integration for repository access
CREATE OR REPLACE API INTEGRATION INSURANCE_GIT_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com')
    ENABLED = TRUE
    COMMENT = 'Git integration for MountainPeak Insurance demo data sources';

-- Create Git repository connection to demo data
CREATE OR REPLACE GIT REPOSITORY INSURANCE_DEMO_REPO
    API_INTEGRATION = INSURANCE_GIT_INTEGRATION
    ORIGIN = 'https://github.com/MrHarBear/Snowflake-Insurance-data-sharing.git'
    GIT_CREDENTIALS = NULL
    COMMENT = 'Repository containing insurance demo CSV files';

-- Refresh repository to get latest files
ALTER GIT REPOSITORY INSURANCE_DEMO_REPO FETCH;

/*
================================================================================
INTERNAL STAGES FOR DATA LOADING
================================================================================
*/

-- Create internal stages for CSV file management
CREATE OR REPLACE STAGE INSURANCE_CSV_STAGE
    DIRECTORY = ( ENABLE = true )
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' )
    COMMENT = 'Internal stage for insurance CSV files';

CREATE OR REPLACE STAGE INSURANCE_WORK_STAGE
    DIRECTORY = ( ENABLE = true )
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' )
    COMMENT = 'Working stage for data processing operations';

/*
================================================================================
CSV DATA LOADING
================================================================================
*/

-- Load CSV files from Git repository to internal stage
COPY FILES
    INTO @INSURANCE_CSV_STAGE
    FROM '@INSURANCE_DEMO_REPO/branches/main/'
    PATTERN='CLAIMS_DATA.csv';

COPY FILES
    INTO @INSURANCE_CSV_STAGE
    FROM '@INSURANCE_DEMO_REPO/branches/main/'
    PATTERN='CUSTOMER_DATA.csv';

-- Verify files are loaded
LIST @INSURANCE_CSV_STAGE;

/*
================================================================================
RAW DATA TABLES CREATION
================================================================================
*/

-- Create raw claims table with proper data types
CREATE OR REPLACE TABLE RAW_DATA.CLAIMS_RAW (
    POLICY_NUMBER VARCHAR(50),
    INCIDENT_DATE TIMESTAMP_NTZ,
    INCIDENT_TYPE VARCHAR(100),
    INCIDENT_SEVERITY VARCHAR(50),
    AUTHORITIES_CONTACTED VARCHAR(50),
    INCIDENT_HOUR_OF_THE_DAY NUMBER,
    NUMBER_OF_VEHICLES_INVOLVED NUMBER,
    BODILY_INJURIES NUMBER,
    WITNESSES NUMBER,
    POLICE_REPORT_AVAILABLE VARCHAR(10),
    CLAIM_AMOUNT NUMBER(10,2),
    FRAUD_REPORTED BOOLEAN
) COMMENT = 'Raw claims data from CSV source - 1,002 records';

-- Create raw customer table with proper data types
CREATE OR REPLACE TABLE RAW_DATA.CUSTOMER_RAW (
    POLICY_NUMBER VARCHAR(50),
    AGE NUMBER,
    POLICY_START_DATE TIMESTAMP_NTZ,
    POLICY_LENGTH_MONTH NUMBER,
    POLICY_DEDUCTABLE NUMBER(10,2),
    POLICY_ANNUAL_PREMIUM NUMBER(10,2),
    INSURED_SEX VARCHAR(10),
    INSURED_EDUCATION_LEVEL VARCHAR(50),
    INSURED_OCCUPATION VARCHAR(100)
) COMMENT = 'Raw customer data from CSV source - 1,202 records';

-- Load data from staged CSV files
COPY INTO RAW_DATA.CLAIMS_RAW
FROM @INSURANCE_CSV_STAGE/CLAIMS_DATA.csv
FILE_FORMAT = (
    TYPE = CSV,
    SKIP_HEADER = 1,
    FIELD_DELIMITER = ',',
    RECORD_DELIMITER = '\n',
    TRIM_SPACE = TRUE,
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE,
    REPLACE_INVALID_CHARACTERS = TRUE,
    DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF3',
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF3'
);

COPY INTO RAW_DATA.CUSTOMER_RAW  
FROM @INSURANCE_CSV_STAGE/CUSTOMER_DATA.csv
FILE_FORMAT = (
    TYPE = CSV,
    SKIP_HEADER = 1,
    FIELD_DELIMITER = ',',
    RECORD_DELIMITER = '\n',
    TRIM_SPACE = TRUE,
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE,
    REPLACE_INVALID_CHARACTERS = TRUE,
    DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF3',
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF3'
);

/*
================================================================================
DATA VALIDATION AND QUALITY CHECKS
================================================================================
*/

-- Validate data loading success
SELECT 'CLAIMS_RAW' as TABLE_NAME, COUNT(*) as RECORD_COUNT FROM RAW_DATA.CLAIMS_RAW
UNION ALL
SELECT 'CUSTOMER_RAW' as TABLE_NAME, COUNT(*) as RECORD_COUNT FROM RAW_DATA.CUSTOMER_RAW;

-- Basic data quality samples
SELECT 
    'Claims Data Sample' as DATA_TYPE,
    POLICY_NUMBER,
    INCIDENT_TYPE,
    CLAIM_AMOUNT,
    FRAUD_REPORTED
FROM RAW_DATA.CLAIMS_RAW 
LIMIT 5;

SELECT 
    'Customer Data Sample' as DATA_TYPE,
    POLICY_NUMBER,
    AGE,
    INSURED_OCCUPATION,
    POLICY_ANNUAL_PREMIUM
FROM RAW_DATA.CUSTOMER_RAW 
LIMIT 5;

-- Check for policy number overlap for joins
SELECT 
    COUNT(DISTINCT c.POLICY_NUMBER) as CUSTOMER_POLICIES,
    COUNT(DISTINCT cl.POLICY_NUMBER) as CLAIM_POLICIES,
    COUNT(DISTINCT c.POLICY_NUMBER) - COUNT(DISTINCT cl.POLICY_NUMBER) as POLICY_DIFFERENCE
FROM RAW_DATA.CUSTOMER_RAW c
FULL OUTER JOIN RAW_DATA.CLAIMS_RAW cl ON c.POLICY_NUMBER = cl.POLICY_NUMBER;

/*
================================================================================
INITIAL PRIVILEGE GRANTS
================================================================================
*/

-- Grant analyst role access to raw data tables
GRANT SELECT ON TABLE RAW_DATA.CLAIMS_RAW TO ROLE MOUNTAINPEAK_ANALYST;
GRANT SELECT ON TABLE RAW_DATA.CUSTOMER_RAW TO ROLE MOUNTAINPEAK_ANALYST;

-- Grant access to stages for potential data operations
GRANT USAGE ON STAGE INSURANCE_CSV_STAGE TO ROLE MOUNTAINPEAK_ANALYST;
GRANT USAGE ON STAGE INSURANCE_WORK_STAGE TO ROLE MOUNTAINPEAK_ANALYST;

/*
================================================================================
SETUP COMPLETION VALIDATION
================================================================================
*/

-- Final setup validation
SELECT 
    'SETUP COMPLETE' as STATUS,
    CURRENT_DATABASE() as ACTIVE_DATABASE,
    CURRENT_SCHEMA() as ACTIVE_SCHEMA,
    CURRENT_WAREHOUSE() as ACTIVE_WAREHOUSE,
    CURRENT_ROLE() as ACTIVE_ROLE;

-- Environment summary
SELECT 
    'Database Objects Created' as COMPONENT,
    'MOUNTAINPEAK_INSURANCE_DB with 4 schemas' as DETAILS
UNION ALL
SELECT 
    'Warehouses Created',
    'INSURANCE_COMPUTE_WH, INSURANCE_SHARING_WH'
UNION ALL
SELECT 
    'Roles Created',
    'MOUNTAINPEAK_ANALYST with appropriate privileges'
UNION ALL
SELECT 
    'Data Tables Created',
    'CLAIMS_RAW, CUSTOMER_RAW with CSV data loaded'
UNION ALL
SELECT 
    'Git Integration',
    'Repository connected with file access enabled';

-- Ready for main demo
SELECT 
    'MOUNTAINPEAK INSURANCE SETUP COMPLETE' as MESSAGE,
    'Ready to execute 01_INSURANCE_DEMO.sql' as NEXT_STEP,
    'Environment configured for progressive governance demo' as DESCRIPTION;

/*
================================================================================
SETUP COMPLETE - READY FOR DEMO
================================================================================
Environment Ready:
  • Database: MOUNTAINPEAK_INSURANCE_DB with 4 schemas
  • Warehouses: Optimized for demo workloads  
  • Roles: MOUNTAINPEAK_ANALYST configured
  • Data: Claims (1,002) and Customer (1,202) records loaded
  • Git: Repository integration established

Next Steps:
  1. Verify data loading completed successfully
  2. Execute 01_INSURANCE_DEMO.sql for main demonstration
  3. Follow progressive governance flow: Build → Share → Protect
================================================================================
*/ 