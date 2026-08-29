source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/fred_client.R")
source("R/eia_client.R")
source("R/observations.R")
source("R/observation_store.R")
source("R/data_ingestion.R")
source("R/data_quality.R")
source("R/incremental_refresh.R")

main <- function() {
  config <- load_config()

  connection <- connect_database(
    config$database_path
  )

  on.exit(
    disconnect_database(
      connection
    ),
    add = TRUE
  )

  cat(
    "EnergyQuant incremental market refresh\n\n"
  )

  refresh_summary <-
    refresh_market_series_incrementally(
      connection = connection,
      fred_api_key =
        config$fred_api_key,
      eia_api_key =
        config$eia_api_key,
      default_start =
        as.Date("2020-01-01"),
      revision_buffer_days = 7
    )

  cat(
    "\nRefresh summary\n\n"
  )

  print(
    refresh_summary,
    width = Inf
  )

  observations <- get_observations(
    connection
  )

  quality_summary <-
    summarise_data_quality(
      observations = observations,
      expected_series =
        get_market_series()
    )

  cat(
    "\nPost-refresh data quality\n\n"
  )

  print(
    quality_summary,
    width = Inf
  )

  if (
    !data_quality_passed(
      quality_summary
    )
  ) {
    stop(
      "Post-refresh data quality checks failed."
    )
  }

  cat(
    "\nIncremental refresh completed successfully.\n"
  )
}

main()