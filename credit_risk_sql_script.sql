-- Creating table
DROP TABLE IF EXISTS credit_data;

CREATE TABLE credit_data (
    ID NUMERIC,
    LIMIT_BAL NUMERIC,
    SEX NUMERIC,
    EDUCATION NUMERIC,
    MARRIAGE NUMERIC,
    AGE NUMERIC,
    PAY_0 NUMERIC,
    PAY_2 NUMERIC,
    PAY_3 NUMERIC,
    PAY_4 NUMERIC,
    PAY_5 NUMERIC,
    PAY_6 NUMERIC,
    BILL_AMT1 NUMERIC,
    BILL_AMT2 NUMERIC,
    BILL_AMT3 NUMERIC,
    BILL_AMT4 NUMERIC,
    BILL_AMT5 NUMERIC,
    BILL_AMT6 NUMERIC,
    PAY_AMT1 NUMERIC,
    PAY_AMT2 NUMERIC,
    PAY_AMT3 NUMERIC,
    PAY_AMT4 NUMERIC,
    PAY_AMT5 NUMERIC,
    PAY_AMT6 NUMERIC,
    default_payment_next_month NUMERIC
);

-- Checking import
SELECT * FROM credit_data LIMIT 20;

SELECT COUNT(*) AS row_count FROM credit_data;

-- Checking for NULL values
SELECT 
    SUM(CASE WHEN LIMIT_BAL IS NULL THEN 1 ELSE 0 END) AS limit_nulls,
    SUM(CASE WHEN SEX IS NULL THEN 1 ELSE 0 END) AS sex_nulls,
    SUM(CASE WHEN EDUCATION IS NULL THEN 1 ELSE 0 END) AS education_nulls,
    SUM(CASE WHEN MARRIAGE IS NULL THEN 1 ELSE 0 END) AS marriage_nulls,
    SUM(CASE WHEN AGE IS NULL THEN 1 ELSE 0 END) AS age_nulls,
    SUM(CASE WHEN default_payment_next_month IS NULL THEN 1 ELSE 0 END) AS default_nulls
FROM credit_data;

-- Checking ranges
SELECT MIN(LIMIT_BAL), MAX(LIMIT_BAL) FROM credit_data;
SELECT MIN(AGE), MAX(AGE) FROM credit_data;
SELECT DISTINCT SEX FROM credit_data ORDER BY SEX;
SELECT DISTINCT EDUCATION FROM credit_data ORDER BY EDUCATION;
SELECT DISTINCT MARRIAGE FROM credit_data ORDER BY MARRIAGE;

-- Creating categorical labels
CREATE OR REPLACE VIEW credit_data_clean AS
SELECT
    id,
    limit_bal,
    
    -- Sex
    CASE 
        WHEN sex = 1 THEN 'Male'
        WHEN sex = 2 THEN 'Female'
        ELSE 'Unknown'
    END AS sex_label,

    -- Education
    CASE 
        WHEN education = 1 THEN 'Graduate School'
        WHEN education = 2 THEN 'University'
        WHEN education = 3 THEN 'High School'
        WHEN education IN (4,5,6,0) THEN 'Other / Unknown'
        ELSE 'Other / Unknown'
    END AS education_label,

    -- Marriage
    CASE 
        WHEN marriage = 1 THEN 'Married'
        WHEN marriage = 2 THEN 'Single'
        WHEN marriage = 3 THEN 'Other'
        ELSE 'Unknown'
    END AS marriage_label,

    age,

    -- Age buckets
    CASE
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        WHEN age >= 60 THEN '60+'
    END AS age_group,

    pay_0, pay_2, pay_3, pay_4, pay_5, pay_6,
    bill_amt1, bill_amt2, bill_amt3, bill_amt4, bill_amt5, bill_amt6,
    pay_amt1, pay_amt2, pay_amt3, pay_amt4, pay_amt5, pay_amt6,
    default_payment_next_month
FROM credit_data;

-- Create KPI
CREATE OR REPLACE VIEW credit_kpi AS
SELECT
    COUNT(*) AS total_customers,
    SUM(default_payment_next_month) AS customers_in_default,
    ROUND( SUM(default_payment_next_month)::NUMERIC / COUNT(*) * 100, 2 ) AS default_rate_pct,
    
    ROUND(AVG(limit_bal), 0) AS avg_credit_limit,
    SUM(limit_bal) AS total_credit_exposure
FROM credit_data;

-- Default rate by gender
CREATE OR REPLACE VIEW default_by_sex AS
SELECT
    sex_label,
    COUNT(*) AS total_customers,
    SUM(default_payment_next_month) AS defaults,
    ROUND( SUM(default_payment_next_month)::NUMERIC / COUNT(*) * 100, 2 ) AS default_rate_pct
FROM credit_data_clean
GROUP BY sex_label
ORDER BY default_rate_pct DESC;

-- Default rate by education
CREATE OR REPLACE VIEW default_by_education AS
SELECT
    education_label,
    COUNT(*) AS total_customers,
    SUM(default_payment_next_month) AS defaults,
    ROUND( SUM(default_payment_next_month)::NUMERIC / COUNT(*) * 100, 2 ) AS default_rate_pct
FROM credit_data_clean
GROUP BY education_label
ORDER BY default_rate_pct DESC;

-- Default rate by age group
CREATE OR REPLACE VIEW default_by_age_group AS
SELECT
    age_group,
    COUNT(*) AS total_customers,
    SUM(default_payment_next_month) AS defaults,
    ROUND( SUM(default_payment_next_month)::NUMERIC / COUNT(*) * 100, 2 ) AS default_rate_pct
FROM credit_data_clean
GROUP BY age_group
ORDER BY age_group;

-- Credit limit buckets
CREATE OR REPLACE VIEW credit_limit_buckets AS
SELECT *,
    CASE 
        WHEN limit_bal < 50000 THEN '< 50k'
        WHEN limit_bal BETWEEN 50000 AND 100000 THEN '50k - 100k'
        WHEN limit_bal BETWEEN 100001 AND 200000 THEN '100k - 200k'
        WHEN limit_bal BETWEEN 200001 AND 500000 THEN '200k - 500k'
        ELSE '500k+'
    END AS limit_bucket
FROM credit_data_clean;

-- Confirming success
SELECT * FROM credit_data_clean LIMIT 5;
SELECT * FROM credit_kpi;
SELECT * FROM default_by_sex;
SELECT * FROM default_by_education;
SELECT * FROM default_by_age_group;
SELECT * FROM credit_limit_buckets;