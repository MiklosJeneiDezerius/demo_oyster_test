SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(c.[customer_id] AS VARCHAR(50))), 2) AS [s_dim_customer_sk],
    c.[customer_id],
    c.[first_nm],
    c.[last_nm],
    CONCAT(c.[first_nm], ' ', c.[last_nm]) AS [full_nm]
FROM {{ ref('b_oys_customer') }} c