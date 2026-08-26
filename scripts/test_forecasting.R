source("R/forecasting.R")

dates <- seq.Date(
  from = as.Date(
    "2025-01-01"
  ),
  by = "day",
  length.out = 200
)

index <- seq_along(
  dates
)

values <- 100 +
  index * 0.05 +
  sin(
    index / 7
  )

test_observations <-
  tibble::tibble(
    series_key = rep(
      "test_market",
      length(dates)
    ),

    date = dates,

    value = values
  )

results <-
  rolling_forecast_backtest(
    observations =
      test_observations,
    series_key =
      "test_market",
    evaluation_points = 10,
    training_window = 150,
    minimum_training = 100
  )

stopifnot(
  nrow(results) == 30
)

stopifnot(
  setequal(
    unique(
      results$model
    ),
    c(
      "naive",
      "arima",
      "ets"
    )
  )
)

stopifnot(
  all(
    is.finite(
      results$forecast
    )
  )
)

performance <-
  summarise_forecast_performance(
    results
  )

stopifnot(
  nrow(performance) == 3
)

stopifnot(
  all(
    performance$rmse >= 0
  )
)

best_model <-
  find_best_forecasting_models(
    performance
  )

stopifnot(
  nrow(best_model) == 1
)

cat(
  "Forecasting tests passed.\n"
)