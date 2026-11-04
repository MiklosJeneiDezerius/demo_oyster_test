CREATE TABLE [oystr_bronze].[b_oys_debit_card] (
    [card_id] VARCHAR (8000) NULL,
    [account_id] VARCHAR (8000) NULL,
    [card_number_txt] VARCHAR (8000) NULL,
    [card_tier_id] VARCHAR (8000) NULL,
    [card_status_cd] VARCHAR (8000) NULL,
    [expiry_dt] VARCHAR (8000) NULL,
    [ingested_dttm] DATETIME2 (6) NULL
);


GO