# Financial Risk & Transaction Intelligence Platform

An end-to-end analytics project built to understand **customer behavior, transaction activity, loan exposure, and account-level risk signals** for a fictional financial institution.

I used **MySQL, Python, and Power BI** to take the data from raw files through data cleaning and analysis and finally turn it into an interactive business intelligence dashboard.

> **Note:** This project uses a synthetic banking dataset. The customers, transactions, accounts, and loans are not real.

---

## What Was the Idea Behind This Project?

I wanted to build something closer to the type of analytics work a **Data Analyst or Business Analyst** might actually do in a financial services company.

Instead of focusing on just one dashboard, I worked through the complete process:

**Raw Data → Data Quality Checks → Data Cleaning → SQL Analytics → Python Analysis → Power BI**

The main questions I wanted to answer were:

- How much transaction activity is happening?
- Which transaction types contribute most to the transaction value?
- What does the customer base look like?
- Which customers have the highest financial value?
- How much money is currently exposed through loans?
- How much of the loan portfolio is overdue?
- Which accounts show unusual transaction behavior?
- Which accounts may deserve further investigation?
- Are there any important data-quality problems that could affect the analysis?

---

## Business Problem

A financial institution may have customer, account, transaction, and loan information stored across different datasets.

Looking at these datasets separately makes it difficult to get a complete picture of customer activity and financial risk.

This project brings these datasets together to create a single analytical view covering:

- Customers
- Accounts
- Transactions
- Loans
- Branches
- Customer segments
- Credit exposure
- Transaction behavior
- Risk signals

The final goal was to create something that could help an analyst or decision-maker quickly understand **where the important activity and potential risk areas are**.

---

## Dataset

The dataset is a **synthetic banking dataset** containing:

| Dataset | Records | Description |
|---|---:|---|
| Customers | 1,111 | Customer information |
| Accounts | 1,667 | Account details and balances |
| Transactions | 50,000 | Transaction activity |
| Loans | 333 | Loan portfolio |
| Addresses | 1,222 | Customer and branch address information |
| Branches | 50 | Branch information |

There are also lookup tables for:

- Customer types
- Account types
- Account statuses
- Transaction types
- Loan statuses

---

## Data Quality Work

Before doing the actual analysis, I first looked at the quality of the raw data.

This turned out to be an important part of the project because the dataset contained several intentional quality issues.

### Transactions

The raw transaction data contained:

- 50,000 records
- 49,500 unique transaction IDs
- 500 exact duplicate records
- 1,000 missing transaction dates

I removed the duplicate transaction IDs during the staging process.

I did **not** simply remove transactions with missing dates. Instead, I kept them in the dataset and flagged them as a data-quality issue.

### Customers

I found:

- 11 duplicate customer IDs
- 22 missing dates of birth
- 3 invalid dates of birth

After deduplication, the analytical customer dimension contains **1,100 customers**.

### Accounts

The account data contained:

- 16 duplicate account IDs
- 10 accounts with negative balances
- 33 missing opening dates

I treated negative balances as a condition that requires interpretation rather than automatically calling them errors.

### Loans

The raw loan data contained:

- 333 records
- 3 duplicate loan IDs

After removing the duplicate records, the analytical loan dataset contains **330 unique loans**.

### Addresses

I also found missing address information:

- 23 missing countries
- 26 missing cities
- 24 missing streets
- 12 duplicate address IDs

---

## Analytics Architecture

I structured the project into separate layers instead of connecting the raw data directly to Power BI.

```text
Raw Data
   ↓
Data Quality Checks
   ↓
Staging Layer
   ↓
Analytics Layer
   ↓
Python Analysis
   ↓
Power BI
```

The analytics layer follows a simple dimensional model:

```text
                 dim_customer
                      │
                      ▼
                 dim_account
                  │       │
                  ▼       ▼
        fact_transactions  fact_loans
              │                 │
              ▼                 ▼
     Transaction Type       Loan Status
```

Additional dimensions such as **Date** and **Branch** are used for analysis and reporting.

---

## Key Results

After cleaning and preparing the data, the main portfolio metrics were:

| Metric | Result |
|---|---:|
| Transactions | **49,500** |
| Transaction Value | **₹123.96M** |
| Average Transaction Value | **₹2,504.15** |
| Loan Exposure | **₹17.09M** |
| Overdue Loan Exposure | **₹1.67M** |
| Overdue Exposure | **9.78%** |
| Customers | **1,100** |
| Accounts | **1,651** |
| Loans | **330** |

---

## Transaction Analysis

The transaction data contains four main transaction types.

| Transaction Type | Transactions | Transaction Value |
|---|---:|---:|
| Deposit | 15,065 | ₹37.65M |
| Transfer | 14,771 | ₹37.18M |
| Withdrawal | 14,706 | ₹36.74M |
| Payment | 4,958 | ₹12.38M |

Deposits, transfers, and withdrawals are fairly evenly distributed, each accounting for around 30% of transaction activity/value.

Payments account for roughly 10%.

This suggests that transaction activity isn't heavily dependent on a single transaction type.

---

## Customer Segmentation

I used **Python and K-Means clustering** to group customers based on their observed financial behavior.

The features included:

- Number of accounts
- Total balance
- Average balance
- Transaction count
- Total transaction value
- Average transaction value

I tested different cluster sizes using the elbow method and silhouette scores before selecting a **3-segment solution**.

### Core Active

**651 customers**

This is the largest segment and represents the main active customer base.

It contributes approximately:

- **54.7% of measured account balance**
- **55.3% of transaction value**

### High-Value Active

**211 customers**

This is a smaller segment, but it represents a significant share of the financial value in the dataset.

It contributes approximately:

- **45.3% of measured account balance**
- **44.7% of transaction value**

