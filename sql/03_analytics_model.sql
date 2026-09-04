-- ============================================================
-- PROJECT 1: FINANCIAL RISK & TRANSACTION INTELLIGENCE
-- 03 - ANALYTICS MODEL
-- ============================================================

CREATE DATABASE IF NOT EXISTS financial_analytics;


-- ============================================================
-- 1. CUSTOMER DIMENSION
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.dim_customer;

CREATE TABLE financial_analytics.dim_customer AS

SELECT DISTINCT
    c.CustomerID,
    c.FirstName,
    c.LastName,

    CONCAT(
        c.FirstName,
        ' ',
        c.LastName
    ) AS FullName,

    c.DateOfBirth,
    c.CustomerTypeID,
    ct.TypeName AS CustomerType,
    c.AddressID,
    a.Street,
    a.City,
    a.Country

FROM financial_staging.stg_customers c

LEFT JOIN financial_raw.customer_types ct
    ON c.CustomerTypeID = ct.CustomerTypeID

LEFT JOIN financial_staging.stg_addresses a
    ON c.AddressID = a.AddressID

WHERE c.CustomerID IS NOT NULL;


-- ============================================================
-- 2. ACCOUNT DIMENSION
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.dim_account;

CREATE TABLE financial_analytics.dim_account AS

SELECT DISTINCT
    a.AccountID,
    a.CustomerID,
    a.AccountTypeID,
    at.TypeName AS AccountType,
    a.AccountStatusID,
    ast.StatusName AS AccountStatus,
    a.Balance,
    a.OpeningDate

FROM financial_staging.stg_accounts a

LEFT JOIN financial_raw.account_types at
    ON a.AccountTypeID = at.AccountTypeID

LEFT JOIN financial_raw.account_statuses ast
    ON a.AccountStatusID = ast.AccountStatusID

WHERE a.AccountID IS NOT NULL;


-- ============================================================
-- 3. BRANCH DIMENSION
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.dim_branch;

CREATE TABLE financial_analytics.dim_branch AS

SELECT
    b.BranchID,
    b.BranchName,
    b.AddressID,
    a.Street,
    a.City,
    a.Country

FROM financial_staging.stg_branches b

LEFT JOIN financial_staging.stg_addresses a
    ON b.AddressID = a.AddressID;


-- ============================================================
-- 4. TRANSACTION TYPE DIMENSION
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.dim_transaction_type;

CREATE TABLE financial_analytics.dim_transaction_type AS

SELECT
    TransactionTypeID,
    TypeName AS TransactionType

FROM financial_raw.transaction_types;


-- ============================================================
-- 5. LOAN STATUS DIMENSION
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.dim_loan_status;

CREATE TABLE financial_analytics.dim_loan_status AS

SELECT
    LoanStatusID,
    StatusName AS LoanStatus

FROM financial_raw.loan_statuses;


-- ============================================================
-- 6. DATE DIMENSION
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.dim_date;

CREATE TABLE financial_analytics.dim_date (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName VARCHAR(20),
    Week INT,
    Day INT,
    DayName VARCHAR(20)
);


-- Populate date dimension using a digit cross-join
-- to avoid recursive CTE recursion limits.

INSERT INTO financial_analytics.dim_date
(
    DateKey,
    FullDate,
    Year,
    Quarter,
    Month,
    MonthName,
    Week,
    Day,
    DayName
)

SELECT
    DATE_FORMAT(d.FullDate, '%Y%m%d') + 0 AS DateKey,
    d.FullDate,
    YEAR(d.FullDate),
    QUARTER(d.FullDate),
    MONTH(d.FullDate),
    MONTHNAME(d.FullDate),
    WEEK(d.FullDate),
    DAY(d.FullDate),
    DAYNAME(d.FullDate)

FROM
(
    SELECT
        DATE_ADD(
            '2020-01-01',
            INTERVAL
            (
                n0.n
                + n1.n * 10
                + n2.n * 100
                + n3.n * 1000
            ) DAY
        ) AS FullDate

    FROM
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2
         UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
         UNION ALL SELECT 9) n0

    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2
         UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
         UNION ALL SELECT 9) n1

    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2
         UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
         UNION ALL SELECT 9) n2

    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2
         UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
         UNION ALL SELECT 9) n3

) d

WHERE d.FullDate <= '2026-08-28';


-- ============================================================
-- 7. TRANSACTION FACT
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.fact_transactions;

CREATE TABLE financial_analytics.fact_transactions AS

