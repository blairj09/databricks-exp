# Package pre-reqs on the driver
install.packages('mlflow')
install.packages('carrier')
library(mlflow)
library(glmnet)
library(carrier)
# install_mlflow()

# Define search/tuning space 
tuning_grid <- expand.grid(data.frame(alpha = seq(0.01, 1, by = 0.05),
                                      lambda = seq(0.10, 1, by = 0.1)))
# Add a unique id to group by 
tuning_grid$id <- 1:nrow(tuning_grid)

# Push to Spark
tuning_sdf <- sdf_copy_to(sc, tuning_grid, overwrite = TRUE)

# Apply a function to each group of hyperparams that:
# 1. Communicates with the MLflow tracking server
# 2. Reads training data in from DBFS
# 3. Trains a model with the hyperparams, logging everything to MLflow
hyperoptr <- spark_apply(tuning_sdf,
                         group_by = "id",
                         function(x) {
                           
                           # Load packages on workers
                           library(mlflow)
                           library(glmnet)
                           library(carrier)
                           
                           # Configure MLflow to communicate with Databricks-hosted tracking server
                           Sys.setenv(MLFLOW_BIN = '/databricks/python/bin/mlflow')
                           Sys.setenv(MLFLOW_PYTHON_BIN = '/databricks/python/bin/python')
                           Sys.setenv(DATABRICKS_HOST = "<>")
                           Sys.setenv(DATABRICKS_TOKEN = "<>")
                           mlflow_set_tracking_uri("databricks")
                           
                           # Assign hyperparams
                           alpha <- as.numeric(x$alpha)
                           lambda <- as.numeric(x$lambda)
                           id <- as.numeric(x$id)
                           
                           train_wine_quality <- function(data, alpha, lambda) {
                             
                             # Split the data into training and test sets. (0.75, 0.25) split.
                             sampled <- base::sample(1:nrow(data), 0.75 * nrow(data))
                             train <- data[sampled, ]
                             test <- data[-sampled, ]
                             
                             # The predicted column is "quality" which is a scalar from [3, 9]
                             train_x <- as.matrix(train[, !(names(train) == "quality")])
                             test_x <- as.matrix(test[, !(names(train) == "quality")])
                             train_y <- train[, "quality"]
                             test_y <- test[, "quality"]
                             
                             with(mlflow_start_run(experiment_id = 1387691099326042), {
                               model <- glmnet(train_x, train_y, alpha = alpha, lambda = lambda, family= "gaussian", standardize = FALSE)
                               l1se <- cv.glmnet(train_x, train_y, alpha = alpha)$lambda.1se
                               predictor <- crate(~ glmnet::predict.glmnet(!!model, as.matrix(.x)), !!model, s = l1se)
                               
                               predicted <- predictor(test_x)
                               
                               rmse <<- sqrt(mean((predicted - test_y) ^ 2))
                               mae <<- mean(abs(predicted - test_y))
                               r2 <<- as.numeric(cor(predicted, test_y) ^ 2)

                               message("Elasticnet model (alpha=", alpha, ", lambda=", lambda, "):")
                               message("  RMSE: ", rmse)
                               message("  MAE: ", mae)
                               message("  R2: ", mean(r2, na.rm = TRUE))
                               
                               ## Log the parameters associated with this run
                               mlflow_log_param("alpha", alpha)
                               mlflow_log_param("lambda", lambda)
                               
                               ## Log metrics we define from this run
                               mlflow_log_metric("rmse", rmse)
                               mlflow_log_metric("r2", mean(r2, na.rm = TRUE))
                               mlflow_log_metric("mae", mae)
                               
                               # Save plot to disk
                               png(filename = "ElasticNet-CrossValidation.png")
                               plot(cv.glmnet(train_x, train_y, alpha = alpha))
                               dev.off()
                               
                               ## Log that plot as an artifact
                               mlflow_log_artifact("ElasticNet-CrossValidation.png")
                               
                               mlflow_log_model(predictor, "model")
                               
                             })
                           }
                           
                           wine_quality <- read.csv("/dbfs/rk/data/wine-quality.csv", 
                                                    stringsAsFactors = F)
                           
                           train_wine_quality(data = wine_quality,
                                              alpha = alpha,
                                              lambda = lambda,
                                              rmse = rmse,
                                              r2 = r2,
                                              mae = mae)
                           
                          data.frame(alpha, lambda, id)
                         })

# Force execution on each group of params
hyperoptr %>% collect()