This is an important finding because a relatively small group of customers represents a large portion of the financial value.

### No Financial Relationship

**238 customers**

These customers currently have no measured account balance or originating transaction activity in the analytical data.

This group could be worth investigating further from a customer activation perspective.

---

## Credit Risk Analysis

The loan portfolio contains approximately:

### ₹17.09M total loan exposure

Of this:

### ₹1.67M is overdue

That gives an overdue exposure ratio of:

### 9.78%

I also compared overdue exposure across customer types.

Large Enterprise customers have the highest overdue exposure, but the difference between Large Enterprise, Small Business, and Individual customers isn't large enough to conclude that one customer type is inherently more risky.

---

## Transaction Anomaly Analysis

One of the more interesting parts of the project was looking beyond static customer information and analyzing **transaction behavior at the account level**.

I created an anomaly score using three behavioral measures:

### Transaction Frequency

Does the account make significantly more transactions than the typical account?

### Total Transaction Value

Is the account's total transaction value unusually high?

### Average Transaction Size

Are the account's individual transactions unusually large on average?

I used a **2-standard-deviation threshold** for each measure.

Each account can therefore receive a score from **0 to 3**.

| Score | Signal |
|---:|---|
| 0 | Normal |
| 1 | Low Anomaly Signal |
| 2 | Moderate Anomaly Signal |
| 3 | High Anomaly Signal |

---

## Important Risk Disclaimer

The anomaly score **does not mean fraud**.

There is no confirmed fraud label in this dataset.

A high score simply means that an account's observed transaction behavior is unusually high compared with the overall behavioral baseline.

Therefore, these accounts should be viewed as:

> **Candidates for further investigation or monitoring**

rather than confirmed fraudulent accounts.

---

## Risk Prioritization

I combined the behavioral signals with credit information to create an **account-level risk prioritization view**.

The final view considers:

- Customer type
- Loan exposure
- Overdue exposure
- Transaction count
- Transaction value
- Average transaction size
- Anomaly score
- Risk signal

This allows an analyst to look beyond a single metric.

For example, an account with unusually high transaction activity **and** significant loan exposure may deserve more attention than an account that is unusual on only one dimension.

---

## Power BI Dashboard

The final Power BI report contains two pages.

### Executive Overview

The first page provides a high-level view of:

- Transaction activity
- Customer segmentation
- Balance contribution
- Loan exposure
- Overdue exposure
- Transaction data coverage

### Risk Intelligence

The second page focuses on:

- Transaction anomaly signals
- Credit exposure by risk signal
- Customer/loan/risk filters
- Account-level risk prioritization

The dashboard is designed so that someone can start with the overall portfolio and then move into specific risk areas.

---

## Data Coverage Limitation

One important issue I found during the analysis was the transaction timeline.

Most transaction activity is concentrated between:

**January 2020 and January 2024.**

There is then a major gap in the data, followed by sparse records later on.

Because of this, the decline shown after 2024 **should not be interpreted as an actual decline in business activity**.

This is a data-coverage limitation, not a business conclusion.

I deliberately highlighted this in the dashboard because understanding when **not to trust a trend** is an important part of analytics.

---

## Tools Used

### MySQL

Used for:

- Data-quality analysis
- Duplicate detection
- Data cleaning
- Staging
- Joins and aggregations
- Window functions
- Dimensional modelling
- Business analysis
- Risk scoring

### Python

Used for:

- Exploratory data analysis
- Data preparation
- Statistical analysis
- Customer segmentation
- K-Means clustering
- Anomaly analysis
- Visualization

Main libraries:

- Pandas
- NumPy
- Matplotlib
- Scikit-learn
- SciPy
- SQLAlchemy
- PyMySQL

### Power BI

Used for:

- Data modelling
- DAX measures
- KPI development
- Interactive dashboards
- Customer segmentation analysis
- Credit-risk analysis
- Risk prioritization

---

## Project Structure

```text
financial-risk-transaction-intelligence/
│
├── README.md
│
├── data/
│   └── processed/
│       ├── account_anomaly_analysis.csv
│       ├── account_risk_intelligence.csv
│       ├── customer_intelligence.csv
│       ├── customer_segment_contribution.csv
│       ├── loan_portfolio_summary.csv
│       └── risk_intelligence.csv
│
├── documentation/
│   ├── data_dictionary.md
│   └── business_insights.md
│
├── powerbi/
│   └── Financial_Risk_Transaction_Intelligence.pbix
│
├── python/
│   └── 01_data_exploration.ipynb
│
└── sql/
    ├── 01_data_quality.sql
    ├── 02_staging.sql
    ├── 03_analytics_model.sql
    └── 04_business_analysis.sql
```

---

## What I Learned From This Project

The main takeaway from this project wasn't just learning another Power BI dashboard.

It was learning how the different parts of an analytics workflow fit together.

I had to think about:

- Whether the raw data could actually be trusted
- How to handle duplicates without losing information
- How to structure data for analysis
- How to choose useful customer segmentation features
- How to distinguish an anomaly from an actual fraud event
- How to avoid drawing conclusions from incomplete data
- How to turn analytical findings into something useful for a business user

---

## Future Improvements

If this were extended into a production analytics solution, I would add:

- Automated data-quality monitoring
- Real-time transaction monitoring
- Machine-learning-based anomaly detection
- Loan default prediction
- Customer churn prediction
- Time-series forecasting
- Automated risk alerts
- Branch-level performance analysis
- Production ETL pipelines

---

## Final Note

This project was built as a portfolio case study to demonstrate **end-to-end analytics thinking**, from raw data and SQL through Python analysis and Power BI reporting.

The focus is not simply on producing charts, but on understanding the data, identifying limitations, finding meaningful patterns, and translating those findings into business decisions.
