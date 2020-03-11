library(sparklyr)

sc <- spark_connect(master = "local", 
                    method = "databricks", 
                    spark_home = "/Users/jamesblair/anaconda3/envs/databricks/lib/python3.7/site-packages/pyspark")

cars_tbl <- copy_to(sc, mtcars, overwrite = TRUE)

cars_tbl

spark_disconnect(sc)
