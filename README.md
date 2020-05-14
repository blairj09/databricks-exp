# Databricks Experiments

This repo highlights initial efforts using [Databricks
Connect](https://docs.databricks.com/dev-tools/databricks-connect.html) to
remotely connect to a Databricks cluster and interact with it via `sparklyr`.

## Requirements
- Development version of `sparklyr`: `remotes::install_github("sparklyr/sparklyr")`
- Follow the [Client setup
instructions](https://docs.databricks.com/dev-tools/databricks-connect.html#client-setup)
for Databricks Connect. 
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
and packages can be restored using `renv::restore()`. Note, there have been no
efforts made to create light dependencies. Therefore, there are several packages
used by this project.

## Test Environment
General description of the environment used for testing and proving Databricks +
RStudio

* Use `sol-eng-terraform` and RST standalone
* Install `databricks-connect` using `/opt/python/` system installation
* Run `databricks-connect configure` (needs to be run per user)
* Install RStudio Pro Drivers
* Install Databricks Spark Driver
