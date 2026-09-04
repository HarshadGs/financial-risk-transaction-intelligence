USE financial_raw;

-- ============================================================
-- PROJECT 1: FINANCIAL RISK & TRANSACTION INTELLIGENCE
-- 01 - DATA QUALITY AUDIT
-- ============================================================


-- ============================================================
-- 1. ROW COUNTS
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL
SELECT 'accounts', COUNT(*)
FROM accounts

UNION ALL
SELECT 'transactions', COUNT(*)
FROM transactions

UNION ALL
SELECT 'loans', COUNT(*)
FROM loans

UNION ALL
SELECT 'addresses', COUNT(*)
FROM addresses

UNION ALL
SELECT 'branches', COUNT(*)
FROM branches;


-- ============================================================
-- 2. TRANSACTION DUPLICATES
-- ============================================================

SELECT
    TransactionID,
    COUNT(*) AS duplicate_count
FROM transactions
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Check exact duplicate transaction rows
SELECT
    TransactionID,
    AccountOriginID,
    AccountDestinationID,
    TransactionTypeID,
    Amount,
    TransactionDate,
    BranchID,
    Description,
    COUNT(*) AS duplicate_count
FROM transactions
GROUP BY
    TransactionID,
    AccountOriginID,
    AccountDestinationID,
    TransactionTypeID,
    Amount,
    TransactionDate,
    BranchID,
    Description
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. TRANSACTION MISSING VALUES
-- ============================================================

SELECT
    SUM(TransactionID IS NULL) AS missing_transaction_id,
    SUM(AccountOriginID IS NULL) AS missing_origin_account,
    SUM(AccountDestinationID IS NULL) AS missing_destination_account,
    SUM(TransactionTypeID IS NULL) AS missing_transaction_type,
    SUM(Amount IS NULL) AS missing_amount,
    SUM(TransactionDate IS NULL OR TRIM(TransactionDate) = '') AS missing_transaction_date,
    SUM(BranchID IS NULL) AS missing_branch
FROM transactions;


-- ============================================================
-- 4. TRANSACTION AMOUNT VALIDATION
-- ============================================================

SELECT
    MIN(Amount) AS minimum_amount,
    MAX(Amount) AS maximum_amount,
    AVG(Amount) AS average_amount,
    SUM(Amount <= 0) AS non_positive_amounts
FROM transactions;


-- ============================================================
-- 5. TRANSACTION DATE VALIDATION
-- ============================================================

SELECT
    MIN(
        STR_TO_DATE(
            LEFT(TransactionDate, 19),
            '%Y-%m-%d %H:%i:%s'
        )
    ) AS minimum_transaction_date,

    MAX(
        STR_TO_DATE(
            LEFT(TransactionDate, 19),
            '%Y-%m-%d %H:%i:%s'
        )
    ) AS maximum_transaction_date
FROM transactions
WHERE TransactionDate IS NOT NULL
  AND TRIM(TransactionDate) <> '';


-- Check future transaction dates
SELECT COUNT(*) AS future_transaction_dates
FROM transactions
WHERE STR_TO_DATE(
          LEFT(TransactionDate, 19),
          '%Y-%m-%d %H:%i:%s'
      ) > CURRENT_DATE;


-- ============================================================
-- 6. CUSTOMER DATA QUALITY
-- ============================================================

SELECT
    COUNT(*) AS total_customers,
    SUM(CustomerID IS NULL) AS missing_customer_id,
    SUM(DateOfBirth IS NULL OR TRIM(DateOfBirth) = '') AS missing_dob
FROM customers;


-- Duplicate customers
SELECT
    CustomerID,
    COUNT(*) AS duplicate_count
FROM customers
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 7. ACCOUNT DATA QUALITY
-- ============================================================

SELECT
    COUNT(*) AS total_accounts,
    SUM(AccountID IS NULL) AS missing_account_id,
    SUM(CustomerID IS NULL) AS missing_customer_id,
    SUM(Balance IS NULL) AS missing_balance,
    SUM(Balance < 0) AS negative_balance_accounts,
    SUM(OpeningDate IS NULL OR TRIM(OpeningDate) = '') AS missing_opening_date
FROM accounts;


