# Street Assist download tooling

This project provides tooling to allow download of Safety Culture data and its display using Power BI dashboards, to allow Street Assist to view up to date data in their Power BI dashboards.

## Directory structure

The contents of this repository are organised as follows.

- [docs](docs) contains documentation.

- [config](config) contains config files, largely with names of resources in particular deployments. (There is one live deployment, and potentially one or more test deployments during development.)

- [scripts](scripts) stores scripts used for deployment purposes.

- [templates](templates) contains Azure templates (BICEP).

- [docker](docker) contains the Azure Container App Job code, including scripts that are run during its nightly runs, the Safety Culture CLI exporter, and SQL table and view definitions.

## Documentation

- To understand the design, read the [architecture document](docs/architecture.md).

- To deploy a new instance of the tooling, read the [deployment documentation](docs/deploy.md).

- For detailed information about database tables, read the [data design](docs/data.md). **This data documentation is a work in progress.**

