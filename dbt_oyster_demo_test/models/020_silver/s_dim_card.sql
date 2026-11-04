{{ config(materialized='table', schema='silver') }}

WITH snapshot_source AS (
    SELECT 
        s.*,
        s.m_valid_from_dttm AS OriginalValidFromTS,
        COALESCE(s.m_valid_to_dttm, CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6))) AS ValidToTS,
        -- Identify the very first snapshot version for each individual card
        ROW_NUMBER() OVER (
            PARTITION BY s.CardID 
            ORDER BY s.m_valid_from_dttm ASC
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
    LEFT JOIN {{ ref('b_oys_card_tier') }} t ON s.CardTierID = t.card_tier_id
)

SELECT 
    -- Version-specific compound surrogate key using the baseline-adjusted ValidFromTS
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONCAT(CAST(s.CardID AS VARCHAR(50)), '_', CAST(s.ValidFromTS AS VARCHAR(50)))), 2) AS [s_dim_card_sk],
    
    -- Restored structural account surrogate key join target
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(s.AccountID AS VARCHAR(50))), 2) AS [s_dim_account_sk],
    
    s.CardID AS [card_id],
    s.AccountID AS [account_id],
    TRIM(s.CardNumber) AS [card_number_txt],
    COALESCE(TRIM(t.[tier_nm]), 'Standard') AS [card_tier_nm],
    TRIM(s.Status) AS [card_status_cd],
    CAST(s.ExpiryDate AS DATE) AS [expiry_dt],
    s.ValidFromTS AS [valid_from_dttm],
    s.ValidToTS AS [valid_to_dttm],
    CASE 
        WHEN s.ValidToTS >= CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6)) THEN 1 
        ELSE 0 
    END AS [is_current_version_flag]
FROM adjusted_timestamps s
LEFT JOIN {{ ref('b_oys_card_tier') }} t ON s.CardTierID = t.card_tier_id
