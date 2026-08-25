historical_var <- function(
  returns,
  confidence_level = 0.95
) {
  returns <- returns[
    is.finite(returns)
  ]

  if (length(returns) == 0) {
    return(
      NA_real_
    )
  }

  loss_quantile <- stats::quantile(
    returns,
    probs = 1 - confidence_level,
    names = FALSE,
    na.rm = TRUE
  )

  max(
    0,
    -loss_quantile
  )
}

historical_expected_shortfall <- function(
  returns,
  confidence_level = 0.95
) {
  returns <- returns[
    is.finite(returns)
  ]

  if (length(returns) == 0) {
    return(
      NA_real_
    )
  }

  threshold <- stats::quantile(
    returns,
    probs = 1 - confidence_level,
    names = FALSE,
    na.rm = TRUE
  )

  tail_returns <- returns[
    returns <= threshold
  ]

  if (length(tail_returns) == 0) {
    return(
      NA_real_
    )
  }

  max(
    0,
    -mean(tail_returns)
  )
}

calculate_downside_deviation <- function(
  excess_returns,
  annualisation_factor = 252
) {
  excess_returns <- excess_returns[
    is.finite(excess_returns)
  ]

  if (length(excess_returns) == 0) {
    return(
      NA_real_
    )
  }

  downside_returns <- pmin(
    excess_returns,
    0
  )

  sqrt(
    mean(
      downside_returns^2
    )
  ) * sqrt(
    annualisation_factor
  )
}

calculate_annualised_return <- function(
  returns,
  annualisation_factor = 252
) {
  returns <- returns[
    is.finite(returns)
  ]

  if (length(returns) == 0) {
    return(
      NA_real_
    )
  }

  growth <- prod(
    1 + returns
  )

  if (growth <= 0) {
    return(
      NA_real_
    )
  }

  growth^(
    annualisation_factor /
      length(returns)
  ) - 1
}

prepare_risk_free_returns <- function(
  risk_free_observations
) {
  risk_free_observations |>
    dplyr::transmute(
      date = as.Date(date),

      risk_free_rate = value / 100,

      daily_risk_free_return = (
        1 + risk_free_rate
      )^(1 / 365) - 1
    )
}

calculate_risk_metrics <- function(
  analytics,
  risk_free_observations,
  confidence_level = 0.95,
  annualisation_factor = 252
) {
  required_columns <- c(
    "series_key",
    "date",
    "simple_return",
    "drawdown"
  )

  missing_columns <- setdiff(
    required_columns,
    names(analytics)
  )

  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Risk analytics input is missing required columns: %s",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }

  risk_free_returns <- prepare_risk_free_returns(
    risk_free_observations
  )

  analytics |>
    dplyr::left_join(
      risk_free_returns,
      by = "date"
    ) |>
    dplyr::mutate(
      excess_return = simple_return -
        daily_risk_free_return
    ) |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::summarise(
      observations = sum(
        !is.na(simple_return)
      ),

      annualised_return =
        calculate_annualised_return(
          simple_return,
          annualisation_factor
        ),

      annualised_volatility =
        stats::sd(
          simple_return,
          na.rm = TRUE
        ) * sqrt(
          annualisation_factor
        ),

      downside_deviation =
        calculate_downside_deviation(
          excess_return,
          annualisation_factor
        ),

      value_at_risk =
        historical_var(
          simple_return,
          confidence_level
        ),

      expected_shortfall =
        historical_expected_shortfall(
          simple_return,
          confidence_level
        ),

      maximum_drawdown = min(
        drawdown,
        na.rm = TRUE
      ),

      sharpe_ratio = dplyr::if_else(
        stats::sd(
          excess_return,
          na.rm = TRUE
        ) > 0,

        mean(
          excess_return,
          na.rm = TRUE
        ) /
          stats::sd(
            excess_return,
            na.rm = TRUE
          ) *
          sqrt(
            annualisation_factor
          ),

        NA_real_
      ),

      sortino_ratio = dplyr::if_else(
        calculate_downside_deviation(
          excess_return,
          annualisation_factor
        ) > 0,

        (
          mean(
            excess_return,
            na.rm = TRUE
          ) *
            annualisation_factor
        ) /
          calculate_downside_deviation(
            excess_return,
            annualisation_factor
          ),

        NA_real_
      ),

      calmar_ratio = dplyr::if_else(
        abs(
          min(
            drawdown,
            na.rm = TRUE
          )
        ) > 0,

        calculate_annualised_return(
          simple_return,
          annualisation_factor
        ) /
          abs(
            min(
              drawdown,
              na.rm = TRUE
            )
          ),

        NA_real_
      ),

      .groups = "drop"
    )
}