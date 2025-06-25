# MountainPeak Insurance Data Sharing Demo

## Overview

This demo showcases Snowflake's end-to-end capabilities for building risk analytics, sharing data securely, and applying progressive governance controls. The scenario demonstrates how **MountainPeak Insurance** shares risk-enriched customer data with **Alpine Risk Brokers** while progressively protecting sensitive information.

## Demo Flow

**Key Message**: "Build value first, then protect it intelligently"

### 1. Setup (5 minutes) - `00_INSURANCE_SETUP.sql`
- Environment creation (database, schemas, warehouses)
- Git integration for CSV data loading
- Role-based access control setup
- Raw data ingestion (1,202 customers + 1,002 claims)

### 2. Data Integration (7 minutes) - `01_INSURANCE_DEMO.sql` Section 1
- Join customer demographics with claims history
- Create unified analytics dataset

### 3. Risk Analytics (5 minutes) - Section 2
- Build automated Risk Level Matrix using Dynamic Tables
- Real-time risk scoring (HIGH/MEDIUM/LOW)
- Automated refresh every 4 hours

### 4. Data Sharing (8 minutes) - Section 3
- Create initial data share with full access
- Demonstrate business value and Zero-Copy Cloning
- Show broker perspective before governance

### 5. Progressive Governance (15 minutes) - Section 4
- **Step 1**: Dynamic Masking (claim amounts floored to $10K)
- **Step 2**: Row Access Policy (geographic restrictions to CO/UT/WY)
- **Step 3**: Aggregation Policy (minimum 20 records per query)
- **Step 4**: Projection Policy (hide fraud indicators)

## Files

1. **`00_INSURANCE_SETUP.sql`** - Complete environment setup
2. **`01_INSURANCE_DEMO.sql`** - Main progressive governance demonstration
3. **`99_Cleanup.sql`** - Clean removal of all demo artifacts
4. **`CLAIMS_DATA.csv`** - Sample claims data (1,002 records)
5. **`CUSTOMER_DATA.csv`** - Sample customer data (1,202 records)

## Setup Instructions

1. **Prerequisites**: Snowflake account with ACCOUNTADMIN privileges
2. **Run Setup**: Execute `00_INSURANCE_SETUP.sql` completely
3. **Validate**: Verify data loading completed successfully
4. **Demo**: Present using `01_INSURANCE_DEMO.sql`
5. **Cleanup**: Run `99_Cleanup.sql` to remove all artifacts

## Architecture

```
MOUNTAINPEAK_INSURANCE_DB
├── RAW_DATA (Schema)
│   ├── CLAIMS_RAW (1,002 records)
│   └── CUSTOMER_RAW (1,202 records)
├── ANALYTICS (Schema)
│   ├── CUSTOMER_CLAIMS_JOINED (integrated dataset)
│   ├── RISK_LEVEL_MATRIX (Dynamic Table)
│   └── VW_RISK_LEVEL_MATRIX (Secure View)
├── GOVERNANCE (Schema)
│   ├── MASK_CLAIM_AMOUNT (masking policy)
│   ├── ALPINE_BROKER_ACCESS (row access policy)
│   ├── MIN_GROUP_POLICY (aggregation policy)
│   └── HIDE_FRAUD_INDICATOR (projection policy)
└── SHARING (Schema)
    └── BROKER_DATA_CLONE (Zero-copy clone)
```

## Key Demo Points

### Business Value Preservation
- Risk analytics remain fully functional
- Brokers get actionable portfolio insights
- Premium-risk alignment validation
- Occupation-based underwriting recommendations

### Progressive Governance
- **Dynamic Masking**: Claim amounts protected but still analytically useful
- **Row Access**: Geographic territory restrictions
- **Aggregation**: Privacy through minimum group sizes
- **Projection**: Sensitive columns hidden from partners

### Role-Based Access
- **ACCOUNTADMIN**: Full access to all data and policies
- **MOUNTAINPEAK_ANALYST**: Simulates consumer experience with restrictions
- **External Accounts**: Would see fully governed data view

## Technical Features Demonstrated

- Git integration for data source management
- Dynamic Tables for automated refresh
- Zero-Copy Cloning for efficient data distribution
- Account-aware governance policies
- Progressive policy application without business disruption
- Cross-role access validation

## Success Metrics

- ✅ 1,202 customers and 1,002 claims loaded
- ✅ Dynamic Table refreshing every 4 hours
- ✅ All 4 governance policies functional
- ✅ Role switching demonstrates different access levels
- ✅ Business analytics preserved under governance
- ✅ Clean artifact removal via cleanup script

---

**Duration**: 40 minutes total (5 min setup + 35 min demo)
**Audience**: Insurance business evaluation teams  
**Complexity**: Intermediate to Advanced 