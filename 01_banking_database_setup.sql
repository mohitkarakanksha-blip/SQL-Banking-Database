-- =====================================================
-- PROJECT: SQL_Banking_Database
-- PURPOSE: Banking Customer & Transaction Analytics
-- DATABASE: MySQL 8.0
-- =====================================================

CREATE DATABASE IF NOT EXISTS SQL_Banking_Database;

USE SQL_Banking_Database;

-- 1. BRANCHES
CREATE TABLE branches (
    branch_id INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(60) NOT NULL,
    state VARCHAR(60) NOT NULL,
    ifsc_code VARCHAR(11) NOT NULL UNIQUE
);

-- 2. CUSTOMERS
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120) UNIQUE,
    gender VARCHAR(20),
    date_of_birth DATE,
    city VARCHAR(60),
    state VARCHAR(60),
    signup_date DATE NOT NULL,
    customer_status VARCHAR(20) NOT NULL DEFAULT 'Active'
);

-- 3. ACCOUNTS
CREATE TABLE accounts (
    account_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    account_type VARCHAR(30) NOT NULL,
    opening_date DATE NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    account_status VARCHAR(20) NOT NULL DEFAULT 'Active',

    CONSTRAINT fk_account_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_account_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
);

-- 4. TRANSACTIONS
CREATE TABLE transactions (
    transaction_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    account_id BIGINT NOT NULL,
    transaction_date DATETIME NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    payment_mode VARCHAR(30),
    transaction_status VARCHAR(20) NOT NULL,
    merchant_category VARCHAR(60),

    CONSTRAINT fk_transaction_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);

-- 5. CARDS
CREATE TABLE cards (
    card_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    account_id BIGINT NOT NULL,
    card_type VARCHAR(30) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    card_status VARCHAR(20) NOT NULL DEFAULT 'Active',

    CONSTRAINT fk_card_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);

-- 6. LOANS
CREATE TABLE loans (
    loan_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    loan_type VARCHAR(30) NOT NULL,
    loan_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    loan_start_date DATE NOT NULL,
    loan_term_months INT NOT NULL,
    loan_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_loan_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_loan_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
);

-- 7. LOAN PAYMENTS
CREATE TABLE loan_payments (
    payment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    loan_id BIGINT NOT NULL,
    due_date DATE NOT NULL,
    payment_date DATE,
    installment_amount DECIMAL(12,2) NOT NULL,
    amount_paid DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_payment_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
);

-- 8. CUSTOMER SUPPORT
CREATE TABLE customer_support (
    ticket_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    account_id BIGINT,
    issue_category VARCHAR(60) NOT NULL,
    ticket_date DATETIME NOT NULL,
    resolution_date DATETIME,
    priority VARCHAR(20) NOT NULL,
    ticket_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_support_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_support_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);


-- INDEXES FOR COMMON ANALYTICS QUERIES
CREATE INDEX idx_accounts_customer
    ON accounts(customer_id);

CREATE INDEX idx_transactions_date
    ON transactions(transaction_date);

CREATE INDEX idx_transactions_account_date
    ON transactions(account_id, transaction_date);

CREATE INDEX idx_loans_customer
    ON loans(customer_id);

CREATE INDEX idx_loan_payments_loan
    ON loan_payments(loan_id);

CREATE INDEX idx_support_customer
    ON customer_support(customer_id);

-- VERIFY DATABASE TABLES
SHOW TABLES;   


USE SQL_Banking_Database;

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_banking_data$$

