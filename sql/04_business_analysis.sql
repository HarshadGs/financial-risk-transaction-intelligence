-- ============================================================
-- PROJECT 1: FINANCIAL RISK & TRANSACTION INTELLIGENCE
-- 04 - BUSINESS ANALYSIS
-- ============================================================

USE financial_analytics;


-- ============================================================
-- 1. EXECUTIVE TRANSACTION KPIs
-- ============================================================

SELECT
    COUNT(*) AS total_transactions,
    SUM(Amount) AS total_transaction_value,
    AVG(Amount) AS average_transaction_value
FROM fact_transactions
WHERE TransactionDate IS NOT NULL;


-- ============================================================
-- 2. TRANSACTION MIX BY TYPE
-- ============================================================

SELECT
    tt.TransactionType,
    COUNT(*) AS transaction_count,
    SUM(f.Amount) AS total_transaction_value,
    AVG(f.Amount) AS average_transaction_value,

    ROUND(
        100 * SUM(f.Amount)
        / SUM(SUM(f.Amount)) OVER (),
        2
    ) AS value_share_pct

FROM fact_transactions f

JOIN dim_transaction_type tt
    ON f.TransactionTypeID = tt.TransactionTypeID

WHERE f.TransactionDate IS NOT NULL

GROUP BY tt.TransactionType

ORDER BY total_transaction_value DESC;


-- ============================================================
-- 3. MONTHLY TRANSACTION ACTIVITY
-- ============================================================

SELECT
    d.Year,
    d.Month,
    d.MonthName,
    COUNT(f.TransactionID) AS transaction_count,
    SUM(f.Amount) AS total_transaction_value,
    AVG(f.Amount) AS average_transaction_value

FROM fact_transactions f

JOIN dim_date d
    ON f.DateKey = d.DateKey

GROUP BY
    d.Year,
    d.Month,
    d.MonthName

ORDER BY
    d.Year,
    d.Month;


-- ============================================================
-- 4. LOAN PORTFOLIO BY STATUS
-- ============================================================

SELECT
    ls.LoanStatus,
    COUNT(*) AS loan_count,
    SUM(f.PrincipalAmount) AS loan_exposure,
    AVG(f.PrincipalAmount) AS average_loan_size

FROM fact_loans f

JOIN dim_loan_status ls
    ON f.LoanStatusID = ls.LoanStatusID

GROUP BY ls.LoanStatus

ORDER BY loan_exposure DESC;


-- ============================================================
-- 5. OVERDUE LOAN EXPOSURE
-- ============================================================

SELECT
    SUM(f.PrincipalAmount) AS total_loan_exposure,

    SUM(
        CASE
            WHEN ls.LoanStatus = 'Overdue'
            THEN f.PrincipalAmount
            ELSE 0
        END
    ) AS overdue_loan_exposure,

    ROUND(
        100 *
        SUM(
            CASE
                WHEN ls.LoanStatus = 'Overdue'
                THEN f.PrincipalAmount
                ELSE 0
            END
        )
        / NULLIF(SUM(f.PrincipalAmount), 0),
        2
    ) AS overdue_exposure_pct

FROM fact_loans f

JOIN dim_loan_status ls
    ON f.LoanStatusID = ls.LoanStatusID;


-- ============================================================
-- 6. OVERDUE EXPOSURE BY CUSTOMER TYPE
-- ============================================================

SELECT
    c.CustomerType,

    COUNT(DISTINCT f.LoanID) AS loan_count,

    SUM(f.PrincipalAmount) AS total_exposure,

    SUM(
        CASE
            WHEN ls.LoanStatus = 'Overdue'
            THEN f.PrincipalAmount
            ELSE 0
        END
    ) AS overdue_exposure

FROM fact_loans f

JOIN dim_loan_status ls
    ON f.LoanStatusID = ls.LoanStatusID

JOIN dim_account a
    ON f.AccountID = a.AccountID

JOIN dim_customer c
    ON a.CustomerID = c.CustomerID

GROUP BY c.CustomerType

ORDER BY overdue_exposure DESC;


-- ============================================================
-- 7. ACCOUNT TRANSACTION BEHAVIOR
-- ============================================================

SELECT
    f.AccountOriginID AS AccountID,

    COUNT(*) AS transaction_count,

    SUM(f.Amount) AS total_transaction_value,

    AVG(f.Amount) AS average_transaction_value

FROM fact_transactions f

WHERE f.TransactionDate IS NOT NULL

GROUP BY f.AccountOriginID

ORDER BY total_transaction_value DESC;


