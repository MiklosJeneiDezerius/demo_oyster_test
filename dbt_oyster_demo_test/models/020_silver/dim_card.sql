-- models/010_silver/dim_card.sql
{{ config(
    materialized='table', 
    schema='silver'
) }}

WITH snapshot_source AS (
    SELECT 
        CardID,
        AccountID,
        TRIM(CardNumber) AS CardNumber,
        TRIM(Tier) AS CardTier,
        TRIM(Status) AS CardStatus,
        TRY_CAST(Expiry AS DATE) AS ExpiryDate,
        dbt_valid_from AS ValidFromTS,
        -- Force explicit (6) precision with a fully structured ISO string literal
        COALESCE(dbt_valid_to, CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6))) AS ValidToTS
    FROM {{ ref('snap_dim_card') }}
)

SELECT 
    -- Generating Card Surrogate Key
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(CardID AS VARCHAR(50)), 
            '_', 
            CAST(ValidFromTS AS VARCHAR(50))
        )
    ), 2) AS CardSK,
    
    CardID,
    
    -- Generating Account Surrogate Key
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 
        CAST(AccountID AS VARCHAR(50))
    ), 2) AS AccountSK,
    
    AccountID,
    CardNumber,
    CardTier,
    CardStatus,
    ExpiryDate,
    ValidFromTS,
    ValidToTS,
    
    -- Check for the current open record version using explicit precision matching
    CASE 
        WHEN ValidToTS >= CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6)) THEN 1 
        ELSE 0 
    END AS IsCurrentVersion

FROM snapshot_source
