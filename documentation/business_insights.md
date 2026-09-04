Business Insights

Financial Risk & Transaction Intelligence Platform

This document summarizes the main business findings from the SQL, Python, and Power BI analysis.


1. Executive Summary

The analysis combines customer, account, transaction, and loan data to create a unified view of financial activity and account-level risk signals.

The cleaned analytical dataset contains:

•	49,500 unique transactions
•	₹123.96M total transaction value
•	₹2,504.15 average transaction value
•	₹17.09M total loan exposure
•	₹1.67M overdue loan exposure
•	9.78% overdue exposure
•	1,100 unique customers
•	1,651 unique accounts
•	330 unique loans

The main findings are:

1. Transaction activity is relatively balanced across deposits, transfers, and withdrawals.
2. A relatively small high-value customer segment controls a large share of measured balance and transaction value.
3. Around 9.78% of loan exposure is classified as overdue.
4. Some accounts show unusually high transaction behavior compared with the overall account baseline.
5. Transaction anomaly signals appear across different customer types and account types rather than being concentrated in one segment.
6. The transaction timeline contains a major coverage gap after January 2024, so the later decline must not be interpreted as a genuine business decline.


2. Transaction Activity

Total transaction activity:

•	Transactions: 49,500
•	Total transaction value: ₹123.96M
•	Average transaction value: ₹2,504.15

Transaction mix:

Deposit:
•	15,065 transactions
•	₹37.65M transaction value
•	Approximately 30% of total transaction value

Transfer:
•	14,771 transactions
•	₹37.18M transaction value
•	Approximately 30% of total transaction value

Withdrawal:
•	14,706 transactions
•	₹36.74M transaction value
•	Approximately 29.6% of total transaction value

Payment:
•	4,958 transactions
•	₹12.38M transaction value
•	Approximately 10% of total transaction value

Business interpretation:

Deposits, transfers, and withdrawals contribute relatively similar levels of transaction value. This means the portfolio does not appear to depend heavily on one transaction type.

Payments represent a smaller share of overall transaction value.


3. Customer Segmentation

Customers were segmented using K-Means clustering in Python.

The segmentation features were:

•	Account count
•	Total balance
•	Average balance
•	Transaction count
•	Total transaction value
•	Average transaction value

A 3-cluster solution was selected after comparing different cluster sizes using the elbow method and silhouette scores.

The three segments are:

Core Active

•	651 customers
•	Approximately 59.2% of customers
•	Approximately 54.7% of measured account balance
•	Approximately 55.3% of transaction value

Business interpretation:

This is the largest active customer group and represents the core financial relationship base.

High-Value Active

•	211 customers
•	Approximately 19.2% of customers
•	Approximately 45.3% of measured account balance
•	Approximately 44.7% of transaction value

Business interpretation:

This is a relatively small customer segment but represents a very large share of the financial value in the dataset.

This group may deserve greater attention from a relationship-management and retention perspective because changes in a relatively small customer population could have a meaningful effect on overall financial activity.

No Financial Relationship

•	238 customers
•	Approximately 21.6% of customers
•	0 measured balance
•	0 originating transaction value

Business interpretation:

These customers exist in the customer data but do not have measured account balance or originating transaction activity in the analytical dataset.

They could represent an opportunity for customer activation, although additional data would be needed to understand why they are inactive.


4. Customer Type Mix

The customer segments contain Individuals, Small Businesses, and Large Enterprises.

The High-Value Active segment has a slightly higher representation of Large Enterprise customers than the Core Active segment.

However, the differences are not large enough to conclude that customer type is the main driver of the segmentation.

The clustering is primarily driven by observed financial behavior such as balance and transaction activity.


5. Credit Risk

The cleaned loan portfolio contains:

•	330 unique loans
•	₹17.09M total loan exposure
•	₹1.67M overdue loan exposure
•	9.78% overdue exposure

Business interpretation:

The overdue portion represents a meaningful area for credit-risk monitoring.

However, the dataset does not contain enough information to determine why individual loans became overdue or to predict future defaults.

Therefore, the analysis should be viewed as portfolio monitoring rather than a default prediction model.


6. Overdue Exposure By Customer Type

Overdue exposure was compared across:

•	Large Enterprise
•	Small Business
•	Individual customers

Large Enterprise customers have the highest overdue exposure in the dataset.

However, the difference between the three customer types is relatively modest.

Business interpretation:

Customer type alone does not appear sufficient to identify high credit risk.

A stronger risk framework would combine customer type with:

•	Loan size
•	Interest rate
•	Repayment history
•	Account balance
•	Transaction behavior
•	Historical delinquency
•	Customer tenure


7. Transaction Anomaly Analysis

Transaction behavior was analyzed at the account level.

Three behavioral measures were used:

•	Transaction frequency
•	Total transaction value
•	Average transaction size

For each measure, accounts above approximately two standard deviations from the overall account baseline received a behavioral flag.

The three flags were combined into an anomaly score.

Score interpretation:

0 — Normal
1 — Low Anomaly Signal
2 — Moderate Anomaly Signal
3 — High Anomaly Signal

The account with the strongest combined signal was:

Account 200304

Observed behavior:

