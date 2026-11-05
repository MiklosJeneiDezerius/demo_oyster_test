{% snapshot ldh_oys_debitcard %}
{{ config(
    target_database=var('target_snapshot_db'),
    target_schema=var('target_snapshot_schema'),
    unique_key='CardID',
    strategy='check',
    check_cols=['CardTierID', 'Status', 'ExpiryDate'],
    hard_deletes='invalidate',
    snapshot_meta_column_names={
        'dbt_valid_from': 'm_valid_from_dttm',
        'dbt_valid_to': 'm_valid_to_dttm',
        'dbt_scd_id': 'm_scd_id',
        'dbt_updated_at': 'm_update_at_dttm'
    },
    dbt_valid_to_current="CAST('9999-12-31 00:00:00' AS DATETIME2(6))"
) }}

-- Fabric Warehouse locks whole tables; serialize snapshots to avoid concurrent-write deadlocks.
-- depends_on: {{ ref('ldh_oys_customer') }}

SELECT 
    card_id AS CardID,
    account_id AS AccountID,
    card_number_txt AS CardNumber,
    card_tier_id AS CardTierID,
    card_status_cd AS Status,
    expiry_dt AS ExpiryDate
FROM {{ ref('b_oys_debit_card') }}
{% endsnapshot %}
