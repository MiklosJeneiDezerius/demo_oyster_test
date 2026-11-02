CREATE TABLE [oystr_bronze].[bronze_customeraddress] (
    [AddressID]    VARCHAR (8000) NULL,
    [CustomerID]   VARCHAR (8000) NULL,
    [AddressLine1] VARCHAR (8000) NULL,
    [City]         VARCHAR (8000) NULL,
    [StateRegion]  VARCHAR (8000) NULL,
    [PostalCode]   VARCHAR (8000) NULL,
    [Country]      VARCHAR (8000) NULL,
    [IngestedTS]   DATETIME2 (6)  NULL
);


GO