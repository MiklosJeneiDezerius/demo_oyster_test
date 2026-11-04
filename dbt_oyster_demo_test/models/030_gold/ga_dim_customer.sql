{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT
    [s_dim_customer_sk] AS [ga_dim_customer_sk]
    ,[customer_id]
    ,[first_nm]
    ,[last_nm]
    ,[full_nm]
    ,[tax_id] -- Automatically masked at the Warehouse layer via your DDM policy
    ,[customer_type_nm]
    ,[birth_dt]
    ,[address_line_1_txt]
    ,[city_nm]
    ,[state_region_nm]
    ,[postal_cd]
    ,[country_nm]
    ,[valid_from_dttm]
    ,[valid_to_dttm]
FROM {{ ref('s_dim_customer') }}
WHERE [is_current_version_flag] = 1 -- Filters down to the single active operational truth