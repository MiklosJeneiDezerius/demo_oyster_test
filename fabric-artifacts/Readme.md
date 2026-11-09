This is the full-demo Fabric artifact tree.

The primary deterministic generator remains CSV-based. The optional
`Oyster_Json_Transaction_Generator` writes the same full ledger fields as nested
JSON; `nb_json_load_source_to_ld` uses `explode(flatten(...))` to write the
`ld_oys_transaction_ledger` Delta table. These JSON notebooks are not wired into
`pl_Landing_Delta`; its existing route remains CSV-based.