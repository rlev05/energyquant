validate_anomaly_input <- function(analytics) {
  required_columns <- c(
    "series_key",
    "date",
    "simple_return"
  )

  missing_columns <- setdiff(
    required_columns,
    names(analytics)
  )

  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Anomaly input is missing required columns: %s",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }

  invisible(TRUE)
}

calculate_rolling_z_score <- function(
  returns,
  window = 60,
  minimum_observations = 30
) {
  if (window < 2) {
    stop(
      "Anomaly window must be at least 2."
    )
  }

  if (minimum_observations < 2) {
    stop(
      "Minimum observations must be at least 2."
    )
  }

  if (minimum_observations > window) {
    stop(
      "Minimum observations cannot exceed the rolling window."
    )
  }

  result <- rep(
    NA_real_,
    length(returns)
  )

  for (index in seq_along(returns)) {
    if (
      index == 1 ||
        !is.finite(returns[[index]])
    ) {
      next
    }

    history_start <- max(
      1,
      index - window
    )

    history <- returns[
      history_start:(index - 1)
    ]

    history <- history[
      is.finite(history)
    ]

    if (
      length(history) <
        minimum_observations
    ) {
      next
    }

    history_mean <- mean(
      history
    )

    history_sd <- stats::sd(
      history
    )

    if (
      !is.finite(history_sd) ||
        history_sd == 0
    ) {
      next
    }

    result[[index]] <- (
      returns[[index]] -
        history_mean
    ) / history_sd
  }

  result
}

detect_market_anomalies <- function(
  analytics,
  window = 60,
  minimum_observations = 30,
  z_threshold = 3
) {
  validate_anomaly_input(
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
    dplyr::mutate(
      anomaly_z_score =
        calculate_rolling_z_score(
          returns = simple_return,
          window = window,
          minimum_observations =
            minimum_observations
        ),

      is_anomaly =
        !is.na(anomaly_z_score) &
          abs(anomaly_z_score) >=
            z_threshold,

      anomaly_direction =
        dplyr::case_when(
          is_anomaly &
            anomaly_z_score > 0 ~
            "positive",

          is_anomaly &
            anomaly_z_score < 0 ~
            "negative",

          TRUE ~
            NA_character_
        )
    ) |>
    dplyr::ungroup()
}

summarise_market_anomalies <- function(
  anomaly_results
) {
  anomaly_results |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::summarise(
      observations = sum(
        is.finite(anomaly_z_score)
      ),

      anomalies = sum(
        is_anomaly,
        na.rm = TRUE
      ),

      positive_anomalies = sum(
        anomaly_direction == "positive",
        na.rm = TRUE
      ),

      negative_anomalies = sum(
        anomaly_direction == "negative",
        na.rm = TRUE
      ),

      anomaly_rate = dplyr::if_else(
        observations > 0,
        anomalies / observations,
        NA_real_
      ),

      largest_absolute_z =
        if (
          any(
            is.finite(
              anomaly_z_score
            )
          )
        ) {
          max(
            abs(
              anomaly_z_score
            ),
            na.rm = TRUE
          )
        } else {
          NA_real_
        },

      latest_anomaly_date =
        if (
          any(
            is_anomaly,
            na.rm = TRUE
          )
        ) {
          max(
            date[
              is_anomaly
            ],
            na.rm = TRUE
          )
        } else {
          as.Date(
            NA
          )
        },

      .groups = "drop"
    )
}