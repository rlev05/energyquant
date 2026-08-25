source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/data_quality.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

observations <- get_observations(
  connection
)

expected_series <- get_market_series()

quality_summary <- summarise_data_quality(
  observations = observations,
  expected_series = expected_series
)

duplicates <- find_duplicate_observations(
  observations |>
    dplyr::filter(
      series_key %in% expected_series$series_key
    )
)

invalid_observations <- find_invalid_observations(
  observations |>
    dplyr::filter(
      series_key %in% expected_series$series_key
    )
)

cat(
  "EnergyQuant data quality report\n\n"
)

print(
  quality_summary
)

cat(
  sprintf(
    "\nDuplicate observations: %s\n",
    nrow(duplicates)
  )
)

cat(
  sprintf(
    "Invalid observations: %s\n",
    nrow(invalid_observations)
  )
)

if (data_quality_passed(quality_summary)) {
  cat(
    "\nOverall status: PASS\n"
  )
} else {
  cat(
    "\nOverall status: FAIL\n"
  )

  disconnect_database(
    connection
  )

  quit(
    status = 1
  )
}

disconnect_database(
  connection
)