-- JOIN : Customer Transaction Analysis
USE SQL_Banking_Database;

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_id,
    t.transaction_id,
    t.transaction_type,
    t.amount,
    t.transaction_date,
    t.transaction_status
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN transactions t
    ON a.account_id = t.account_id
ORDER BY t.transaction_date DESC
LIMIT 20;

-- GROUP BY : Analyze Transaction activity
SELECT
    transaction_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(AVG(amount), 2) AS average_transaction_amount
FROM transactions
WHERE transaction_status = 'Successful'
GROUP BY transaction_type
ORDER BY total_transaction_value DESC;

-- Subquery: Find above-average customers
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(a.balance) AS total_balance
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(a.balance) > (
    SELECT AVG(customer_balance)
    FROM (
        SELECT
            customer_id,
            SUM(balance) AS customer_balance
        FROM accounts
        GROUP BY customer_id
    ) AS customer_totals
)
ORDER BY total_balance DESC;

-- CTE: Monthly Transaction Trends
WITH monthly_analysis AS (
    SELECT
        DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
        COUNT(*) AS total_transactions,
        SUM(amount) AS total_value
    FROM transactions
    WHERE transaction_status = 'Successful'
    GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
)
SELECT
    transaction_month,
    total_transactions,
    ROUND(total_value, 2) AS total_transaction_value
FROM monthly_analysis
ORDER BY transaction_month;

-- Window Function: Rank top customers
WITH customer_transactions AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM(t.amount) AS total_transaction_value
    FROM customers c
    JOIN accounts a
        ON c.customer_id = a.customer_id
    JOIN transactions t
        ON a.account_id = t.account_id
    WHERE t.transaction_status = 'Successful'
    GROUP BY c.customer_id, c.first_name, c.last_name
),
ranked_customers AS (
    SELECT
        customer_id,
        customer_name,
        total_transaction_value,
        DENSE_RANK() OVER (
            ORDER BY total_transaction_value DESC
        ) AS customer_rank
    FROM customer_transactions
)
SELECT
    customer_id,
    customer_name,
    ROUND(total_transaction_value, 2) AS total_transaction_value,
    customer_rank
FROM ranked_customers
WHERE customer_rank <= 10
ORDER BY customer_rank, customer_id;

-- Data Quality Testing
USE SQL_Banking_Database;

-- 1. Check total records in all 8 tables
SELECT 'branches' AS table_name, COUNT(*) AS total FROM branches
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'cards', COUNT(*) FROM cards
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'loan_payments', COUNT(*) FROM loan_payments
UNION ALL SELECT 'customer_support', COUNT(*) FROM customer_support;

-- 2. Find transactions with invalid amounts
SELECT *
FROM transactions
WHERE amount <= 0;

-- 3. Find loans with invalid amounts or interest rates
SELECT *
FROM loans
WHERE loan_amount <= 0
   OR interest_rate <= 0
   OR interest_rate > 100;

-- 4. Check whether any loan payment exceeds its installment
SELECT *
FROM loan_payments
WHERE amount_paid > installment_amount;

-- =============================//
-- Banking Business Analysis
-- =============================//
-- Que.1 : Which cities have the highest customer balance ?
USE SQL_Banking_Database;

SELECT
    c.city,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(a.account_id) AS total_accounts,
    ROUND(SUM(a.balance), 2) AS total_balance
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
GROUP BY c.city
ORDER BY total_balance DESC;

-- Que.2: Which branches have the most successful transactions?
SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    COUNT(t.transaction_id) AS successful_transactions,
    ROUND(SUM(t.amount), 2) AS successful_transaction_value
FROM branches b
JOIN accounts a
    ON b.branch_id = a.branch_id
JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.transaction_status = 'Successful'
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY successful_transactions DESC;


-- Que.3: What percentage of due loan payments are overdue?
SELECT
    COUNT(CASE
        WHEN payment_status = 'Overdue' THEN 1
    END) AS overdue_payments,

    COUNT(CASE
        WHEN due_date <= CURDATE() THEN 1
    END) AS total_due_payments,

    ROUND(
        100.0 * COUNT(CASE
            WHEN payment_status = 'Overdue' THEN 1
        END)
        / NULLIF(COUNT(CASE
            WHEN due_date <= CURDATE() THEN 1
        END), 0),
        2
    ) AS overdue_percentage
FROM loan_payments
WHERE due_date <= CURDATE();

-- Que.4: Which customer-support issues remain unresolved
SELECT
    issue_category,
    priority,
    COUNT(*) AS open_tickets
FROM customer_support
WHERE ticket_status = 'Open'
GROUP BY issue_category, priority
ORDER BY open_tickets DESC;


-- Que.5: Rank customer within in city
WITH customer_balances AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.city,
        SUM(a.balance) AS total_balance
    FROM customers c
    JOIN accounts a
        ON c.customer_id = a.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.city
),
ranked_customers AS (
    SELECT
        customer_id,
        customer_name,
        city,
        total_balance,
        DENSE_RANK() OVER (
            PARTITION BY city
            ORDER BY total_balance DESC
        ) AS city_rank
    FROM customer_balances
)
SELECT *
FROM ranked_customers
WHERE city_rank <= 3
ORDER BY city, city_rank;
