{{ config(materialized='table', schema='silver') }}

WITH snapshot_source AS (
    SELECT 
        s.*,
        s.dbt_valid_from AS ValidFromTS,
        COALESCE(s.dbt_valid_to, CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6))) AS ValidToTS
    FROM {{ ref('snap_dim_card') }} s
)
SELECT 
    -- Version-specific compound surrogate key
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONCAT(CAST(s.CardID AS VARCHAR(50)), '_', CAST(s.ValidFromTS AS VARCHAR(50)))), 2) AS [CardSK],
    
    -- Restored structural account surrogate key join target
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(s.AccountID AS VARCHAR(50))), 2) AS [AccountSK],
    
    s.CardID,
    s.AccountID,
    TRIM(s.CardNumber) AS [CardNumber],
    COALESCE(TRIM(t.[TierName]), 'Standard') AS [CardTier],
    TRIM(s.Status) AS [CardStatus],
    CAST(s.ExpiryDate AS DATE) AS [ExpiryDate],
    s.ValidFromTS,
    s.ValidToTS,
    CASE 
        WHEN s.ValidToTS >= CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6)) THEN 1 
        ELSE 0 
    END AS [IsCurrentVersion]
FROM snapshot_source s
LEFT JOIN {{ ref('bronze_cardtier') }} t ON s.CardTierID = t.CardTierID
