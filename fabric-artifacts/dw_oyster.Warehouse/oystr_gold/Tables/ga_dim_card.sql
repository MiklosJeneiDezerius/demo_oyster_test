CREATE TABLE [oystr_gold].[ga_dim_card] (
    [ga_dim_card_sk]   VARCHAR (64)   NULL,
    [s_dim_account_sk] VARCHAR (64)   NULL,
    [card_id]          VARCHAR (8000) NULL,
    [account_id]       VARCHAR (8000) NULL,
    [card_number_txt]  VARCHAR (8000) NULL,
    [card_tier_nm]     VARCHAR (8000) NULL,
    [card_status_cd]   VARCHAR (8000) NULL,
    [expiry_dt]        DATE           NULL,
    [valid_from_dttm]  DATETIME2 (6)  NULL,
    [valid_to_dttm]    DATETIME2 (6)  NULL
);


GO