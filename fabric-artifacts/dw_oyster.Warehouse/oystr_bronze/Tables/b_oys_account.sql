CREATE TABLE [oystr_bronze].[b_oys_account] (
    [account_id]         VARCHAR (8000)  NULL,
    [customer_id]        VARCHAR (8000)  NULL,
    [account_number_txt] VARCHAR (8000)  NULL,
    [account_type_id]    VARCHAR (8000)  NULL,
    [balance_amt]        DECIMAL (18, 4) NULL,
    [currency_id]        VARCHAR (8000)  NULL,
    [ingested_dttm]      DATETIME2 (6)   NULL
);


GO