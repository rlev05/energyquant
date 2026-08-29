run_dashboard_backtest <- function(
observations,
series_key,
evaluation_points = 30,
training_window = 500,
minimum_training = 120
) {
  results <- rolling_forecast_backtest(
    observations = observations,
    series_key = series_key,
    evaluation_points = evaluation_points,
    training_window = training_window,
    minimum_training = minimum_training
  )

  performance <- summarise_forecast_performance(
    results
  )

  list(
    results = results,
    performance = performance,
    best_model = find_best_forecasting_models(
      performance
    )
  )
}