-- Duplicate accounts
SELECT
    AccountID,
    COUNT(*) AS duplicate_count
FROM accounts
GROUP BY AccountID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Negative account balances
SELECT
    AccountID,
    CustomerID,
    Balance
FROM accounts
WHERE Balance < 0
ORDER BY Balance;


-- ============================================================
-- 8. ADDRESS DATA QUALITY
-- ============================================================

SELECT
    COUNT(*) AS total_addresses,
    SUM(Street IS NULL OR TRIM(Street) = '') AS missing_street,
    SUM(City IS NULL OR TRIM(City) = '') AS missing_city,
    SUM(Country IS NULL OR TRIM(Country) = '') AS missing_country
FROM addresses;


-- Duplicate addresses
SELECT
    AddressID,
    COUNT(*) AS duplicate_count
FROM addresses
GROUP BY AddressID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 9. LOAN DATA QUALITY
-- ============================================================

SELECT
    COUNT(*) AS total_loans,
    SUM(LoanID IS NULL) AS missing_loan_id,
    SUM(AccountID IS NULL) AS missing_account_id,
    SUM(PrincipalAmount IS NULL) AS missing_principal,
    SUM(PrincipalAmount <= 0) AS invalid_principal,
    SUM(InterestRate IS NULL) AS missing_interest_rate,
    SUM(InterestRate < 0) AS negative_interest_rate
FROM loans;


-- Duplicate loans
SELECT
    LoanID,
    COUNT(*) AS duplicate_count
FROM loans
GROUP BY LoanID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Missing loan dates
SELECT
    SUM(StartDate IS NULL OR TRIM(StartDate) = '') AS missing_start_date,
    SUM(EstimatedEndDate IS NULL OR TRIM(EstimatedEndDate) = '') AS missing_estimated_end_date
FROM loans;


-- ============================================================
-- 10. TRANSACTION REFERENTIAL INTEGRITY
-- ============================================================

-- Origin accounts missing from account master
SELECT COUNT(*) AS invalid_origin_accounts
FROM transactions t
LEFT JOIN accounts a
    ON t.AccountOriginID = a.AccountID
WHERE a.AccountID IS NULL;


-- Destination accounts missing from account master
SELECT COUNT(*) AS invalid_destination_accounts
FROM transactions t
LEFT JOIN accounts a
    ON t.AccountDestinationID = a.AccountID
WHERE a.AccountID IS NULL;


-- Invalid transaction types
SELECT COUNT(*) AS invalid_transaction_types
FROM transactions t
LEFT JOIN transaction_types tt
    ON t.TransactionTypeID = tt.TransactionTypeID
WHERE tt.TransactionTypeID IS NULL;


-- Invalid branches
SELECT COUNT(*) AS invalid_branches
FROM transactions t
LEFT JOIN branches b
    ON t.BranchID = b.BranchID
WHERE b.BranchID IS NULL;


-- ============================================================
-- 11. ACCOUNT REFERENTIAL INTEGRITY
-- ============================================================

-- Invalid customers
SELECT COUNT(*) AS invalid_customers
FROM accounts a
LEFT JOIN customers c
    ON a.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;


-- Invalid account types
SELECT COUNT(*) AS invalid_account_types
FROM accounts a
LEFT JOIN account_types at
    ON a.AccountTypeID = at.AccountTypeID
WHERE at.AccountTypeID IS NULL;


-- Invalid account statuses
SELECT COUNT(*) AS invalid_account_statuses
FROM accounts a
LEFT JOIN account_statuses s
    ON a.AccountStatusID = s.AccountStatusID
WHERE s.AccountStatusID IS NULL;


-- ============================================================
-- 12. LOAN REFERENTIAL INTEGRITY
-- ============================================================

-- Invalid loan accounts
SELECT COUNT(*) AS invalid_loan_accounts
FROM loans l
LEFT JOIN accounts a
    ON l.AccountID = a.AccountID
WHERE a.AccountID IS NULL;


-- Invalid loan statuses
SELECT COUNT(*) AS invalid_loan_statuses
FROM loans l
LEFT JOIN loan_statuses ls
    ON l.LoanStatusID = ls.LoanStatusID
WHERE ls.LoanStatusID IS NULL;