library(plumber)
library(mlflow)
library(httr)

model <- mlflow_load_model(model_uri = "models:/iris_r/2")

#* @apiTitle mlflow model API

#* Modify the request with already parsed data
#* @filter add-data
function(req, res) {
  if (grepl("swagger", tolower(req$PATH_INFO))) return(forward())
  data <- tryCatch(jsonlite::parse_json(req$postBody, simplifyVector = TRUE),
                   error = function(e) NULL)
  if (is.null(data)) {
    res$status <- 400
    return(list(error = "No data submitted"))
  }
  req$data <- data
  forward()
}

#* Return predicted values from R model
#* @post /predict/r
function(req, res) {
  mlflow_predict(model, req$data)
}
