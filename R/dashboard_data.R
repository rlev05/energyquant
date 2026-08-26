prepare_dashboard_data <- function(
  connection
) {
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

  analytics <- calculate_market_analytics(
    market_observations
  )

  risk_free_observations <- observations |>
    dplyr::filter(
      series_key == "fed_funds"
    )

  risk_summary <- calculate_risk_metrics(
    analytics = analytics,
    risk_free_observations =
      risk_free_observations
  ) |>
    dplyr::left_join(
      market_metadata |>
        dplyr::select(
          series_key,
          display_name
        ),
      by = "series_key"
    )

  list(
    observations = observations,
    market_metadata = market_metadata,
    analytics = analytics,
    risk_summary = risk_summary
  )
}

get_latest_market_snapshot <- function(
  analytics,
  market_metadata
) {
  analytics |>
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
      value,
      unit,
      simple_return,
      rolling_volatility
    )
}