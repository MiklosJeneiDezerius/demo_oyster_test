{{ config(materialized='table', schema='silver') }}

WITH source_transactions AS (
    SELECT 
        [TransactionID], 
        [CardID], 
        [Amount], 
        [transaction_at] AS [TransactionTimestamp], 
        TRIM([Counterparty]) AS [Counterparty], 
        TRIM([Status]) AS [TransactionStatus], 
        [IngestedTS]
    FROM {{ ref('bronze_transaction') }}
),
card_bridge AS (
    SELECT [CardID], [AccountID] 
    FROM {{ ref('bronze_debitcard') }}
),
account_bridge AS (
    SELECT [AccountID], [CustomerID] 
    FROM {{ ref('bronze_account') }}
)

SELECT
    -- Primary Surrogate Key
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(t.[TransactionID] AS VARCHAR(50))), 2) AS [TransactionSK],
    
    -- Dimension Foreign Keys (Star Schema Framework)
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(t.[CardID] AS VARCHAR(50))), 2) AS [CardSK],
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(cb.[AccountID] AS VARCHAR(50))), 2) AS [AccountSK],
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(ab.[CustomerID] AS VARCHAR(50))), 2) AS [CustomerSK],
    
    -- Optimized Date Dimension Foreign Key (YYYYMMDD integer format matching dim_date.DateSK)
    CAST(FORMAT(t.[TransactionTimestamp], 'yyyyMMdd') AS INT) AS [TransactionDateSK],
    
    -- Degenerate Dimensions & Business Keys
    t.[TransactionID], 
    t.[CardID], 
    cb.[AccountID], 
    ab.[CustomerID], 
    
    -- Fact Measures & Timestamps
    t.[Amount], 
    t.[TransactionTimestamp], 
    t.[Counterparty], 
    t.[TransactionStatus], 
    t.[IngestedTS]

FROM source_transactions t
LEFT JOIN card_bridge cb ON t.[CardID] = cb.[CardID]
LEFT JOIN account_bridge ab ON cb.[AccountID] = ab.[AccountID]
