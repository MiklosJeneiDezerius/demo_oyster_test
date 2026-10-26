{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT
    [CardSK]
    ,[AccountSK] -- Restored and validated account mapping link
    ,[CardID]
    ,[AccountID]
    ,[CardNumber]
    ,[CardTier]
    ,[CardStatus]
    ,[ExpiryDate]
    ,[ValidFromTS]
    ,[ValidToTS]
FROM {{ ref('dim_card') }}
WHERE [IsCurrentVersion] = 1