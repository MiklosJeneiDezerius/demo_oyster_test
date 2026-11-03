SELECT
    TRY_CONVERT(INT, [CustomerID]) AS [CustomerID],
    TRIM([FirstName]) AS [FirstName],
    TRIM([LastName]) AS [LastName],
    CAST(GETDATE() AS DATETIME2(6)) AS [IngestedTS]
FROM {{ source('landing_delta_core', 'customer') }}