-- ============================================================
-- 8. ACCOUNT BEHAVIORAL BASELINE
-- ============================================================

WITH account_activity AS (

    SELECT
        AccountOriginID AS AccountID,

        COUNT(*) AS transaction_count,

        SUM(Amount) AS total_transaction_value,

        AVG(Amount) AS average_transaction_value

    FROM fact_transactions

    WHERE TransactionDate IS NOT NULL

    GROUP BY AccountOriginID
)

SELECT
    AVG(transaction_count) AS mean_transaction_count,
    STDDEV(transaction_count) AS stddev_transaction_count,

    AVG(total_transaction_value) AS mean_transaction_value,
    STDDEV(total_transaction_value) AS stddev_transaction_value,

    AVG(average_transaction_value) AS mean_average_transaction_value,
    STDDEV(average_transaction_value) AS stddev_average_transaction_value

FROM account_activity;


-- ============================================================
-- 9. ACCOUNT ANOMALY SIGNAL ANALYSIS
-- ============================================================

WITH account_activity AS (

    SELECT
        AccountOriginID AS AccountID,

        COUNT(*) AS transaction_count,

        SUM(Amount) AS total_transaction_value,

        AVG(Amount) AS average_transaction_value

    FROM fact_transactions

    WHERE TransactionDate IS NOT NULL

    GROUP BY AccountOriginID
),

baseline AS (

    SELECT

        AVG(transaction_count)
            AS mean_transaction_count,

        STDDEV(transaction_count)
            AS std_transaction_count,

        AVG(total_transaction_value)
            AS mean_transaction_value,

        STDDEV(total_transaction_value)
            AS std_transaction_value,

        AVG(average_transaction_value)
            AS mean_average_transaction_value,

        STDDEV(average_transaction_value)
            AS std_average_transaction_value

    FROM account_activity
)

SELECT
    a.AccountID,
    a.transaction_count,
    a.total_transaction_value,
    a.average_transaction_value,

    (
        CASE
            WHEN a.transaction_count >
                 b.mean_transaction_count
                 + 2 * b.std_transaction_count
            THEN 1
            ELSE 0
        END

        +

        CASE
            WHEN a.total_transaction_value >
                 b.mean_transaction_value
                 + 2 * b.std_transaction_value
            THEN 1
            ELSE 0
        END

        +

        CASE
            WHEN a.average_transaction_value >
                 b.mean_average_transaction_value
                 + 2 * b.std_average_transaction_value
            THEN 1
            ELSE 0
        END

    ) AS anomaly_score

FROM account_activity a

CROSS JOIN baseline b

ORDER BY anomaly_score DESC,
         total_transaction_value DESC;


-- ============================================================
-- 10. HIGH ANOMALY SIGNAL ACCOUNTS
-- ============================================================

WITH account_activity AS (

    SELECT
        AccountOriginID AS AccountID,

        COUNT(*) AS transaction_count,

        SUM(Amount) AS total_transaction_value,

        AVG(Amount) AS average_transaction_value

    FROM fact_transactions

    WHERE TransactionDate IS NOT NULL

    GROUP BY AccountOriginID
),

baseline AS (

    SELECT

        AVG(transaction_count)
            AS mean_transaction_count,

        STDDEV(transaction_count)
            AS std_transaction_count,

        AVG(total_transaction_value)
            AS mean_transaction_value,

        STDDEV(total_transaction_value)
            AS std_transaction_value,

        AVG(average_transaction_value)
            AS mean_average_transaction_value,

        STDDEV(average_transaction_value)
            AS std_average_transaction_value

    FROM account_activity
),

scored_accounts AS (

    SELECT
        a.AccountID,
        a.transaction_count,
        a.total_transaction_value,
        a.average_transaction_value,

        (
            CASE
                WHEN a.transaction_count >
                     b.mean_transaction_count
                     + 2 * b.std_transaction_count
                THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN a.total_transaction_value >
                     b.mean_transaction_value
                     + 2 * b.std_transaction_value
                THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN a.average_transaction_value >
                     b.mean_average_transaction_value
                     + 2 * b.std_average_transaction_value
                THEN 1
                ELSE 0
            END

        ) AS anomaly_score

    FROM account_activity a

    CROSS JOIN baseline b
)

SELECT *

FROM scored_accounts

WHERE anomaly_score >= 2

ORDER BY
    anomaly_score DESC,
    total_transaction_value DESC;


-- ============================================================
-- 11. CUSTOMER FINANCIAL PROFILE
-- ============================================================