CREATE PROCEDURE generate_banking_data()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    DECLARE v_customer INT;
    DECLARE v_account BIGINT;
    DECLARE v_loan BIGINT;
    DECLARE v_branch INT;
    DECLARE v_due DATE;
    DECLARE v_ticket_date DATETIME;
    DECLARE v_amount DECIMAL(12,2);
    DECLARE v_r DOUBLE;
    DECLARE v_type VARCHAR(30);
    DECLARE v_status VARCHAR(20);

    -- 1. BRANCHES: 10
    SET i = 1;
    WHILE i <= 10 DO
        INSERT INTO branches
            (branch_id, branch_name, city, state, ifsc_code)
        VALUES (
            i,
            CONCAT(ELT(1 + MOD(i-1,5),
                'Central','City','Main','North','South'),
                ' Branch ', i),
            ELT(i,
                'Nagpur','Mumbai','Pune','Nashik','Delhi',
                'Bengaluru','Hyderabad','Chennai','Jaipur','Kolkata'),
            ELT(i,
                'Maharashtra','Maharashtra','Maharashtra',
                'Maharashtra','Delhi','Karnataka','Telangana',
                'Tamil Nadu','Rajasthan','West Bengal'),
            CONCAT('BNK', LPAD(i,8,'0'))
        );
        SET i = i + 1;
    END WHILE;

    -- 2. CUSTOMERS: 500
    SET i = 1;
    WHILE i <= 500 DO
        INSERT INTO customers
            (customer_id, first_name, last_name, email,
             gender, date_of_birth, city, state,
             signup_date, customer_status)
        VALUES (
            i,
            ELT(1 + MOD(i-1,12),
                'Aarav','Akanksha','Priya','Rahul',
                'Sneha','Rohan','Neha','Amit',
                'Ananya','Vikram','Pooja','Karan'),
            ELT(1 + MOD(i-1,10),
                'Sharma','Patil','Verma','Joshi','Singh',
                'Deshmukh','Gupta','Khan','Reddy','Mehta'),
            CONCAT('customer', i, '@example.com'),
            ELT(1 + MOD(i-1,3),'Female','Male','Other'),
            DATE_SUB('2005-01-01',
                INTERVAL (6570 + MOD(i*37,14600)) DAY),
            ELT(1 + MOD(i-1,10),
                'Nagpur','Mumbai','Pune','Nashik','Delhi',
                'Bengaluru','Hyderabad','Chennai','Jaipur','Kolkata'),
            ELT(1 + MOD(i-1,10),
                'Maharashtra','Maharashtra','Maharashtra',
                'Maharashtra','Delhi','Karnataka','Telangana',
                'Tamil Nadu','Rajasthan','West Bengal'),
            DATE_SUB(CURDATE(), INTERVAL MOD(i*17,1500) DAY),
            IF(MOD(i,10)=0,'Inactive','Active')
        );
        SET i = i + 1;
    END WHILE;

    -- 3. ACCOUNTS: 700
    SET i = 1;
    WHILE i <= 700 DO
        SET v_customer = 1 + MOD(i*37,500);
        SET v_branch = 1 + MOD(i*7,10);

        INSERT INTO accounts
            (account_id, customer_id, branch_id, account_type,
             opening_date, balance, account_status)
        VALUES (
            i,
            v_customer,
            v_branch,
            ELT(1 + MOD(i-1,4),
                'Savings','Current','Salary','Fixed Deposit'),
            DATE_SUB(CURDATE(), INTERVAL MOD(i*11,1200) DAY),
            ROUND(500 + RAND()*199500, 2),
            IF(MOD(i,15)=0,'Inactive','Active')
        );
        SET i = i + 1;
    END WHILE;

    -- 4. TRANSACTIONS: 3000
    SET i = 1;
    WHILE i <= 3000 DO
        SET v_type = ELT(1 + MOD(i-1,4),
            'Deposit','Withdrawal','Transfer','Payment');

        INSERT INTO transactions
            (transaction_id, account_id, transaction_date,
             transaction_type, amount, payment_mode,
             transaction_status, merchant_category)
        VALUES (
            i,
            1 + MOD(i*19,700),
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*730) DAY),
            v_type,
            ROUND(100 + RAND()*49900, 2),
            ELT(1 + MOD(i-1,5),
                'UPI','Debit Card','NEFT','IMPS','Net Banking'),
            ELT(1 + MOD(i-1,20),
                'Successful','Successful','Successful',
                'Successful','Failed','Pending','Successful',
                'Successful','Successful','Successful',
                'Successful','Successful','Successful',
                'Successful','Successful','Successful',
                'Successful','Successful','Successful','Successful'),
            ELT(1 + MOD(i-1,8),
                'Groceries','Shopping','Utilities','Travel',
                'Healthcare','Education','Dining','Other')
        );
        SET i = i + 1;
    END WHILE;

    -- 5. CARDS: 400
    SET i = 1;
    WHILE i <= 400 DO
        INSERT INTO cards
            (card_id, account_id, card_type,
             issue_date, expiry_date, card_status)
        VALUES (
            i,
            1 + MOD(i*13,700),
            ELT(1 + MOD(i-1,3),
                'Debit','Credit','Contactless'),
            DATE_SUB(CURDATE(), INTERVAL MOD(i*7,900) DAY),
            DATE_ADD(CURDATE(), INTERVAL (365 + MOD(i,1460)) DAY),
            IF(MOD(i,12)=0,'Blocked','Active')
        );
        SET i = i + 1;
    END WHILE;

    -- 6. LOANS: 200
    SET i = 1;
    WHILE i <= 200 DO
        INSERT INTO loans
            (loan_id, customer_id, branch_id, loan_type,
             loan_amount, interest_rate, loan_start_date,
             loan_term_months, loan_status)
        VALUES (
            i,
            1 + MOD(i*23,500),
            1 + MOD(i*3,10),
            ELT(1 + MOD(i-1,4),
                'Personal','Home','Vehicle','Education'),
            ROUND(50000 + RAND()*1950000, 2),
            ROUND(7 + RAND()*8, 2),
            DATE_SUB(CURDATE(), INTERVAL (180 + MOD(i*7,900)) DAY),
            ELT(1 + MOD(i-1,4),12,24,36,60),
            ELT(1 + MOD(i-1,4),
                'Active','Active','Closed','Pending')
        );
        SET i = i + 1;
    END WHILE;

    -- 7. LOAN PAYMENTS: 6 per loan = 1200
    SET i = 1;
    WHILE i <= 200 DO
        SET j = 1;
        WHILE j <= 6 DO
            SET v_loan = i;
            SET v_due = DATE_ADD(
                (SELECT loan_start_date
                 FROM loans WHERE loan_id = v_loan),
                INTERVAL j MONTH
            );
            SET v_amount = ROUND(2000 + RAND()*18000, 2);
            SET v_r = RAND();

            IF v_due > CURDATE() THEN
                SET v_status = 'Upcoming';
            ELSEIF v_r < 0.75 THEN
                SET v_status = 'Paid';
            ELSEIF v_r < 0.90 THEN
                SET v_status = 'Late';
            ELSE
                SET v_status = 'Overdue';
            END IF;

            INSERT INTO loan_payments
                (payment_id, loan_id, due_date, payment_date,
                 installment_amount, amount_paid, payment_status)
            VALUES (
                (i-1)*6+j,
                v_loan,
                v_due,
                CASE
                    WHEN v_status IN ('Paid','Late')
                    THEN DATE_ADD(v_due, INTERVAL
                        IF(v_status='Late',
                           1 + FLOOR(RAND()*10),
                           -FLOOR(RAND()*5)) DAY)
                    ELSE NULL
                END,
                v_amount,
                CASE
                    WHEN v_status IN ('Paid','Late') THEN v_amount
                    ELSE 0
                END,
                v_status
            );
            SET j = j + 1;
        END WHILE;
        SET i = i + 1;
    END WHILE;

    -- 8. CUSTOMER SUPPORT: 300
    SET i = 1;
    WHILE i <= 300 DO
        SET v_account = 1 + MOD(i*17,700);

        SELECT customer_id INTO v_customer
        FROM accounts WHERE account_id = v_account;

        SET v_ticket_date = DATE_SUB(
            NOW(), INTERVAL MOD(i*3,180) DAY
        );

        INSERT INTO customer_support
            (ticket_id, customer_id, account_id,
             issue_category, ticket_date, resolution_date,
             priority, ticket_status)
        VALUES (
            i,
            v_customer,
            v_account,
            ELT(1 + MOD(i-1,6),
                'Transaction Failure','Card Issue','Loan Query',
                'Account Access','Fraud Report','Other'),
            v_ticket_date,
            CASE
                WHEN MOD(i,4)=0 THEN NULL
                ELSE DATE_ADD(v_ticket_date,
                    INTERVAL (1 + MOD(i,10)) DAY)
            END,
            ELT(1 + MOD(i-1,3),'Low','Medium','High'),
            IF(MOD(i,4)=0,'Open','Resolved')
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

-- Generate all synthetic records
CALL generate_banking_data();

-- Remove the helper procedure after successful generation
DROP PROCEDURE generate_banking_data;

USE SQL_Banking_Database;

-- verify that the data is inserted
SELECT 'branches' AS table_name, COUNT(*) AS total_records FROM branches
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'cards', COUNT(*) FROM cards
UNION ALL
SELECT 'loans', COUNT(*) FROM loans
UNION ALL
SELECT 'loan_payments', COUNT(*) FROM loan_payments
UNION ALL
SELECT 'customer_support', COUNT(*) FROM customer_support;

-- View customers
SELECT * FROM customers LIMIT 10;

-- View accounts with customer names
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_id,
    a.account_type,
    a.balance
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
LIMIT 10;

-- View recent transactions
SELECT *
FROM transactions
ORDER BY transaction_date DESC
LIMIT 10;

-- View loan payment statuses
SELECT payment_status, COUNT(*) AS total
FROM loan_payments
GROUP BY payment_status;
