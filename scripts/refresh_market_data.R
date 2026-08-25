source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/fred_client.R")
source("R/eia_client.R")
source("R/observations.R")
source("R/observation_store.R")
source("R/data_ingestion.R")


config <- load_config()

connection <- connect_database(
  config$database_path
)

observations <- refresh_all_market_series(
  connection = connection,
  fred_api_key = config$fred_api_key,
  eia_api_key = config$eia_api_key,
  observation_start = "2020-01-01"
)

summary <- observations |>
  dplyr::group_by(
    source,
    series_key
  ) |>
  dplyr::summarise(
    observations = dplyr::n(),
    first_date = min(date),
    latest_date = max(date),
    .groups = "drop"
  )

cat(
  sprintf(
    "Processed %s market observations. \n\n",
    nrow(observations)
  )
)

print(
  summary
)

disconnect_database(
  connection
)



