CREATE TABLE [oystr_silver].[dim_card] (
    [CardSK]           VARCHAR (64)   NULL,
    [AccountSK]        VARCHAR (64)   NULL,
    [CardID]           VARCHAR (8000) NULL,
    [AccountID]        VARCHAR (8000) NULL,
    [CardNumber]       VARCHAR (8000) NULL,
    [CardTier]         VARCHAR (8000) NULL,
    [CardStatus]       VARCHAR (8000) NULL,
    [ExpiryDate]       DATE           NULL,
    [ValidFromTS]      DATETIME2 (6)  NULL,
    [ValidToTS]        DATETIME2 (6)  NULL,
    [IsCurrentVersion] INT            NOT NULL
);


GO