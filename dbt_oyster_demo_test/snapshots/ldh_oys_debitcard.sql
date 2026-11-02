{% snapshot ldh_oys_debitcard %}
{{ config(
    target_database=var('target_snapshot_db'),
    target_schema=var('target_snapshot_schema'),
    unique_key='CardID',
    strategy='check',
    check_cols=['CardTierID', 'Status', 'ExpiryDate'],
    hard_deletes='invalidate'
) }}

SELECT 
    CardID,
    AccountID,
    CardNumber,
    CardTierID,
    Status,
    ExpiryDate
FROM {{ ref('b_oys_debit_card') }}
{% endsnapshot %}
