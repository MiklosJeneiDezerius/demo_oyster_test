{{ config(materialized='table', schema='silver') }}

WITH source_transactions AS (
    SELECT 
        t.[TransactionID], t.[AccountID], t.[Amount], t.[transaction_at] AS [TransactionTimestamp], 
        TRIM(t.[Counterparty]) AS [Counterparty], COALESCE(TRIM(ts.[StatusName]), 'Pending') AS [TransactionStatus], t.[IngestedTS]
    FROM {{ ref('b_oys_transaction') }} t
    LEFT JOIN {{ ref('b_oys_transaction_status') }} ts ON t.[TransactionStatusID] = ts.[TransactionStatusID]
),
accounts AS (
    SELECT [AccountSK], [AccountID], [CustomerID] FROM {{ ref('s_dim_account') }}
),
customer_history AS (
    SELECT [CustomerSK], [CustomerID], [ValidFromTS], [ValidToTS] FROM {{ ref('s_dim_customer') }}
),
card_history AS (
    SELECT [CardSK], [CardID], [AccountID], [ValidFromTS], [ValidToTS] FROM {{ ref('s_dim_card') }}
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
