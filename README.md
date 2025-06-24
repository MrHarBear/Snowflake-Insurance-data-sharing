# 🔵 MountainPeak Insurance Data Sharing Demo

## Overview

This demonstration showcases Snowflake's progressive data sharing capabilities through an insurance business scenario where **MountainPeak Insurance** shares risk analytics with **Alpine Risk Brokers** while applying intelligent governance controls.

**Key Message**: *Build value first, then protect it intelligently*

---

## 🎯 Demo Objectives

- **Build**: Integrate customer and claims data with automated risk scoring
- **Share**: Provide immediate business value through secure data sharing  
- **Protect**: Apply progressive governance without breaking functionality

---

## 📊 Business Scenario

### Participants
- **Data Provider**: MountainPeak Insurance (Primary Account)
- **Data Consumer**: Alpine Risk Brokers (Partner Account)

### Use Case
Share claims and customer data with risk level insights to help brokers understand their book of business risk profile and make better underwriting decisions.

---

## 🗂️ Repository Contents

### Core Scripts
- `00_INSURANCE_SETUP.sql` - Complete environment setup (5 minutes)
- `01_INSURANCE_DEMO.sql` - Full demo progression (35 minutes)

### Documentation
- `PROJECT_PLAN.md` - Comprehensive project blueprint
- `README.md` - This setup and execution guide
- `INSURANCE_DEMO_TALK_TRACK.md` - Presentation narrative and talking points

### Data Sources
- `CLAIMS_DATA.csv` - 1,002 claim records with fraud indicators
- `CUSTOMER_DATA.csv` - 1,202 customer records with demographics

---

## 🚀 Quick Start

### Prerequisites
- Snowflake account with ACCOUNTADMIN privileges
- Git integration capabilities enabled
- Secondary account for cross-account sharing (optional)

### Step 1: Environment Setup
```sql
-- Execute the setup script
-- Runtime: ~5 minutes
USE ROLE ACCOUNTADMIN;
-- Run 00_INSURANCE_SETUP.sql
```

### Step 2: Demo Execution
```sql
-- Execute the main demo
-- Runtime: ~35 minutes
-- Run 01_INSURANCE_DEMO.sql section by section
```

---

## 📈 Demo Flow & Timing

### Total Duration: 40 minutes

#### Setup Phase (5 minutes)
- Database/schema/warehouse creation
- Git integration and data loading
- Role configuration and privileges

#### Section 1: Data Integration (7 minutes)
- Join customer and claims data
- Create unified analytics dataset
- Business insights by occupation

#### Section 2: Risk Analytics (5 minutes)  
- Build Risk Level Matrix (Dynamic Table)
- Automated risk scoring logic
- Portfolio risk distribution analysis

#### Section 3: Data Sharing (8 minutes)
- Create secure view for sharing
- Demonstrate business value
- Zero-copy cloning showcase

#### Section 4: Progressive Governance (15 minutes)
- **Step 1**: Dynamic Masking (4 min) - Claim amount protection
- **Step 2**: Row Access Policy (4 min) - Geographic restrictions  
- **Step 3**: Aggregation Policy (3 min) - Privacy through group sizes
- **Step 4**: Projection Policy (4 min) - Hide fraud indicators

---

## 🛡️ Governance Policies Demonstrated

### 1. Dynamic Masking Policy
**Purpose**: Protect claim amount sensitivity while maintaining analytical value

| Role | Access Level | Example |
|------|-------------|---------|
| ACCOUNTADMIN | Full amount | $67,432 |
| MOUNTAINPEAK_ANALYST | Full amount | $67,432 |
| External Account | Floored to $10k | $60,000 |

### 2. Row Access Policy  
**Purpose**: Geographic territory restrictions for broker partners

| Account | Geographic Access |
|---------|------------------|
| Alpine Risk Brokers | Colorado, Utah, Wyoming only |
| Internal roles | All customer locations |

### 3. Aggregation Policy
**Purpose**: Statistical privacy protection through minimum group sizes

| Account Type | Restriction |
|--------------|-------------|
| External accounts | Minimum 20 records per query |
| Internal roles | No aggregation restrictions |

### 4. Projection Policy
**Purpose**: Hide most sensitive column from external selection

| Account Type | Fraud Data Access |
|--------------|-------------------|
| External accounts | FRAUD_REPORTED column hidden from SELECT |
| Internal roles | Full column access |

---

## 🎭 Key Demo Moments

### Opening Hook
*"Watch MountainPeak Insurance build risk analytics, share with partners, then intelligently protect sensitive data - all in real-time."*

### Risk Analytics Value
*"Dynamic Tables automatically calculate risk levels every 4 hours. Alpine Brokers get real-time portfolio insights."*

### Progressive Governance Story
*"Now let's protect sensitive data step-by-step without breaking business value:"*

