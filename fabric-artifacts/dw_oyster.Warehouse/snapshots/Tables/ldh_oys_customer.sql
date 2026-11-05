CREATE TABLE [snapshots].[ldh_oys_customer] (
    [CustomerID]        VARCHAR (8000) NULL,
    [TaxID]             VARCHAR (8000) NULL,
    [CustomerTypeID]    VARCHAR (8000) NULL,
    [FirstName]         VARCHAR (8000) NULL,
    [LastName]          VARCHAR (8000) NULL,
    [DoB]               VARCHAR (8000) NULL,
    [AddressLine1]      VARCHAR (8000) NULL,
    [City]              VARCHAR (8000) NULL,
    [StateRegion]       VARCHAR (8000) NULL,
    [PostalCode]        VARCHAR (8000) NULL,
    [Country]           VARCHAR (8000) NULL,
    [IngestedTS]        DATETIME2 (6)  NULL,
    [m_scd_id]          VARCHAR (32)   NULL,
    [m_update_at_dttm]  DATETIME2 (6)  NULL,
    [m_valid_from_dttm] DATETIME2 (6)  NULL,
    [m_valid_to_dttm]   DATETIME2 (6)  NULL
);


GO