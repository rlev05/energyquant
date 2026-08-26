source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/forecasting.R")


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

results <- lapply(
  market_metadata$series_key,

  function(series_key) {
    cat(
      sprintf(
        "Backtesting %s...\n",
        series_key
      )
    )

    rolling_forecast_backtest(
      observations = observations,
      series_key = series_key,
      evaluation_points = 60,
      training_window = 500,
      minimum_training = 120
    )
  }
)

backtest_results <- dplyr::bind_rows(
  results
)

performance <-
  summarise_forecast_performance(
    backtest_results
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
      model,
      forecasts,
      mae,
      rmse,
      smape,
      bias,
      directional_accuracy,
      rmse_rank
    ) |>
    dplyr::arrange(
      series_key,
      rmse_rank
    )

best_models <-
  find_best_forecasting_models(
    performance
  )

cat(
  "\nEnergyQuant out-of-sample forecasting performance\n\n"
)

print(
  performance,
  width = Inf
)

cat(
  "\nBest model by out-of-sample RMSE\n\n"
)

print(
  best_models |>
    dplyr::select(
      series_key,
      display_name,
      model,
      rmse,
      mae,
      directional_accuracy
    ),

  width = Inf
)

disconnect_database(
  connection
)

