source("R/market_analytics.R")
source("R/forecasting.R")
source("R/incremental_refresh.R")
source("R/dashboard_event_studies.R")

testthat::test_dir(
  "tests/testthat",
  reporter = "summary",
  env = globalenv()
)