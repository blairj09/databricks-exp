# Databricks Experiments

This repo highlights initial efforts using [Databricks
Connect](https://docs.databricks.com/dev-tools/databricks-connect.html) to
remotely connect to a Databricks cluster and interact with it via `sparklyr`.

## Requirements
- Development version of `sparklyr`: `remotes::install_github("sparklyr/sparklyr")`
- Follow the [Client setup
instructions](https://docs.databricks.com/dev-tools/databricks-connect.html#client-setup)
for Databricks Connect. In my case, I created a `conda` environment and
installed `databricks-connect` with the following after activating the
environment:
```
pip install -U databricks-connect==6.3.1
```
    - Note: There is some messaging when running `databricks-connect` about
    including `spark.databricks.service.server.enabled true` in the Spark conf.
    This isn't necessary in Databricks Runtime > 5.3.

## Connecting
In order to connect, there must be a local installation of Spark that matches
the version of the Databricks Cluster. This can be installed using
`sparklyr::spark_install()`.

The `SPARK_HOME` environment variable must be set to the output of
`databricks-connect get-spark-home`.

Connect using the following:

```r
library(sparklyr)

Sys.setenv(SPARK_HOME="[path returned by databricks-connect get-spark-home]")

sc <- spark_connect(master = "local", method = "databricks")
```

## Setup
This repository uses [`renv`](https://rstudio.github.io/renv/articles/renv.html)
and packages can be restored using `renv::restore()`.

---

#### Known Concerns
These are concerns that may not be actual issues, but are things I have come
across while testing and evaluating Databricks Connect:

- Can't copy local data over, but this may be a known limitation
  - This is fixed starting with `databricks-connect 6.3.1`. See
  https://github.com/sparklyr/sparklyr/pull/2282 for more details.
    
- Can't figure out DBFS, but that may just be me
  - Couldn't read from CSV uploaded to DBFS
- Uploaded data as .csv to DBFS, then used DB GUI to create a table. Then
referenced that table using `tbl()`. Worked like a charm!