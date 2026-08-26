validate_forecast_input <- function(
  observations
) {
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
        "Forecast input is missing required columns: %s",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }

  invisible(TRUE)
}

forecast_naive <- function(
  training_values
) {
  if (length(training_values) == 0) {
    return(
      NA_real_
    )
  }

  tail(
    training_values,
    1
  )
}

forecast_arima <- function(
  training_values
) {
  model <- forecast::auto.arima(
    training_values,
    seasonal = FALSE,
    stepwise = TRUE,
    approximation = FALSE
  )

  prediction <- forecast::forecast(
    model,
    h = 1
  )

  as.numeric(
    prediction$mean[[1]]
  )
}

forecast_ets <- function(
  training_values
) {
  model <- forecast::ets(
    training_values,
    model = "ZZN"
  )

  prediction <- forecast::forecast(
    model,
    h = 1
  )

  as.numeric(
    prediction$mean[[1]]
  )
}

forecast_one_step <- function(
  training_values,
  model
) {
  switch(
    model,

    naive = forecast_naive(
      training_values
    ),

    arima = forecast_arima(
      training_values
    ),

    ets = forecast_ets(
      training_values
    ),

    stop(
      sprintf(
        "Unknown forecasting model: %s",
        model
      )
    )
  )
}

safe_forecast_one_step <- function(
  training_values,
  model
) {
  tryCatch(
    forecast_one_step(
      training_values = training_values,
      model = model
    ),

    error = function(error) {
      NA_real_
    }
  )
}

rolling_forecast_backtest <- function(
  observations,
  series_key,
  evaluation_points = 60,
  training_window = 500,
  minimum_training = 120
) {
  validate_forecast_input(
    observations
  )

  series_data <- observations |>
    dplyr::filter(
      series_key == .env$series_key,
      is.finite(value)
    ) |>
    dplyr::arrange(
      date
    )

  if (
    nrow(series_data) <
      minimum_training + 1
  ) {
    stop(
      sprintf(
        "Not enough observations to backtest series '%s'.",
        series_key
      )
    )
  }

  available_evaluation_points <-
    nrow(series_data) -
      minimum_training

  evaluation_points <- min(
    evaluation_points,
    available_evaluation_points
  )

  evaluation_start <-
    nrow(series_data) -
      evaluation_points +
      1

  models <- c(
    "naive",
    "arima",
    "ets"
  )

  results <- list()

  result_index <- 1

  for (
    test_index in
    evaluation_start:nrow(series_data)
  ) {
    training_end <-
      test_index - 1

    training_start <- max(
      1,
      training_end -
        training_window +
        1
    )

    training_values <-
      series_data$value[
        training_start:training_end
      ]

    if (
      length(training_values) <
        minimum_training
    ) {
      next
    }

    actual_value <-
      series_data$value[
        test_index
      ]

    previous_value <-
      series_data$value[
        test_index - 1
      ]

    test_date <-
      series_data$date[
        test_index
      ]

    for (model in models) {
      predicted_value <-
        safe_forecast_one_step(
          training_values =
            training_values,
          model = model
        )

      direction_correct <-
        if (
          is.finite(predicted_value) &&
            is.finite(actual_value) &&
            is.finite(previous_value)
        ) {
          sign(
            predicted_value -
              previous_value
          ) ==
            sign(
              actual_value -
                previous_value
            )
        } else {
          NA
        }

      results[[result_index]] <-
        tibble::tibble(
          series_key =
            series_key,

          date =
            test_date,

          model =
            model,

          previous_value =
            previous_value,

          actual =
            actual_value,

          forecast =
            predicted_value,

          error =
            actual_value -
              predicted_value,

          direction_correct =
            direction_correct
        )

      result_index <-
        result_index + 1
    }
  }

  dplyr::bind_rows(
    results
  )
}

summarise_forecast_performance <- function(
  backtest_results
) {
  backtest_results |>
    dplyr::filter(
      is.finite(actual),
      is.finite(forecast),
      is.finite(error)
    ) |>
    dplyr::group_by(
      series_key,
      model
    ) |>
    dplyr::summarise(
      forecasts = dplyr::n(),

      mae = mean(
        abs(error)
      ),

      rmse = sqrt(
        mean(
          error^2
        )
      ),

      smape = mean(
        dplyr::if_else(
          abs(actual) +
            abs(forecast) > 0,

          2 *
            abs(error) /
            (
              abs(actual) +
                abs(forecast)
            ),

          NA_real_
        ),

        na.rm = TRUE
      ),

      bias = mean(
        error
      ),

      directional_accuracy = mean(
        direction_correct,
        na.rm = TRUE
      ),

      .groups = "drop"
    ) |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::mutate(
      rmse_rank = rank(
        rmse,
        ties.method = "min"
      )
    ) |>
    dplyr::ungroup()
}

find_best_forecasting_models <- function(
  performance
) {
  performance |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::slice_min(
      order_by = rmse,
      n = 1,
      with_ties = FALSE
    ) |>
    dplyr::ungroup()
}