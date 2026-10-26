{{ config(materialized='table', schema='silver') }}

WITH source_transactions AS (
    SELECT 
        t.[TransactionID], t.[AccountID], t.[Amount], t.[transaction_at] AS [TransactionTimestamp], 
        TRIM(t.[Counterparty]) AS [Counterparty], COALESCE(TRIM(ts.[StatusName]), 'Pending') AS [TransactionStatus], t.[IngestedTS]
    FROM {{ ref('bronze_transaction') }} t
    LEFT JOIN {{ ref('bronze_transactionstatus') }} ts ON t.[TransactionStatusID] = ts.[TransactionStatusID]
),
account_history AS (
    SELECT [AccountSK], [AccountID], [CustomerID], [ValidFromTS] FROM {{ ref('dim_account') }}
),
customer_history AS (
    SELECT [CustomerSK], [CustomerID], [ValidFromTS], [ValidToTS] FROM {{ ref('dim_customer') }}
),
card_history AS (
    SELECT [CardSK], [CardID], [AccountID], [ValidFromTS], [ValidToTS] FROM {{ ref('dim_card') }}
)
SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(st.[TransactionID] AS VARCHAR(50))), 2) AS [TransactionSK],
    
    -- Point-in-time dimensional alignment using transaction timestamps
    COALESCE(dc.[CardSK], 'UNASSIGNED') AS [CardSK],
    da.[AccountSK],
    dcuh.[CustomerSK],
    
    CAST(FORMAT(st.[TransactionTimestamp], 'yyyyMMdd') AS INT) AS [TransactionDateSK],
    st.[TransactionID],
    st.[AccountID],
    st.[Amount],
    st.[TransactionTimestamp],
    st.[Counterparty],
    st.[TransactionStatus]
FROM source_transactions st

-- 1. Map to the exact Account record state active during the transaction
INNER JOIN account_history da 
    ON st.[AccountID] = da.[AccountID]
    --AND st.[TransactionTimestamp] BETWEEN da.[ValidFromTS] AND da.[ValidToTS]

-- 2. Map to the exact Customer profile state active during the transaction
INNER JOIN customer_history dcuh 
    ON da.[CustomerID] = dcuh.[CustomerID]
    AND st.[TransactionTimestamp] BETWEEN dcuh.[ValidFromTS] AND dcuh.[ValidToTS]

-- 3. Map to the exact Card asset state active during the transaction
LEFT JOIN card_history dc 
    ON st.[AccountID] = dc.[AccountID]
    AND st.[TransactionTimestamp] BETWEEN dc.[ValidFromTS] AND dc.[ValidToTS]
