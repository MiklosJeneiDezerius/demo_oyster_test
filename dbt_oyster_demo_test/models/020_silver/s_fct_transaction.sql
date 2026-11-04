{{ config(materialized='table', schema='silver') }}

WITH source_transactions AS (
    SELECT 
        t.[transaction_id] AS [TransactionID],
        t.[account_id] AS [AccountID],
        t.[transaction_amt] AS [Amount],
        t.[transaction_dttm] AS [TransactionTimestamp],
        TRIM(t.[counterparty_nm]) AS [Counterparty],
        COALESCE(TRIM(ts.[status_nm]), 'Pending') AS [TransactionStatus],
        t.[ingested_dttm] AS [IngestedTS]
    FROM {{ ref('b_oys_transaction') }} t
    LEFT JOIN {{ ref('b_oys_transaction_status') }} ts
        ON t.[transaction_status_id] = ts.[transaction_status_id]
),
accounts AS (
    SELECT
        [s_dim_account_sk] AS [AccountSK],
        [account_id] AS [AccountID],
        [customer_id] AS [CustomerID]
    FROM {{ ref('s_dim_account') }}
),
customer_history AS (
    SELECT
        [s_dim_customer_sk] AS [CustomerSK],
        [customer_id] AS [CustomerID],
        [valid_from_dttm] AS [ValidFromTS],
        [valid_to_dttm] AS [ValidToTS]
    FROM {{ ref('s_dim_customer') }}
),
card_history AS (
    SELECT
        [s_dim_card_sk] AS [CardSK],
        [card_id] AS [CardID],
        [account_id] AS [AccountID],
        [valid_from_dttm] AS [ValidFromTS],
        [valid_to_dttm] AS [ValidToTS]
    FROM {{ ref('s_dim_card') }}
)
SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(st.[TransactionID] AS VARCHAR(50))), 2) AS [s_fct_transaction_sk],
    
    -- Point-in-time dimensional alignment using transaction timestamps
    COALESCE(dc.[CardSK], 'UNASSIGNED') AS [s_dim_card_sk],
    da.[AccountSK] AS [s_dim_account_sk],
    dcuh.[CustomerSK] AS [s_dim_customer_sk],
    
    CAST(FORMAT(st.[TransactionTimestamp], 'yyyyMMdd') AS INT) AS [s_dim_date_sk],
    st.[TransactionID] AS [transaction_id],
    st.[AccountID] AS [account_id],
    st.[Amount] AS [transaction_amt],
    st.[TransactionTimestamp] AS [transaction_dttm],
    st.[Counterparty] AS [counterparty_nm],
    st.[TransactionStatus] AS [transaction_status_cd]
FROM source_transactions st

INNER JOIN accounts da
    ON st.[AccountID] = da.[AccountID]

-- 2. Map to the exact Customer profile state active during the transaction
INNER JOIN customer_history dcuh 
    ON da.[CustomerID] = dcuh.[CustomerID]
    AND st.[TransactionTimestamp] BETWEEN dcuh.[ValidFromTS] AND DATEADD(MICROSECOND, -1, ISNULL(dcuh.[ValidToTS], '9999-12-31 00:00:00.000000'))

-- 3. Map to the exact Card asset state active during the transaction
LEFT JOIN card_history dc 
    ON st.[AccountID] = dc.[AccountID]
    AND st.[TransactionTimestamp] BETWEEN dc.[ValidFromTS] AND DATEADD(MICROSECOND, -1, ISNULL(dc.[ValidToTS], '9999-12-31 00:00:00.000000'))