1. **Masking**: "Claim amounts protected but still useful"
2. **Row Access**: "Brokers see only their territory"  
3. **Aggregation**: "Privacy through minimum group sizes"
4. **Projection**: "Fraud data hidden from partners"

### Closing Impact
*"Brokers get valuable insights, MountainPeak's data stays protected. Internal ANALYST role shows flexible governance."*

---

## 🏗️ Technical Architecture

### Database Structure
```
MOUNTAINPEAK_INSURANCE_DB
├── RAW_DATA
│   ├── CLAIMS_RAW (1,002 records)
│   └── CUSTOMER_RAW (1,202 records)
├── ANALYTICS  
│   ├── CUSTOMER_CLAIMS_JOINED (integrated dataset)
│   └── RISK_LEVEL_MATRIX (Dynamic Table)
├── GOVERNANCE
│   ├── MASK_CLAIM_AMOUNT (masking policy)
│   ├── ALPINE_BROKER_ACCESS (row access policy)
│   ├── MIN_GROUP_POLICY (aggregation policy)
│   └── HIDE_FRAUD_INDICATOR (projection policy)
└── SHARING
    └── BROKER_SHARED_VIEW (secure view)
```

### Role Architecture
- **ACCOUNTADMIN**: Full system access
- **MOUNTAINPEAK_ANALYST**: Internal user with governance demonstrations
- **Alpine Risk Brokers Account**: External access with restrictions

---

## 🎯 Success Criteria

### Technical Validation
- [ ] All 1,202 customer records and 1,002 claim records loaded
- [ ] Dynamic Table refreshes automatically every 4 hours
- [ ] All 4 governance policies function correctly
- [ ] Role switching demonstrates different access levels
- [ ] Zero-copy cloning operational

### Business Value Demonstration  
- [ ] Clear ROI story for data sharing initiative
- [ ] Risk analytics provide actionable insights
- [ ] Governance compliance visibly maintained
- [ ] Progressive protection maintains business value

---

## 🚨 Troubleshooting

### Common Issues

#### Git Integration Fails
```sql
-- Fallback: Manual data loading
-- Upload CSV files to internal stage manually
PUT file://CLAIMS_DATA.csv @INSURANCE_CSV_STAGE;
PUT file://CUSTOMER_DATA.csv @INSURANCE_CSV_STAGE;
```

#### Dynamic Table Refresh Delays
```sql
-- Manual refresh if needed
ALTER DYNAMIC TABLE ANALYTICS.RISK_LEVEL_MATRIX REFRESH;
```

#### Cross-Account Sharing Issues
```sql
-- Simulate with same-account roles
-- Use MOUNTAINPEAK_ANALYST as "external" user proxy
```

#### Performance Issues
```sql
-- Add LIMIT clauses to reduce result sets
-- Ensure warehouse is properly sized (XSMALL sufficient)
```

---

## 🔄 Demo Execution Tips

### Presentation Flow
1. **Start with business context** - Set the insurance scenario
2. **Show data integration** - Emphasize unified view value
3. **Highlight automation** - Dynamic Tables refresh capability  
4. **Demonstrate sharing** - Immediate business value
5. **Apply governance progressively** - Show before/after for each policy
6. **Close with impact** - Business value + data protection

### Role Switching
- Use `USE ROLE ACCOUNTADMIN;` and `USE ROLE MOUNTAINPEAK_ANALYST;` 
- Show different data access levels
- Explain internal vs external governance

### Timing Management
- Each section has natural pause points
- Use validation queries as discussion moments
- Business insights provide presentation value

---

## 📚 Additional Resources

### Snowflake Documentation
- [Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro)
- [Data Sharing](https://docs.snowflake.com/en/user-guide/data-sharing-intro)
- [Data Governance](https://docs.snowflake.com/en/user-guide/security-access-control-overview)

### Demo Extensions
- Add ML-enhanced risk scoring with Cortex
- Implement real-time fraud detection
- Create Marketplace listing for self-service
- Scale to multiple broker partners

---

## ✅ Demo Checklist

### Pre-Demo Setup
- [ ] Snowflake account accessible with ACCOUNTADMIN
- [ ] Git repository accessible 
- [ ] CSV files available
- [ ] Secondary account for sharing (optional)
- [ ] Warehouse resources sized appropriately

### During Demo
- [ ] Setup script executed successfully
- [ ] Data loading validated
- [ ] Each section executes cleanly
- [ ] Role switching works as expected
- [ ] All governance policies applied

### Post-Demo
- [ ] Business value clearly articulated
- [ ] Technical capabilities demonstrated
- [ ] Questions addressed effectively
- [ ] Next steps outlined

---

**🎉 Ready to demonstrate the power of Snowflake's intelligent data sharing with progressive governance!** 