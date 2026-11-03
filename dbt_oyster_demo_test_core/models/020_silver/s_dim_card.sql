{{ config(materialized='table', schema='core_silver') }}

SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(c.[CardID] AS VARCHAR(50))), 2) AS [CardSK],
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(c.[AccountID] AS VARCHAR(50))), 2) AS [AccountSK],
    c.[CardID],
    c.[AccountID],
    COALESCE(NULLIF(c.[CardTier], ''), 'Standard') AS [CardTier]
FROM {{ ref('b_oys_debit_card') }} c