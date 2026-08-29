testthat::test_that(
  "event study correctly positions the event day",
{
  analytics <- tibble::tibble(
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

  result <- prepare_single_event_study(
    analytics = analytics,
    series_key = "test_market",
    event_date = "2026-01-06",
    pre_window = 2,
    post_window = 2
  )

  testthat::expect_equal(
    nrow(result),
    5
  )

  testthat::expect_equal(
    result$event_day,
    c(
      -2,
      -1,
      0,
      1,
      2
    )
  )

  testthat::expect_equal(
    result$date[
      result$event_day == 0
    ],
    as.Date("2026-01-06")
  )
}
)

testthat::test_that(
  "event study summary captures the event-day return",
{
  analytics <- tibble::tibble(
    series_key = rep(
      "test_market",
      7
    ),

    date = seq.Date(
      from = as.Date(
        "2026-01-01"
      ),
      by = "day",
      length.out = 7
    ),

    simple_return = c(
      0.01,
      0.02,
      -0.01,
      0.05,
      -0.02,
      0.01,
      0
    )
  )

  study <- prepare_single_event_study(
    analytics = analytics,
    series_key = "test_market",
    event_date = "2026-01-04",
    pre_window = 2,
    post_window = 2
  )

  summary <- summarise_single_event_study(
    study
  )

  testthat::expect_equal(
    summary$event_day_return[[1]],
    0.05
  )
}
)