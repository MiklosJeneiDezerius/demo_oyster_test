CREATE TABLE [snapshots].[snap_dim_customer] (
    [CustomerID]     VARCHAR (8000) NULL,
    [TaxID]          VARCHAR (8000) NULL,
    [CustomerTypeID] VARCHAR (8000) NULL,
    [FirstName]      VARCHAR (8000) NULL,
    [LastName]       VARCHAR (8000) NULL,
    [DoB]            VARCHAR (8000) NULL,
    [AddressLine1]   VARCHAR (8000) NULL,
    [City]           VARCHAR (8000) NULL,
    [StateRegion]    VARCHAR (8000) NULL,
    [PostalCode]     VARCHAR (8000) NULL,
    [Country]        VARCHAR (8000) NULL,
    [IngestedTS]     DATETIME2 (6)  NULL,
    [dbt_scd_id]     VARCHAR (32)   NULL,
    [dbt_updated_at] DATETIME2 (6)  NULL,
    [dbt_valid_from] DATETIME2 (6)  NULL,
    [dbt_valid_to]   DATETIME2 (6)  NULL
);


GO