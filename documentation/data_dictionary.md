Data Dictionary	

This document describes the main tables used in the Financial Risk & Transaction Intelligence Platform.

The project uses a layered data architecture:

Raw → Staging → Analytics → Python Outputs → Power BI


1. dim_customer

Customer-level dimension containing standardized customer information.

CustomerID — Unique identifier for the customer
FirstName — Customer first name
LastName — Customer last name
FullName — Combined customer name
DOB — Standardized date of birth
CustomerTypeID — Identifier for customer type
CustomerType — Customer classification such as Individual, Small Business, or Large Enterprise
AddressID — Identifier linking the customer to an address
Street — Customer street address
City — Customer city
Country — Customer country

Grain: One row per customer.
Primary Key: CustomerID


2. dim_account

Account-level dimension containing account characteristics and current balance information.

AccountID — Unique identifier for the account
CustomerID — Customer who owns the account
AccountTypeID — Identifier for account type
AccountType — Account classification such as Savings, Checking, Business, Payroll, or Youth
AccountStatusID — Identifier for account status
AccountStatus — Current account status
Balance — Current account balance
OpeningDate — Date the account was opened

Grain: One row per account.
Primary Key: AccountID

Relationship: Customer → Account is one-to-many.


3. dim_branch

Branch-level dimension containing branch and location information.

BranchID — Unique identifier for the branch
BranchName — Name of the branch
AddressID — Identifier for branch address
Street — Branch street address
City — Branch city
Country — Branch country

Grain: One row per branch.
Primary Key: BranchID


4. dim_date

Calendar dimension used for time-based analysis and Power BI reporting.

DateKey — Integer key representing the date
FullDate — Calendar date
Year — Calendar year
Quarter — Calendar quarter
Month — Numeric month
MonthName — Month name
Week — Week number
Day — Day of month
DayName — Day of week

Grain: One row per calendar date.
Primary Key: DateKey


5. dim_transaction_type

Lookup dimension describing transaction categories.

TransactionTypeID — Unique transaction type identifier
TypeName — Transaction type

Transaction types:
•	Deposit
•	Withdrawal
•	Transfer
•	Payment

Grain: One row per transaction type.
Primary Key: TransactionTypeID


6. dim_loan_status

Lookup dimension describing loan status.

LoanStatusID — Unique loan status identifier
LoanStatus — Loan status

Loan statuses:
•	Active
•	Paid Off
•	Overdue

Grain: One row per loan status.
Primary Key: LoanStatusID


Fact Tables


7. fact_transactions

Central transaction fact table containing cleaned and deduplicated transaction activity.

TransactionID — Unique transaction identifier
AccountOriginID — Account associated with the originating transaction
AccountDestinationID — Destination account where applicable
TransactionTypeID — Type of transaction
Amount — Transaction amount
TransactionDate — Standardized transaction date and time
DateKey — Date dimension key
BranchID — Branch associated with the transaction
Description — Transaction description

Grain: One row per unique transaction.
Primary Key: TransactionID

Important Data Quality Note:

The raw transaction dataset contained:
•	50,000 records
•	500 exact duplicate records
•	49,500 unique transaction IDs
•	1,000 transactions with missing transaction dates

Duplicate transaction IDs were removed during staging.

Transactions with missing dates were retained but their date-related analytical fields were left unavailable rather than assigning an artificial date.


8. fact_loans

Central loan fact table containing cleaned and deduplicated loan records.

LoanID — Unique loan identifier
AccountID — Account associated with the loan
LoanStatusID — Current loan status
PrincipalAmount — Original/principal loan amount
InterestRate — Loan interest rate
StartDate — Loan start date
EstimatedEndDate — Estimated loan end date
StartDateKey — Date dimension key for start date
EstimatedEndDateKey — Date dimension key for estimated end date

Grain: One row per unique loan.
Primary Key: LoanID

Important Data Quality Note:

The raw loan dataset contained 333 records.

Three loan IDs were exact duplicates, resulting in 330 unique loans in the analytics layer.


Python Output Tables


9. customer_intelligence

Customer-level analytical dataset combining customer information with account and transaction behavior.

