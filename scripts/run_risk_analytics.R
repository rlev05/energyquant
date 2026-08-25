source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/market_analytics.R")
source("R/risk_analytics.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

observations <- get_observations(
  connection
)

market_metadata <- get_market_series() |>
  dplyr::filter(
    return_eligible
  )

market_observations <- observations |>
  dplyr::filter(
    series_key %in%
      market_metadata$series_key
  )

risk_free_observations <- observations |>
  dplyr::filter(
    series_key == "fed_funds"
  )

analytics <- calculate_market_analytics(
  market_observations
)

risk_summary <- calculate_risk_metrics(
  analytics = analytics,
  risk_free_observations =
    risk_free_observations,
  confidence_level = 0.95
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
  "EnergyQuant market risk analytics\n\n"
)

print(
  risk_summary,
  width = Inf
)

disconnect_database(
  connection
)