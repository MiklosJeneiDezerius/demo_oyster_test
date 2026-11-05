CREATE TABLE [oystr_bronze].[b_oys_transaction] (
    [transaction_id]        VARCHAR (8000)  NULL,
    [account_id]            VARCHAR (8000)  NULL,
    [transaction_amt]       DECIMAL (18, 4) NULL,
    [transaction_dttm]      DATETIME2 (6)   NULL,
    [counterparty_nm]       VARCHAR (8000)  NULL,
    [transaction_status_id] VARCHAR (8000)  NULL,
    [ingested_dttm]         DATETIME2 (6)   NULL
);


GO