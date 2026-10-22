{{ config(materialized='table', schema='gold') }}
SELECT 
    CardSK, CardID, AccountSK, AccountID, CardNumber, CardTier, CardStatus, ExpiryDate, IsCurrentVersion
FROM {{ ref('dim_card') }}
WHERE IsCurrentVersion = 1
