source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/market_analytics.R")
source("R/correlation_analytics.R")

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
  observations
)

correlation_matrix <- calculate_correlation_matrix(
  analytics
)

cat(
  "EnergyQuant full-period return correlations\n\n"
)

print(
  round(
    correlation_matrix,
    3
  )
)

pairs <- list(
  c(
    "brent",
    "wti"
  ),
  c(
    "brent",
    "sp500"
  ),
  c(
    "brent",
    "usd_index"
  ),
  c(
    "natural_gas",
    "brent"
  ),
  c(
    "sp500",
    "usd_index"
  )
)

rolling_summaries <- lapply(
  pairs,
  function(pair) {
    pair_results <-
      calculate_rolling_correlation(
        analytics = analytics,
        first_series = pair[[1]],
        second_series = pair[[2]],
        window = 60
      )

    summarise_rolling_correlation(
      results = pair_results
    )
  }
)

rolling_summary <- dplyr::bind_rows(
  rolling_summaries
)

cat(
  "\n60-observation rolling correlation summary\n\n"
)

print(
  rolling_summary,
  width = Inf
)

disconnect_database(
  connection
)