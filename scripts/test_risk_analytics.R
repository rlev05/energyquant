source("R/risk_analytics.R")

test_returns <- c(
  0.02,
  -0.01,
  0.015,
  -0.03,
  0.01,
  -0.02,
  0.005,
  0.012,
  -0.008,
  0.018
)

var_95 <- historical_var(
  test_returns,
  confidence_level = 0.95
)

expected_shortfall_95 <-
  historical_expected_shortfall(
    test_returns,
    confidence_level = 0.95
  )

stopifnot(
  is.finite(var_95)
)

stopifnot(
  var_95 >= 0
)

stopifnot(
  is.finite(
    expected_shortfall_95
  )
)

stopifnot(
  expected_shortfall_95 >= var_95
)

downside_deviation <-
  calculate_downside_deviation(
    test_returns
  )

stopifnot(
  downside_deviation > 0
)

annualised_return <-
  calculate_annualised_return(
    test_returns
  )

stopifnot(
  is.finite(
    annualised_return
  )
)

risk_free <- tibble::tibble(
  date = as.Date(
    c(
      "2026-01-01",
      "2026-01-02"
    )
  ),
  value = c(
    4,
    4
  )
)

risk_free_returns <-
  prepare_risk_free_returns(
    risk_free
  )

stopifnot(
  all(
    risk_free_returns$daily_risk_free_return >
      0
  )
)

cat(
  "Risk analytics tests passed.\n"
)