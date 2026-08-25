source("R/correlation_analytics.R")

dates <- seq.Date(
  from = as.Date("2026-01-01"),
  by = "day",
  length.out = 10
)

series_a <- c(
  0.01,
  0.02,
  -0.01,
  0.03,
  -0.02,
  0.01,
  0.04,
  -0.03,
  0.02,
  0.01
)

series_b <- series_a * 2

series_c <- series_a * -1

test_analytics <- dplyr::bind_rows(
  tibble::tibble(
    series_key = "series_a",
    date = dates,
    simple_return = series_a
  ),

  tibble::tibble(
    series_key = "series_b",
    date = dates,
    simple_return = series_b
  ),

  tibble::tibble(
    series_key = "series_c",
    date = dates,
    simple_return = series_c
  )
)

positive_correlation <- calculate_pair_correlation(
  test_analytics,
  "series_a",
  "series_b"
)

negative_correlation <- calculate_pair_correlation(
  test_analytics,
  "series_a",
  "series_c"
)

stopifnot(
  abs(
    positive_correlation - 1
  ) < 0.000001
)

stopifnot(
  abs(
    negative_correlation + 1
  ) < 0.000001
)

rolling_results <- calculate_rolling_correlation(
  analytics = test_analytics,
  first_series = "series_a",
  second_series = "series_b",
  window = 5
)

stopifnot(
  is.na(
    rolling_results$correlation[[4]]
  )
)

stopifnot(
  abs(
    rolling_results$correlation[[5]] - 1
  ) < 0.000001
)

cat(
  "Correlation analytics tests passed.\n"
)