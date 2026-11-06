SELECT
    CAST([CustomerID] AS INT) AS [customer_id],
    TRIM([FirstName]) AS [first_nm],
    TRIM([LastName]) AS [last_nm],
    CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta_core', 'customer') }}