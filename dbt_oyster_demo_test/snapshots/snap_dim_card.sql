{% snapshot snap_dim_card %}

{{ config(
    target_database='dw_oysterlake',
    target_schema='snapshots',
    unique_key='CardID',
    strategy='check',
    check_cols=['Tier', 'Status', 'Expiry'],
    invalidate_hard_deletes=True
) }}

SELECT 
    CardID, 
    AccountID, 
    CardNumber, 
    Tier, 
    Status, 
    Expiry 
FROM {{ ref('bronze_debitcard') }}

{% endsnapshot %}
