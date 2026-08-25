source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/market_analytics.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

market_metadata <- get_market_series() |>
  dplyr::filter(
    return_eligible
  )

observations <- get_observations(
  connection
) |>
  dplyr::filter(
    series_key %in%
      market_metadata$series_key
  )

analytics <- calculate_market_analytics(
  observations = observations,
  volatility_window = 30
)

risk_summary <- summarise_market_risk(
  analytics
) |>
  dplyr::left_join(
    market_metadata |>
      dplyr::select(
        series_key,
        display_name
      ),
    by = "series_key"
  ) |>
  dplyr::select(
    series_key,
    display_name,
    dplyr::everything()
  )

cat(
  "EnergyQuant market risk summary\n\n"
)

print(
  risk_summary
)

disconnect_database(
  connection
)

