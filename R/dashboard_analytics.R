prepare_correlation_dashboard <- function(
  analytics
) {
  calculate_correlation_matrix(
    analytics
  )
}

prepare_anomaly_dashboard <- function(
  analytics
) {
  anomaly_results <- detect_market_anomalies(
    analytics = analytics,
    window = 60,
    minimum_observations = 30,
    z_threshold = 3
  )

  list(
    results = anomaly_results,
    summary = summarise_market_anomalies(
      anomaly_results
    )
  )
}

prepare_regime_dashboard <- function(
  analytics
) {
  regime_results <- detect_market_regimes(
    analytics = analytics,
    lookback = 252,
    minimum_history = 120
  )

  current_regimes <- regime_results |>
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
    dplyr::ungroup()

  transitions <- find_regime_transitions(
    regime_results
  )

  list(
    results = regime_results,
    current = current_regimes,
    transitions = transitions
  )
}