-- ============================================================
-- PROJECT 1: FINANCIAL RISK & TRANSACTION INTELLIGENCE
-- 02 - STAGING & DATA CLEANING
-- ============================================================


-- ============================================================
-- 1. CREATE STAGING DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS financial_staging;


-- ============================================================
-- 2. TRANSACTION STAGING
-- ============================================================

DROP TABLE IF EXISTS financial_staging.stg_transactions;

CREATE TABLE financial_staging.stg_transactions AS

WITH ranked_transactions AS (
    SELECT
        t.*,

        ROW_NUMBER() OVER (
            PARTITION BY TransactionID
            ORDER BY TransactionID
        ) AS rn

    FROM financial_raw.transactions t
)

SELECT
    TransactionID,
    AccountOriginID,
    AccountDestinationID,
    TransactionTypeID,
    Amount,

    CASE
        WHEN TransactionDate IS NULL
             OR TRIM(TransactionDate) = ''
        THEN NULL

        ELSE STR_TO_DATE(
            LEFT(TransactionDate, 19),
            '%Y-%m-%d %H:%i:%s'
        )
    END AS TransactionDate,

    BranchID,
    Description,

    CASE
        WHEN TransactionDate IS NULL
             OR TRIM(TransactionDate) = ''
        THEN 'Missing Transaction Date'
        ELSE 'Valid'
    END AS DataQualityStatus

FROM ranked_transactions
WHERE rn = 1;


-- ============================================================
-- 3. CUSTOMER STAGING
-- ============================================================

DROP TABLE IF EXISTS financial_staging.stg_customers;

CREATE TABLE financial_staging.stg_customers AS

SELECT
    CustomerID,
    FirstName,
    LastName,

    CASE

        WHEN DateOfBirth IS NULL
             OR TRIM(DateOfBirth) = ''
        THEN NULL

        WHEN DateOfBirth REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(
            DateOfBirth,
            '%Y-%m-%d'
        )

        WHEN DateOfBirth REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
        THEN STR_TO_DATE(
            DateOfBirth,
            '%d/%m/%Y'
        )

        WHEN DateOfBirth REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
        THEN STR_TO_DATE(
            DateOfBirth,
            '%d-%m-%Y'
        )

        ELSE NULL

    END AS DateOfBirth,

    AddressID,
    CustomerTypeID

FROM financial_raw.customers;


-- ============================================================
-- 4. ACCOUNT STAGING
-- ============================================================

DROP TABLE IF EXISTS financial_staging.stg_accounts;

CREATE TABLE financial_staging.stg_accounts AS

SELECT
    AccountID,
    CustomerID,
    AccountTypeID,
    AccountStatusID,
    Balance,

    CASE

        WHEN OpeningDate IS NULL
             OR TRIM(OpeningDate) = ''
        THEN NULL

        ELSE STR_TO_DATE(
            LEFT(OpeningDate, 10),
            '%Y-%m-%d'
        )

    END AS OpeningDate,

    CASE

        WHEN Balance < 0
        THEN 'Negative Balance'

        WHEN OpeningDate IS NULL
             OR TRIM(OpeningDate) = ''
        THEN 'Missing Opening Date'

        ELSE 'Valid'

    END AS DataQualityStatus

FROM financial_raw.accounts;


-- ============================================================
-- 5. LOAN STAGING
-- ============================================================

DROP TABLE IF EXISTS financial_staging.stg_loans;

CREATE TABLE financial_staging.stg_loans AS

SELECT
    LoanID,
    AccountID,
    LoanStatusID,
    PrincipalAmount,
    InterestRate,

    CASE

        WHEN StartDate IS NULL
             OR TRIM(StartDate) = ''
        THEN NULL

        ELSE STR_TO_DATE(
            LEFT(StartDate, 10),
            '%Y-%m-%d'
        )

    END AS StartDate,

    CASE

        WHEN EstimatedEndDate IS NULL
             OR TRIM(EstimatedEndDate) = ''
        THEN NULL

        ELSE STR_TO_DATE(
            LEFT(EstimatedEndDate, 10),
            '%Y-%m-%d'
        )

    END AS EstimatedEndDate

FROM financial_raw.loans;


-- ============================================================
-- 6. BRANCH STAGING
-- ============================================================

DROP TABLE IF EXISTS financial_staging.stg_branches;

CREATE TABLE financial_staging.stg_branches AS

SELECT
    BranchID,
    BranchName,
    AddressID

FROM financial_raw.branches;


-- ============================================================
-- 7. ADDRESS STAGING
-- ============================================================

DROP TABLE IF EXISTS financial_staging.stg_addresses;

CREATE TABLE financial_staging.stg_addresses AS

SELECT
    AddressID,
    Street,
    City,
    Country,

    CASE

        WHEN Street IS NULL
             OR TRIM(Street) = ''
        THEN 'Missing Street'

        WHEN City IS NULL
             OR TRIM(City) = ''
        THEN 'Missing City'

        WHEN Country IS NULL
             OR TRIM(Country) = ''
        THEN 'Missing Country'

        ELSE 'Valid'

    END AS DataQualityStatus

FROM financial_raw.addresses;


-- ============================================================
-- 8. STAGING VALIDATION
-- ============================================================


-- Transaction staging count
SELECT
    COUNT(*) AS staging_transaction_count
FROM financial_staging.stg_transactions;


-- Duplicate transaction IDs after deduplication
SELECT
    TransactionID,
    COUNT(*) AS duplicate_count
FROM financial_staging.stg_transactions
GROUP BY TransactionID
HAVING COUNT(*) > 1;


-- Transaction data-quality status
SELECT
    DataQualityStatus,
    COUNT(*) AS row_count
FROM financial_staging.stg_transactions
GROUP BY DataQualityStatus;


-- Customer staging count
SELECT
    COUNT(*) AS staging_customer_count
FROM financial_staging.stg_customers;


-- Account staging count
SELECT
    COUNT(*) AS staging_account_count
FROM financial_staging.stg_accounts;


-- Loan staging count
SELECT
    COUNT(*) AS staging_loan_count
FROM financial_staging.stg_loans;


-- Address staging count
SELECT
    COUNT(*) AS staging_address_count
FROM financial_staging.stg_addresses;