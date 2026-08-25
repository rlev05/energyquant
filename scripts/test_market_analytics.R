source("R/market_analytics.R")

test_observations <- tibble::tibble(
  series_key = c(
    "test",
    "test",
    "test",
    "test"
  ),
  date = as.Date(
    c(
      "2026-01-01",
      "2026-01-02",
      "2026-01-03",
      "2026-01-04"
    )
  ),
  value = c(
    100,
    105,
    102,
    108
  )
)

analytics <- calculate_market_analytics(
  observations = test_observations,
  volatility_window = 2
)

stopifnot(
  nrow(analytics) == 4
)

stopifnot(
  is.na(
    analytics$simple_return[[1]]
  )
)

stopifnot(
  abs(
    analytics$cumulative_return[[4]] - 0.08
  ) < 0.000001
)

expected_drawdown <- (
  102 / 105
) - 1

stopifnot(
  abs(
    min(analytics$drawdown) -
      expected_drawdown
  ) < 0.000001
)

stopifnot(
  !is.na(
    analytics$rolling_volatility[[3]]
  )
)

cat(
  "Market analytics tests passed.\n"
)