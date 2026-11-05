CREATE TABLE [oystr_dq].[not_null_b_oys_debit_card_card_id] (
    [card_id]         VARCHAR (8000) NULL,
    [account_id]      VARCHAR (8000) NULL,
    [card_number_txt] VARCHAR (8000) NULL,
    [card_tier_id]    VARCHAR (8000) NULL,
    [card_status_cd]  VARCHAR (8000) NULL,
    [expiry_dt]       VARCHAR (8000) NULL,
    [ingested_dttm]   DATETIME2 (6)  NULL
);


GO