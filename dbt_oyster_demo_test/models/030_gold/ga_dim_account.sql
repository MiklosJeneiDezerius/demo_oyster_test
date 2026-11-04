{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT
    [s_dim_account_sk] AS [ga_dim_account_sk]
    ,[s_dim_customer_sk]
    ,[account_id]
    ,[customer_id]
    ,[account_number_txt]
    ,[account_type_nm]
    ,[current_balance_amt]
    ,[currency_cd]
FROM {{ ref('s_dim_account') }}