# Street Assist download tooling

This project provides tooling to allow download of Safety Culture data and its display using Power BI dashboards.

*More about what this actually does / is for*

## Implementation overview

The implementation consists of the following pieces.

- In Azure, there is data storage as follows.

    - An Azure SQL instance to store the data.

    - Something TBD (Azure container instance most likely, with a container registry) to run the downloads.

    - An Azure Key Vault to store credentials.

- In the Power BI service there are Power BI reports and dashboards that allow display and viewing of data.

## Directory structure

The contents of this repository are organised as follows.

- [scripts](scripts) stores scripts

- [templates](templates) contains Azure templates (ARM or BICEP)

- [src](src) contains code

- [docs](docs) contains documentation

- [powerbi](powerbi) contains Power BI files.

## Detailed instructions

*To be provided*