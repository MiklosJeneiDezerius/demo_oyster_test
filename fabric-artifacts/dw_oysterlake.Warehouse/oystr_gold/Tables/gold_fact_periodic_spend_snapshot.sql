CREATE TABLE [oystr_gold].[gold_fact_periodic_spend_snapshot] (
    [SpendSnapshotSK]          VARCHAR (64)    NULL,
    [DateSK]                   INT             NULL,
    [SnapshotDate]             DATE            NULL,
    [AccountSK]                VARCHAR (64)    NULL,
    [AccountID]                VARCHAR (8000)  NULL,
    [CustomerSK]               VARCHAR (64)    NULL,
    [CardSK]                   VARCHAR (64)    NULL,
    [ActualCardTier]           VARCHAR (8000)  NULL,
    [Rolling30DaySpend]        DECIMAL (38, 4) NULL,
    [CalculatedSpendingTier]   VARCHAR (8)     NOT NULL,
    [IsUpgradeCandidate]       INT             NOT NULL,
    [IsLowSpendPremiumAnomaly] INT             NOT NULL,
    [AlignmentStatusFlag]      VARCHAR (10)    NOT NULL,
    [SnapshotMaterializedTS]   DATETIME2 (6)   NULL
);


GO