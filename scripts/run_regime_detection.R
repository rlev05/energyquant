source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/market_analytics.R")
source("R/regime_detection.R")

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

regime_results <- detect_market_regimes(
  analytics = analytics,
  lookback = 252,
  minimum_history = 120
)

regime_summary <-
  summarise_market_regimes(
    regime_results
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
      regime,
      dplyr::everything()
    ) |>
    dplyr::arrange(
      series_key,
      regime
    )

current_regime <-
  regime_results |>
    dplyr::filter(
      !is.na(regime)
    ) |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::slice_max(
      order_by = date,
      n = 1,
      with_ties = FALSE
    ) |>
    dplyr::ungroup() |>
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
      date,
      regime,
      rolling_volatility,
      regime_lower_threshold,
      regime_upper_threshold
    )

recent_transitions <-
  find_regime_transitions(
    regime_results
  ) |>
    dplyr::arrange(
      dplyr::desc(
        date
      )
    ) |>
    dplyr::slice_head(
      n = 20
    )

cat(
  "EnergyQuant volatility regime summary \n\n"
)

print(
  regime_summary,
  width = Inf
)

cat(
  "\nMost recent regime transitions\n\n"
)

print(
  recent_transitions,
  width = Inf
)

disconnect_database(
  connection
)