CustomerID — Customer identifier
CustomerType — Customer classification
AccountCount — Number of accounts
TotalBalance — Total balance across customer accounts
AverageBalance — Average account balance
TransactionCount — Number of originating transactions
TotalTransactionValue — Total originating transaction value
AverageTransactionValue — Average originating transaction value
CustomerSegment — Behavioral customer segment

Grain: One row per customer.

Customer segments:
•	Core Active
•	High-Value Active
•	No Financial Relationship


10. account_anomaly_analysis

Account-level transaction behavior analysis.

AccountOriginID — Account identifier
TransactionCount — Number of originating transactions
TotalTransactionValue — Total transaction value
AverageTransactionValue — Average transaction amount
FrequencyFlag — Indicates unusually high transaction frequency
ValueFlag — Indicates unusually high total transaction value
AverageSizeFlag — Indicates unusually high average transaction size
AnomalyScore — Combined behavioral anomaly score
AnomalyCategory — Risk signal category

Anomaly Score:

0 — Normal
1 — Low Anomaly Signal
2 — Moderate Anomaly Signal
3 — High Anomaly Signal

The score is based on behavioral thresholds using approximately two standard deviations above the overall account baseline.

Important: The anomaly score is not a fraud classification.


11. account_risk_intelligence

Account-level risk prioritization dataset combining transaction behavior with loan exposure.

AccountID — Account identifier
CustomerID — Customer identifier
CustomerType — Customer classification
TotalLoanExposure — Total loan principal associated with the account
OverdueLoanExposure — Loan principal currently classified as overdue
AverageInterestRate — Average interest rate across associated loans
TransactionCount — Originating transaction count
TotalTransactionValue — Total originating transaction value
AverageTransactionValue — Average originating transaction amount
AnomalyScore — Account behavioral anomaly score
AnomalyCategory — Account risk signal

Grain: One row per account.

This dataset is used in the Power BI Risk Intelligence page to prioritize accounts based on observed behavior and credit exposure.


12. risk_intelligence

Analytical dataset combining loan-level information with account transaction behavior.

This dataset was used during exploratory analysis and risk analysis.

Because an account can potentially have multiple loan records, this table is not used as the final account-level risk table for prioritization.

The final account-level analysis uses account_risk_intelligence.

This avoids double-counting account-level anomaly scores when multiple loans are associated with the same account.


13. loan_portfolio_summary

Summary dataset used to analyze the overall loan portfolio.

Key analytical fields include:
•	Total loan exposure
•	Overdue loan exposure
•	Loan status
•	Customer type
•	Loan counts

It supports the credit-risk analysis shown in the Power BI dashboard.


14. customer_segment_contribution

Summary dataset showing the contribution of each customer segment.

Key metrics include:
•	Customer count
•	Customer percentage
•	Balance contribution
•	Transaction value contribution

This dataset supports the customer segmentation analysis presented in the Executive Overview dashboard.


Key Relationships

dim_customer
      |
      | CustomerID
      ↓
dim_account
      |
      ├──────────────→ fact_transactions
      |
      └──────────────→ fact_loans

dim_transaction_type → fact_transactions
dim_branch → fact_transactions
dim_date → fact_transactions
dim_loan_status → fact_loans

Relationship logic:
•	One customer can have multiple accounts.
•	One account can have multiple transactions.
•	One account can have multiple loans.
•	One transaction belongs to one transaction type.
•	One transaction is associated with one branch.
•	Transaction dates connect to the date dimension.
•	Each loan belongs to one loan status.


Data Quality Philosophy

A major part of this project was avoiding assumptions when dealing with imperfect data.

Examples include:

•	Duplicate records were investigated before removal.
•	Missing transaction dates were retained instead of assigning artificial dates.
•	Negative account balances were treated as a business condition rather than automatically classified as errors.
•	The post-2024 transaction gap was identified as a data-coverage limitation rather than interpreted as a business decline.
•	Transaction anomaly signals were not labelled as fraud because the dataset contains no confirmed fraud field.

This approach was important because good analytics is not only about calculating metrics — it is also about understanding whether those metrics can be trusted.
