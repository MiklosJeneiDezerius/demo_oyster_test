CREATE TABLE [oystr_gold].[gold_dim_customer] (
    [CustomerSK]   VARCHAR (64)   NULL,
    [CustomerID]   VARCHAR (8000) NULL,
    [FirstName]    VARCHAR (8000) NULL,
    [LastName]     VARCHAR (8000) NULL,
    [FullName]     VARCHAR (8000) NULL,
    [TaxID]        VARCHAR (8000) NULL,
    [CustomerType] VARCHAR (8000) NULL,
    [BirthDate]    DATE           NULL,
    [AddressLine1] VARCHAR (8000) NULL,
    [City]         VARCHAR (8000) NULL,
    [StateRegion]  VARCHAR (8000) NULL,
    [PostalCode]   VARCHAR (8000) NULL,
    [Country]      VARCHAR (8000) NULL,
    [ValidFromTS]  DATETIME2 (6)  NULL,
    [ValidToTS]    DATETIME2 (6)  NULL
);


GO