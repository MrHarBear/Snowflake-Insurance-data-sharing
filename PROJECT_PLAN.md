# 📋 SNOWFLAKE INSURANCE DATA SHARING DEMO - PROJECT PLAN

## 🎯 PROJECT OVERVIEW

**Project Name**: MountainPeak Insurance Risk Analytics & Secure Data Sharing Demo  
**Objective**: Demonstrate Snowflake's end-to-end capabilities: Build → Share → Protect  
**Target Audience**: Insurance business evaluation audience  
**Duration**: 40 minutes total (5 min setup + 35 min demo)

### Business Scenario
- **Data Provider**: MountainPeak Insurance
- **Data Consumer**: Alpine Risk Brokers  
- **Use Case**: Share risk-enriched data while progressively applying governance
- **Key Message**: "Build value first, then protect it intelligently"

---

## 📊 DATA SOURCES & ARCHITECTURE

### Available CSV Data
- **CLAIMS_DATA.csv**: 1,002 records (policy numbers, claim amounts, fraud indicators)
- **CUSTOMER_DATA.csv**: 1,202 records (demographics, policy details)

### Target Database Structure
```
MOUNTAINPEAK_INSURANCE_DB
├── RAW_DATA → CLAIMS_RAW, CUSTOMER_RAW
├── ANALYTICS → CUSTOMER_CLAIMS_JOINED, RISK_LEVEL_MATRIX
├── GOVERNANCE → Policies (4 types)
└── SHARING → BROKER_SHARED_VIEW
```

---

## 🔄 DEMO FLOW (Revised Order)

### 1. Setup (5 min) - `00_INSURANCE_SETUP.sql`
- Environment creation
- Git integration + CSV loading  
- Role setup (ACCOUNTADMIN, ANALYST, PUBLIC)

### 2. Data Integration (7 min) - `01_INSURANCE_DEMO.sql` Section 1
- Join customer + claims data
- Create unified dataset

### 3. Risk Analytics (5 min) - Section 2  
- Build Risk Level Matrix (Dynamic Table)
- Automated risk scoring logic

### 4. Data Sharing (8 min) - Section 3
- Create share with full access
- Demonstrate business value

### 5. Progressive Governance (15 min) - Section 4
- **Step 1**: Dynamic Masking (claim amounts)
- **Step 2**: Row Access (geographic restrictions)  
- **Step 3**: Aggregation Policy (min group sizes)
- **Step 4**: Projection Policy (hide fraud column)

---

## 👥 ROLE ARCHITECTURE & ACCESS LEVELS

| Role/Account | Claim Amounts | Geography | Fraud Data | Min Groups |
|--------------|---------------|-----------|------------|------------|
| ACCOUNTADMIN | Full | All States | Visible | No |
| ANALYST | Full | All States | Visible | No |
| Alpine Brokers | Floored to $10k | CO/UT/WY only | Hidden | 20+ records |

---

## 🛡️ GOVERNANCE POLICIES (Simplified - 1 Each)

### 1. Dynamic Masking Policy
```sql
MASK_CLAIM_AMOUNT:
- ACCOUNTADMIN/ANALYST: $67,432 (full amount)
- External Account: $60,000 (floored to nearest $10k)
```

### 2. Row Access Policy  
```sql
ALPINE_BROKER_ACCESS:
- Alpine Brokers: Colorado, Utah, Wyoming customers only
- Internal roles: All customer locations
```

### 3. Aggregation Policy
```sql
MIN_GROUP_POLICY:
- External accounts: Minimum 20 records per query
- Internal roles: No restrictions
```

### 4. Projection Policy
```sql
HIDE_FRAUD_INDICATOR:
- External accounts: FRAUD_REPORTED column hidden
- Internal roles: Full column access
```

---

## 📈 DYNAMIC TABLE: RISK_LEVEL_MATRIX

### Input: Joined customer + claims data
### Logic:
```sql
RISK_LEVEL = CASE
  WHEN age < 25 OR claim_amount > 75000 OR fraud_reported = true THEN 'HIGH'
  WHEN age BETWEEN 25-45 AND claim_amount BETWEEN 25000-75000 THEN 'MEDIUM'
  ELSE 'LOW'
END

RISK_SCORE = age_factor + claim_factor + fraud_factor (0-100)
```
### Refresh: Every 4 hours

---

## 🎭 KEY DEMO MOMENTS & NARRATIVE

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

## 🗂️ DELIVERABLES (2 Scripts Only)

1. **00_INSURANCE_SETUP.sql** (~150 lines)
   - Complete environment setup
   - Git integration + data loading
   - Role configuration

2. **01_INSURANCE_DEMO.sql** (~400 lines)  
   - Section 1: Data Integration
   - Section 2: Risk Matrix (Dynamic Table)
   - Section 3: Data Sharing
   - Section 4: Progressive Governance (4 steps)

3. **Supporting Docs**:
   - Talk track narrative
   - README with setup instructions

---

## ⏱️ TIMING BREAKDOWN

### Setup: 5 minutes
- Environment + Git + Data loading

### Demo Presentation: 35 minutes
- **Data Integration**: 7 min
- **Risk Analytics**: 5 min  
- **Data Sharing**: 8 min
- **Progressive Governance**: 15 min (4 min per policy)

---

## 🎯 SUCCESS CRITERIA

### Technical Validation
- [ ] All CSV data loaded (1,202 customers + 1,002 claims)
- [ ] Dynamic Table refreshing automatically
- [ ] All 4 governance policies functional
- [ ] Role switching demonstrates different access
- [ ] Cross-account sharing working

### Business Impact
- [ ] Clear value proposition for data sharing
- [ ] Risk analytics provide actionable insights  
- [ ] Governance compliance demonstrated
- [ ] Progressive protection story compelling

---

## 🚨 RISK MITIGATION

### Technical Risks
- **Git failure**: Pre-loaded CSV backup
- **Sharing issues**: Same-account role simulation
- **Performance**: Optimized queries + appropriate sizing

### Presentation Risks  
- **Complexity**: Clear business narrative first
- **Interruptions**: Modular sections allow restarts
- **Questions**: Comprehensive FAQ prepared

---

## 🎨 BRANDING (Snowflake Colors)

```sql
-- 🔵 MAIN SECTIONS (Snowflake Blue #29B5E8)
-- ⚫ CRITICAL INFO (Midnight #000000)
-- 🔷 SUBSECTIONS (Mid-Blue #11567F)  
-- 🔸 WARNINGS (Valencia Orange #FF9F36)
-- 🟣 ADVANCED FEATURES (Purple Moon #7254A3)
```

---

## ✅ FINAL REQUIREMENTS CHECK

- [x] **2-script approach** (setup + demo)
- [x] **Progressive governance** (build → share → protect)  
- [x] **Single policy each type** (focused demo)
- [x] **Risk matrix Dynamic Table** (automated analytics)
- [x] **ANALYST role included** (internal governance)
- [x] **Insurance scenario** (MountainPeak + Alpine)
- [x] **40-minute timing** (5 setup + 35 demo)

---

**🚀 READY FOR IMPLEMENTATION**

This project plan provides the complete blueprint for a compelling Snowflake insurance data sharing demo that showcases technical capabilities while telling a clear business story.

**AWAITING APPROVAL TO CREATE THE 2 SQL SCRIPTS** 