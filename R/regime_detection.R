validate_regime_input <- function(analytics) {
  required_columns <- c(
    "series_key",
    "date",
    "simple_return",
    "rolling_volatility"
  )

  missing_columns <- setdiff(
    required_columns,
    names(analytics)
  )

  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Regime input is missing required columns: %s",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }

  invisible(TRUE)
}

calculate_regime_thresholds <- function(
  volatility,
  lookback = 252,
  minimum_history = 120,
  lower_probability = 0.33,
  upper_probability = 0.67
) {
  if (lookback < 2) {
    stop(
      "Regime lookback must be at least 2."
    )
  }

  if (minimum_history < 2) {
    stop(
      "Minimum regime history must be at least 2."
    )
  }

  if (minimum_history > lookback) {
    stop(
      "Minimum regime history cannot exceed the lookback window."
    )
  }

  if (
    lower_probability <= 0 ||
      upper_probability >= 1 ||
      lower_probability >= upper_probability
  ) {
    stop(
      "Regime probabilities must satisfy 0 < lower < upper < 1."
    )
  }

  lower_threshold <- rep(
    NA_real_,
    length(volatility)
  )

  upper_threshold <- rep(
    NA_real_,
    length(volatility)
  )

  regime <- rep(
    NA_character_,
    length(volatility)
  )

  for (index in seq_along(volatility)) {
    if (
      index == 1 ||
        !is.finite(volatility[[index]])
    ) {
      next
    }

    history_start <- max(
      1,
      index - lookback
    )

    history <- volatility[
      history_start:(index - 1)
    ]

    history <- history[
      is.finite(history)
    ]

    if (
      length(history) <
        minimum_history
    ) {
      next
    }

    lower <- stats::quantile(
      history,
      probs = lower_probability,
      names = FALSE,
      na.rm = TRUE
    )

    upper <- stats::quantile(
      history,
      probs = upper_probability,
      names = FALSE,
      na.rm = TRUE
    )

    lower_threshold[[index]] <- lower
    upper_threshold[[index]] <- upper

    regime[[index]] <- dplyr::case_when(
      volatility[[index]] < lower ~ "low",
      volatility[[index]] > upper ~ "high",
      TRUE ~ "normal"
    )
  }

  tibble::tibble(
    regime_lower_threshold =
      lower_threshold,

    regime_upper_threshold =
      upper_threshold,

    regime = regime
  )
}

detect_market_regimes <- function(
  analytics,
  lookback = 252,
  minimum_history = 120,
  lower_probability = 0.33,
  upper_probability = 0.67
) {
  validate_regime_input(
    analytics
  )

  analytics |>
    dplyr::arrange(
      series_key,
      date
    ) |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::group_modify(
      function(data, key) {
        thresholds <-
          calculate_regime_thresholds(
            volatility =
              data$rolling_volatility,
            lookback = lookback,
            minimum_history =
              minimum_history,
            lower_probability =
              lower_probability,
            upper_probability =
              upper_probability
          )

        dplyr::bind_cols(
          data,
          thresholds
        ) |>
          dplyr::mutate(
            previous_regime =
              dplyr::lag(regime),

            regime_change =
              !is.na(regime) &
                !is.na(previous_regime) &
                regime != previous_regime
          )
      }
    ) |>
    dplyr::ungroup()
}

summarise_market_regimes <- function(
  regime_results,
  annualisation_factor = 252
) {
  regime_results |>
    dplyr::filter(
      !is.na(regime)
    ) |>
    dplyr::group_by(
      series_key,
      regime
    ) |>
    dplyr::summarise(
      observations = dplyr::n(),

      average_return = mean(
        simple_return,
        na.rm = TRUE
      ),

      annualised_return =
        mean(
          simple_return,
          na.rm = TRUE
        ) *
          annualisation_factor,

      annualised_volatility =
        stats::sd(
          simple_return,
          na.rm = TRUE
        ) *
          sqrt(
            annualisation_factor
          ),

      first_date = min(
        date
      ),

      latest_date = max(
        date
      ),

      .groups = "drop"
    ) |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::mutate(
      regime_share =
        observations /
          sum(observations)
    ) |>
    dplyr::ungroup()
}

find_regime_transitions <- function(
  regime_results
) {
  regime_results |>
    dplyr::filter(
      regime_change
    ) |>
    dplyr::select(
      series_key,
      date,
      previous_regime,
      regime,
      rolling_volatility,
      regime_lower_threshold,
      regime_upper_threshold
    )
}