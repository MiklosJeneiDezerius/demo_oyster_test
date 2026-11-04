CREATE TABLE [snapshots].[ldh_oys_debitcard] (
    [CardID]            VARCHAR (8000) NULL,
    [AccountID]         VARCHAR (8000) NULL,
    [CardNumber]        VARCHAR (8000) NULL,
    [CardTierID]        VARCHAR (8000) NULL,
    [Status]            VARCHAR (8000) NULL,
    [ExpiryDate]        VARCHAR (8000) NULL,
    [m_scd_id]          VARCHAR (32)   NULL,
    [m_update_at_dttm]  DATETIME2 (6)  NULL,
    [m_valid_from_dttm] DATETIME2 (6)  NULL,
    [m_valid_to_dttm]   DATETIME2 (6)  NULL
);


GO