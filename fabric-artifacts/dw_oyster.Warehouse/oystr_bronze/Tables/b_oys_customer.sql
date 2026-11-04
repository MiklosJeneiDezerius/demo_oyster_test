CREATE TABLE [oystr_bronze].[b_oys_customer] (
    [customer_id]      VARCHAR (8000) NULL,
    [tax_id]           VARCHAR (8000) NULL,
    [customer_type_id] VARCHAR (8000) NULL,
    [first_nm]         VARCHAR (8000) NULL,
    [last_nm]          VARCHAR (8000) NULL,
    [birth_dt]         VARCHAR (8000) NULL,
    [ingested_dttm]    DATETIME2 (6)  NULL
);


GO