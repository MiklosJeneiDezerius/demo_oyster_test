{{ config(materialized='table', schema='core_silver') }}

WITH ranked_cards AS (
    SELECT
        c.[AccountID],
        c.[CardSK],
        ROW_NUMBER() OVER (
            PARTITION BY c.[AccountID]
            ORDER BY c.[CardID] DESC
        ) AS [CardRank]
    FROM {{ ref('s_dim_card') }} c
)
SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(t.[TransactionID] AS VARCHAR(50))), 2) AS [TransactionSK],
    a.[AccountSK],
    a.[CustomerSK],
    c.[CardSK],
    CONVERT(INT, CONVERT(CHAR(8), t.[TransactionTimestamp], 112)) AS [TransactionDateSK],
    t.[TransactionID],
    t.[AccountID],
    t.[Amount],
    t.[TransactionTimestamp]
FROM {{ ref('b_oys_transaction') }} t
INNER JOIN {{ ref('s_dim_account') }} a
    ON t.[AccountID] = a.[AccountID]
LEFT JOIN ranked_cards c
    ON t.[AccountID] = c.[AccountID]
   AND c.[CardRank] = 1