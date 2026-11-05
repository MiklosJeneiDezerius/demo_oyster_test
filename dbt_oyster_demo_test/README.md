Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test

### Fabric connection

The `server` in [profiles.yml](profiles.yml) must match the SQL connection
string shown in the target Fabric Warehouse settings. The default database is
`dw_oyster`; `DBT_DATABASE` and `DBT_TARGET` can override the database and target.
Local runs use Azure CLI authentication.

Validate the connection before building:

```shell
dbt debug --profiles-dir .
```

The Fabric runner notebook clones the configured GitHub branch and creates a
runtime token-credential profile from this file. Local profile changes must be
committed and pushed to that branch before a notebook run can use them.


### Repeatable demo snapshot

The gold spend snapshot returns only `demo_snapshot_date` (default:
`2026-09-15`), after calculating the inclusive 30-day window ending on that
date. With the generator's September 2026 data, this includes all generated
transactions. The output columns and tier thresholds are unchanged.
`snapshot_materialized_dttm` still records the actual build time.

```shell
dbt build --select g_fct_periodic_spend_snapshot --profiles-dir .
```

Override the reference date when needed:

```shell
dbt build --select g_fct_periodic_spend_snapshot --profiles-dir . --vars '{"demo_snapshot_date": "2026-09-15"}'
```

Business results are repeatable with unchanged upstream data and dimension
history; a fixed date does not freeze changes to those inputs. Refresh the
semantic model after rebuilding. The Fabric runner must clone a branch
containing these changes before it can use the new behavior.

### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
