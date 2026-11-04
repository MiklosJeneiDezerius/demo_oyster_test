{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT
    [s_dim_card_sk] AS [ga_dim_card_sk]
    ,[s_dim_account_sk]
    ,[card_id]
    ,[account_id]
    ,[card_number_txt]
    ,[card_tier_nm]
    ,[card_status_cd]
    ,[expiry_dt]
    ,[valid_from_dttm]
    ,[valid_to_dttm]
FROM {{ ref('s_dim_card') }}
WHERE [is_current_version_flag] = 1