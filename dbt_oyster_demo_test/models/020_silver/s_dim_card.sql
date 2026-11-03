{{ config(materialized='table', schema='silver') }}

WITH snapshot_source AS (
    SELECT 
        s.*,
        s.dbt_valid_from AS OriginalValidFromTS,
        COALESCE(s.dbt_valid_to, CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6))) AS ValidToTS,
        -- Identify the very first snapshot version for each individual card
        ROW_NUMBER() OVER (
            PARTITION BY s.CardID 
            ORDER BY s.dbt_valid_from ASC
        ) AS version_num
    FROM {{ ref('ldh_oys_debitcard') }} s
),

adjusted_timestamps AS (
    SELECT
        s.*,
        -- Overwrite the first version's timestamp to the baseline history date
        CASE 
            WHEN s.version_num = 1 THEN CAST('1900-01-01 00:00:00.000000' AS DATETIME2(6))
            ELSE s.OriginalValidFromTS
        END AS [ValidFromTS]
    FROM snapshot_source s
    LEFT JOIN {{ ref('b_oys_card_tier') }} t ON s.CardTierID = t.CardTierID
)

SELECT 
    -- Version-specific compound surrogate key using the baseline-adjusted ValidFromTS
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
FROM adjusted_timestamps s
LEFT JOIN {{ ref('b_oys_card_tier') }} t ON s.CardTierID = t.CardTierID
