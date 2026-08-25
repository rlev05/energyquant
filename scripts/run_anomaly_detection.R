source("R/config.R")
source("R/database.R")
source("R/market_series.R")
source("R/observation_store.R")
source("R/market_analytics.R")
source("R/anomaly_detection.R")


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

analytics <- calculate_market_analytics(
  observations
)

anomaly_results <- detect_market_anomalies(
  analytics = analytics,
  window = 60,
  minimum_observations = 30,
  z_threshold = 3
)

anomaly_summary <-
  summarise_market_anomalies(
    anomaly_results
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
      dplyr::everything()
    )

recent_anomalies <- anomaly_results |>
  dplyr::filter(
    is_anomaly
  ) |>
  dplyr::arrange(
    dplyr::desc(
      date
    )
  ) |>
  dplyr::select(
    series_key,
    date,
    value,
    simple_return,
    anomaly_z_score,
    anomaly_direction
  ) |>
  dplyr::slice_head(
    n = 20
  )

cat(
  "EnergyQuant anomaly summary\n\n"
)

print(
  anomaly_summary,
  width = Inf
)

cat(
  "\nMost recent detected anomalies\n\n"
)

print(
  recent_anomalies,
  width = Inf
)

disconnect_database(
  connection
)