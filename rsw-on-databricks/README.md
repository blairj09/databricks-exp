# RSW on Databricks

## Setup
Initial instructions are provided by Databricks here: https://docs.databricks.com/spark/latest/sparkr/rstudio.html

These instuctions suggest using a floating license server with RSW. In this case, we'll use a license file. Databricks uses the construct of an "init script" to manage the installation of additional tools (like RSW) into a Databricks cluster. The init script used is mainted in this repository as [`rstudio-init.sh`](rstudio-init.sh). This file is modified from the [example](https://docs.databricks.com/spark/latest/sparkr/rstudio.html#install-rstudio-workbench) provided by Databricks.

RStudio License File is stored as a [secret](https://docs.databricks.com/security/secrets/secrets.html) within Databricks and referenced via [environment variable](https://docs.databricks.com/security/secrets/secrets.html#reference-a-secret-in-an-environment-variable) from the init script. These environment variables are set via the `databricks secrets` CLI.

The following example illustrates an attempt at using environment variables to insert the license file as appropriate within a cluster init script. So far, these attempts have been unsuccessful.

```
  # echo """
  # [DEFAULT]
  # host = https://dbc-4dce3c75-6c98.cloud.databricks.com
  # token = ${TOKEN}
  # jobs-api-version = 2.0
  # """ >> ~/.databrickscfg
  # sudo echo ${RSW_LICENSE_FILE} >> /etc/rstudio/rsw.lic
  # sudo cat dbfs:/rstudio-license-files/rsw.lic
  # /databricks/python3/bin/dbfs cp dbfs:/rstudio-license-files/rsw.lic .
  # sudo cp ./rsw.lic /opt/rstudio
```

One thing that has worked is to just bake the RSW license into the init script:

```
  sudo echo """
-----BEGIN RSTUDIO LICENSE-----
********************************
********************************
********************************
-----END RSTUDIO LICENSE-----
""" >> /etc/rstudio/rsw.lic
```