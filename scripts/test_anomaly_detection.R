source("R/anomaly_detection.R")

normal_returns <- rep(
  c(
    -0.01,
    -0.005,
    0,
    0.005,
    0.01
  ),
  12
)

test_returns <- c(
  normal_returns,
  0.15
)

test_analytics <- tibble::tibble(
  series_key = rep(
    "test_market",
    length(test_returns)
  ),

  date = seq.Date(
    from = as.Date(
      "2026-01-01"
    ),
    by = "day",
    length.out =
      length(test_returns)
  ),

  simple_return =
    test_returns
)

results <- detect_market_anomalies(
  analytics = test_analytics,
  window = 60,
  minimum_observations = 30,
  z_threshold = 3
)

stopifnot(
  nrow(results) ==
    length(test_returns)
)

stopifnot(
  results$is_anomaly[
    nrow(results)
  ]
)

stopifnot(
  results$anomaly_direction[
    nrow(results)
  ] == "positive"
)

stopifnot(
  results$anomaly_z_score[
    nrow(results)
  ] > 3
)

summary <- summarise_market_anomalies(
  results
)

stopifnot(
  summary$anomalies[[1]] >= 1
)

stopifnot(
  summary$positive_anomalies[[1]] >= 1
)

cat(
  "Anomaly detection tests passed.\n"
)