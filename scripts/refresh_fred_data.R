source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/fred_client.R")
source("R/observations.R")
source("R/observation_store.R")
source("R/data_ingestion.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

observations <- refresh_all_fred_series(
  connection = connection,
  fred_api_key = config$fred_api_key,
  observation_start = "2020-01-01"
)

cat(
  sprintf(
    "Stored %s FRED observations. \n",
    nrow(observations)
  )
)

print(
  observations |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      first_date = min(date),
      latest_date = max(date),
      .groups = "drop"
    )
)

disconnect_database(
  connection
)