•	45 transactions
•	₹139,721.66 total transaction value
•	₹3,104.93 average transaction value
•	Anomaly Score: 3
•	High Anomaly Signal

Business interpretation:

This account shows unusually high behavior across the measured transaction dimensions compared with the overall account baseline.

It should therefore be considered a candidate for additional review or monitoring.


8. Risk Signals Are Not Concentrated In One Customer Type

The accounts showing moderate or high anomaly signals are not limited to a single customer segment.

Signals appear across:

•	Individuals
•	Small Businesses
•	Large Enterprises

They also occur across different account types and statuses.

Business interpretation:

A monitoring framework based only on customer type would likely miss some unusual accounts.

Behavioral monitoring should therefore complement static customer segmentation.


9. Risk Prioritization

The final account-level risk analysis combines:

•	Transaction behavior
•	Loan exposure
•	Overdue exposure
•	Transaction frequency
•	Total transaction value
•	Average transaction size
•	Anomaly score

This provides a more useful prioritization framework than looking at any single metric.

For example, an account showing unusually high transaction behavior together with meaningful credit exposure may deserve more attention than an account that is unusual on only one dimension.


10. Important Risk Disclaimer

The anomaly score is NOT a fraud score.

The dataset does not contain a confirmed fraud label.

A high anomaly score means that the observed account behavior is unusually high relative to the overall baseline.

It does not prove:

•	Fraud
•	Money laundering
•	Financial misconduct
•	Unauthorized activity

The appropriate business interpretation is:

"Requires further investigation or monitoring."


11. Data Quality Findings

Several quality issues were identified before analysis.

Transactions:

•	500 exact duplicate records
•	1,000 missing transaction dates

Customers:

•	11 duplicate customer IDs
•	22 missing dates of birth
•	3 invalid dates of birth

Accounts:

•	16 duplicate account IDs
•	10 negative balances
•	33 missing opening dates

Loans:

•	3 duplicate loan IDs

Addresses:

•	12 duplicate address IDs
•	23 missing countries
•	26 missing cities
•	24 missing streets

Business interpretation:

Data-quality checks are important because analytical conclusions are only as reliable as the underlying data.

The project therefore separates data-quality handling from business analysis.


12. Transaction Data Coverage Limitation

The transaction data is concentrated between:

January 2020 and January 2024.

After that period, there is a major gap followed by sparse records.

This creates an important analytical limitation.

The sharp decline visible after 2024 should NOT be interpreted as a genuine decline in business activity.

It is more appropriate to classify it as a data-coverage issue.

Business implication:

Before using transaction trends for forecasting, performance evaluation, or strategic decisions, the missing period would need to be investigated and resolved.


13. Negative Account Balances

Ten accounts have negative balances.

The total negative balance across these accounts is approximately:

₹3,247.46

Negative balances were not automatically treated as data errors.

They may represent legitimate financial conditions such as overdrafts or account adjustments.

However, they should be reviewed against the institution's actual business rules in a production environment.


14. Key Business Recommendations

Based on the analysis, the following actions would be reasonable for a real financial institution:

1. Monitor high-value customers

The High-Value Active segment represents around 19% of customers but almost 45% of measured balance and transaction value.

These customers could be prioritized for relationship management and retention programs.

2. Strengthen behavioral monitoring

Use account-level transaction behavior alongside customer profiles.

This can help identify unusual activity that may not be visible from customer type alone.

3. Prioritize credit-risk monitoring

Overdue exposure represents approximately 9.78% of total loan exposure.

Accounts with overdue loans and unusual transaction behavior could receive higher monitoring priority.

4. Improve data-quality controls

Automated checks should be implemented for:

•	Duplicate IDs
•	Missing dates
•	Invalid dates
•	Missing customer attributes
•	Referential integrity
•	Unexpected transaction patterns

5. Investigate the transaction coverage gap

The missing period after January 2024 should be investigated before using the dataset for trend forecasting or long-term performance analysis.

6. Build a more advanced risk model

A production solution could combine:

•	Historical transaction behavior
•	Repayment history
•	Customer tenure
•	Account balances
•	Loan characteristics
•	Historical anomalies

with machine-learning methods to improve risk prioritization.


15. Limitations

This analysis has several limitations.

•	The dataset is synthetic.
•	There is no confirmed fraud label.
•	The anomaly score is a statistical behavioral signal rather than a fraud prediction.
•	Transaction activity is incomplete after January 2024.
•	The loan dataset does not contain detailed repayment history.
•	There is not enough information to build a reliable default prediction model.
•	Customer segmentation reflects the behavior available in this dataset and may change with additional variables.

These limitations are important when interpreting the results.


16. Overall Business Takeaway

The strongest finding from the project is that financial intelligence becomes more useful when customer profile, transaction behavior, and credit exposure are viewed together.

A dashboard showing only transaction volume or loan exposure would provide a limited view.

Combining these dimensions allows an analyst to identify:

•	Where financial value is concentrated
•	Which customers are most active
•	Where overdue exposure exists
•	Which accounts show unusual behavior
•	Which areas require further investigation
•	Where data limitations may affect decision-making

The project demonstrates an end-to-end approach to turning raw financial data into actionable business intelligence.
