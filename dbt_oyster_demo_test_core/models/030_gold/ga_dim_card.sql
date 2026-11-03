{{ config(materialized='table', schema='core_gold') }}

SELECT
    [CardSK],
    [AccountSK],
    [CardID],
    [AccountID],
    [CardTier]
FROM {{ ref('s_dim_card') }}