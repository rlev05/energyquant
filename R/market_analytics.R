validate_analytics_input <- function(observations) {
  required_columns <- c(
    "series_key",
    "date",
    "value"
  )

  missing_columns <- setdiff(
    required_columns,
    names(observations)
  )

  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Analytics input is missing required columns: %s",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }

  invisible(TRUE)
}

rolling_standard_deviation <- function(
  values,
  window
) {
  if (window < 2) {
    stop(
      "Rolling window must be at least 2."
    )
  }

  result <- rep(
    NA_real_,
    length(values)
  )

  for (index in seq_along(values)) {
    start_index <- index - window + 1

    if (start_index < 1) {
      next
    }

    window_values <- values[
      start_index:index
    ]

    if (sum(!is.na(window_values)) == window) {
      result[[index]] <- stats::sd(
        window_values
      )
    }
  }

  result
}

calculate_market_analytics <- function(
  observations,
  volatility_window = 30,
  annualisation_factor = 252
) {
  validate_analytics_input(
    observations
  )

  observations |>
    dplyr::arrange(
      series_key,
      date
    ) |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::mutate(
      previous_value = dplyr::lag(
        value
      ),

      simple_return = (
        value / previous_value
      ) - 1,

      log_return = dplyr::if_else(
        value > 0 &
          previous_value > 0,
        log(
          value / previous_value
        ),
        NA_real_
      ),

      cumulative_return = cumprod(
        1 + dplyr::coalesce(
          simple_return,
          0
        )
      ) - 1,

      rolling_volatility = rolling_standard_deviation(
        simple_return,
        volatility_window
      ) * sqrt(
        annualisation_factor
      ),

      running_peak = cummax(
        value
      ),

      drawdown = (
        value / running_peak
      ) - 1
    ) |>
    dplyr::ungroup()
}

summarise_market_risk <- function(
  analytics,
  annualisation_factor = 252
) {
  validate_analytics_input(
    analytics
  )

  required_columns <- c(
    "simple_return",
    "cumulative_return",
    "rolling_volatility",
    "drawdown"
  )

  missing_columns <- setdiff(
    required_columns,
    names(analytics)
  )

  if (length(missing_columns) > 0) {
    stop(
      "Run calculate_market_analytics() before summarising market risk."
    )
  }

  analytics |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::summarise(
      first_date = min(date),
      latest_date = max(date),

      latest_value = value[
        which.max(date)
      ],

      observations = sum(
        !is.na(simple_return)
      ),

      cumulative_return = dplyr::last(
        cumulative_return
      ),

      annualised_volatility = stats::sd(
        simple_return,
        na.rm = TRUE
      ) * sqrt(
        annualisation_factor
      ),

      maximum_drawdown = min(
        drawdown,
        na.rm = TRUE
      ),

      latest_rolling_volatility = dplyr::last(
        rolling_volatility[
          !is.na(rolling_volatility)
        ]
      ),

      .groups = "drop"
    )
}