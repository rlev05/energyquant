source("R/regime_detection.R")

test_volatility <- c(
  rep(
    0.10,
    60
  ),
  rep(
    0.20,
    10
  ),
  rep(
    0.05,
    10
  )
)

test_analytics <- tibble::tibble(
  series_key = rep(
    "test_market",
    length(test_volatility)
  ),

  date = seq.Date(
    from = as.Date(
      "2026-01-01"
    ),
    by = "day",
    length.out =
      length(test_volatility)
  ),

  simple_return = rep(
    0.001,
    length(test_volatility)
  ),

  rolling_volatility =
    test_volatility
)

results <- detect_market_regimes(
  analytics = test_analytics,
  lookback = 60,
  minimum_history = 30
)

stopifnot(
  all(
    is.na(
      results$regime[
        1:30
      ]
    )
  )
)

stopifnot(
  results$regime[[31]] ==
    "normal"
)

stopifnot(
  results$regime[[61]] ==
    "high"
)

stopifnot(
  results$regime[[71]] ==
    "low"
)

transitions <- find_regime_transitions(
  results
)

stopifnot(
  nrow(transitions) >= 2
)

cat(
  "Regime detection tests passed.\n"
)