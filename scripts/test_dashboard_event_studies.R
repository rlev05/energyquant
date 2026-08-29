source("R/dashboard_event_studies.R")

test_analytics <- tibble::tibble(
  series_key = rep(
    "test_market",
    10
  ),

  date = seq.Date(
    from = as.Date(
      "2026-01-01"
    ),
    by = "day",
    length.out = 10
  ),

  simple_return = c(
    0.01,
    -0.01,
    0.02,
    0.01,
    -0.02,
    0.03,
    0.01,
    -0.01,
    0.02,
    0
  )
)

study <- prepare_single_event_study(
  analytics = test_analytics,
  series_key = "test_market",
  event_date = "2026-01-06",
  pre_window = 2,
  post_window = 2
)

stopifnot(
  nrow(study) == 5
)

stopifnot(
  study$event_day[[3]] == 0
)

stopifnot(
  study$date[[3]] ==
    as.Date("2026-01-06")
)

summary <- summarise_single_event_study(
  study
)

stopifnot(
  nrow(summary) == 1
)

stopifnot(
  summary$event_day_return[[1]] ==
    0.03
)

cat(
  "Dashboard event study tests passed.\n"
)