library(sparklyr)

spark_home <- system("databricks-connect get-spark-home", intern = TRUE)

sc <- spark_connect(method = "databricks", 
                    spark_home = spark_home)

cars_tbl <- copy_to(sc, mtcars, overwrite = TRUE)

cars_tbl

spark_disconnect(sc)
