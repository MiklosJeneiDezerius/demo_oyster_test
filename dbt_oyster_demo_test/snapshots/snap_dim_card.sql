{% snapshot snap_dim_card %}
{{ config(
    target_database=var('target_snapshot_db'),
    target_schema=var('target_snapshot_schema'),
    unique_key='CardID',
    strategy='check',
    check_cols=['CardTierID', 'Status', 'ExpiryDate'],
    invalidate_hard_deletes=True
) }}

SELECT 
    CardID,
    AccountID,
    CardNumber,
    CardTierID,
    Status,
    ExpiryDate
FROM {{ ref('bronze_debitcard') }}
{% endsnapshot %}