SELECT
    t.TransactionID,
    t.AccountOriginID,
    t.AccountDestinationID,
    t.TransactionTypeID,
    t.Amount,
    t.TransactionDate,

    CASE
        WHEN t.TransactionDate IS NOT NULL
        THEN YEAR(t.TransactionDate) * 10000
             + MONTH(t.TransactionDate) * 100
             + DAY(t.TransactionDate)
        ELSE NULL
    END AS DateKey,

    t.BranchID,
    t.Description

FROM financial_staging.stg_transactions t;


-- ============================================================
-- 8. LOAN FACT
-- ============================================================

DROP TABLE IF EXISTS financial_analytics.fact_loans;

CREATE TABLE financial_analytics.fact_loans AS

WITH ranked_loans AS (

    SELECT
        l.*,

        ROW_NUMBER() OVER (
            PARTITION BY LoanID
            ORDER BY LoanID
        ) AS rn

    FROM financial_staging.stg_loans l
)

SELECT
    LoanID,
    AccountID,
    LoanStatusID,
    PrincipalAmount,
    InterestRate,
    StartDate,
    EstimatedEndDate,

    CASE
        WHEN StartDate IS NOT NULL
        THEN YEAR(StartDate) * 10000
             + MONTH(StartDate) * 100
             + DAY(StartDate)
        ELSE NULL
    END AS StartDateKey,

    CASE
        WHEN EstimatedEndDate IS NOT NULL
        THEN YEAR(EstimatedEndDate) * 10000
             + MONTH(EstimatedEndDate) * 100
             + DAY(EstimatedEndDate)
        ELSE NULL
    END AS EstimatedEndDateKey

FROM ranked_loans

WHERE rn = 1;


-- ============================================================
-- 9. PRIMARY KEYS
-- ============================================================

ALTER TABLE financial_analytics.dim_customer
ADD PRIMARY KEY (CustomerID);

ALTER TABLE financial_analytics.dim_account
ADD PRIMARY KEY (AccountID);

ALTER TABLE financial_analytics.dim_branch
ADD PRIMARY KEY (BranchID);

ALTER TABLE financial_analytics.dim_transaction_type
ADD PRIMARY KEY (TransactionTypeID);

ALTER TABLE financial_analytics.dim_loan_status
ADD PRIMARY KEY (LoanStatusID);

ALTER TABLE financial_analytics.fact_transactions
ADD PRIMARY KEY (TransactionID);

ALTER TABLE financial_analytics.fact_loans
ADD PRIMARY KEY (LoanID);


-- ============================================================
-- 10. ANALYTICS MODEL VALIDATION
-- ============================================================


-- Customer count
SELECT COUNT(*) AS customer_count
FROM financial_analytics.dim_customer;


-- Account count
SELECT COUNT(*) AS account_count
FROM financial_analytics.dim_account;


-- Transaction fact count
SELECT COUNT(*) AS transaction_fact_count
FROM financial_analytics.fact_transactions;


-- Loan fact count
SELECT COUNT(*) AS loan_fact_count
FROM financial_analytics.fact_loans;


-- Transaction duplicate validation
SELECT
    TransactionID,
    COUNT(*) AS duplicate_count
FROM financial_analytics.fact_transactions
GROUP BY TransactionID
HAVING COUNT(*) > 1;


-- Loan duplicate validation
SELECT
    LoanID,
    COUNT(*) AS duplicate_count
FROM financial_analytics.fact_loans
GROUP BY LoanID
HAVING COUNT(*) > 1;


-- Transaction → Account integrity
SELECT COUNT(*) AS invalid_origin_accounts
FROM financial_analytics.fact_transactions f
LEFT JOIN financial_analytics.dim_account a
    ON f.AccountOriginID = a.AccountID
WHERE a.AccountID IS NULL;


-- Transaction → Transaction Type integrity
SELECT COUNT(*) AS invalid_transaction_types
FROM financial_analytics.fact_transactions f
LEFT JOIN financial_analytics.dim_transaction_type d
    ON f.TransactionTypeID = d.TransactionTypeID
WHERE d.TransactionTypeID IS NULL;


-- Loan → Account integrity
SELECT COUNT(*) AS invalid_loan_accounts
FROM financial_analytics.fact_loans f
LEFT JOIN financial_analytics.dim_account a
    ON f.AccountID = a.AccountID
WHERE a.AccountID IS NULL;


-- Loan → Loan Status integrity
SELECT COUNT(*) AS invalid_loan_statuses
FROM financial_analytics.fact_loans f
LEFT JOIN financial_analytics.dim_loan_status d
    ON f.LoanStatusID = d.LoanStatusID
WHERE d.LoanStatusID IS NULL;