SELECT
    c.CustomerID,
    c.FullName,
    c.CustomerType,

    COUNT(DISTINCT a.AccountID) AS account_count,

    COALESCE(
        SUM(a.Balance),
        0
    ) AS total_balance,

    COALESCE(
        COUNT(DISTINCT f.TransactionID),
        0
    ) AS transaction_count,

    COALESCE(
        SUM(f.Amount),
        0
    ) AS total_transaction_value

FROM dim_customer c

LEFT JOIN dim_account a
    ON c.CustomerID = a.CustomerID

LEFT JOIN fact_transactions f
    ON a.AccountID = f.AccountOriginID

GROUP BY
    c.CustomerID,
    c.FullName,
    c.CustomerType

ORDER BY total_balance DESC;


-- ============================================================
-- 12. NEGATIVE BALANCE ACCOUNTS
-- ============================================================

SELECT
    a.AccountID,
    a.CustomerID,
    c.FullName,
    c.CustomerType,
    a.AccountType,
    a.AccountStatus,
    a.Balance

FROM dim_account a

JOIN dim_customer c
    ON a.CustomerID = c.CustomerID

WHERE a.Balance < 0

ORDER BY a.Balance ASC;


-- ============================================================
-- 13. LARGE LOAN EXPOSURES
-- ============================================================

SELECT
    f.LoanID,
    f.AccountID,
    c.CustomerID,
    c.FullName,
    c.CustomerType,
    f.PrincipalAmount,
    f.InterestRate,
    ls.LoanStatus

FROM fact_loans f

JOIN dim_account a
    ON f.AccountID = a.AccountID

JOIN dim_customer c
    ON a.CustomerID = c.CustomerID

JOIN dim_loan_status ls
    ON f.LoanStatusID = ls.LoanStatusID

ORDER BY f.PrincipalAmount DESC
LIMIT 20;


-- ============================================================
-- 14. RISK PRIORITIZATION
-- ============================================================

WITH account_activity AS (

    SELECT
        AccountOriginID AS AccountID,

        COUNT(*) AS transaction_count,

        SUM(Amount) AS total_transaction_value,

        AVG(Amount) AS average_transaction_value

    FROM fact_transactions

    WHERE TransactionDate IS NOT NULL

    GROUP BY AccountOriginID
),

baseline AS (

    SELECT

        AVG(transaction_count)
            AS mean_transaction_count,

        STDDEV(transaction_count)
            AS std_transaction_count,

        AVG(total_transaction_value)
            AS mean_transaction_value,

        STDDEV(total_transaction_value)
            AS std_transaction_value,

        AVG(average_transaction_value)
            AS mean_average_transaction_value,

        STDDEV(average_transaction_value)
            AS std_average_transaction_value

    FROM account_activity
),

risk_scored_accounts AS (

    SELECT
        a.AccountID,

        (
            CASE
                WHEN a.transaction_count >
                     b.mean_transaction_count
                     + 2 * b.std_transaction_count
                THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN a.total_transaction_value >
                     b.mean_transaction_value
                     + 2 * b.std_transaction_value
                THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN a.average_transaction_value >
                     b.mean_average_transaction_value
                     + 2 * b.std_average_transaction_value
                THEN 1
                ELSE 0
            END

        ) AS anomaly_score,

        a.transaction_count,
        a.total_transaction_value,
        a.average_transaction_value

    FROM account_activity a

    CROSS JOIN baseline b
)

SELECT
    r.AccountID,

    c.CustomerID,
    c.CustomerType,

    COALESCE(
        SUM(l.PrincipalAmount),
        0
    ) AS total_loan_exposure,

    COALESCE(
        SUM(
            CASE
                WHEN ls.LoanStatus = 'Overdue'
                THEN l.PrincipalAmount
                ELSE 0
            END
        ),
        0
    ) AS overdue_loan_exposure,

    r.transaction_count,

    r.total_transaction_value,

    r.average_transaction_value,

    r.anomaly_score

FROM risk_scored_accounts r

JOIN dim_account a
    ON r.AccountID = a.AccountID

JOIN dim_customer c
    ON a.CustomerID = c.CustomerID

LEFT JOIN fact_loans l
    ON a.AccountID = l.AccountID

LEFT JOIN dim_loan_status ls
    ON l.LoanStatusID = ls.LoanStatusID

GROUP BY
    r.AccountID,
    c.CustomerID,
    c.CustomerType,
    r.transaction_count,
    r.total_transaction_value,
    r.average_transaction_value,
    r.anomaly_score

ORDER BY
    r.anomaly_score DESC,
    total_loan_exposure DESC,
    r.total_transaction_value DESC;