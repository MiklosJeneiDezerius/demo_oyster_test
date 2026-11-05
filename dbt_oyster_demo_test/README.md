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


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
