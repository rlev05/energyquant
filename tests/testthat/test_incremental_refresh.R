testthat::test_that(
  "empty stores use the configured default start date",
{
  result <- calculate_refresh_start(
    stored_dates =
      as.Date(character()),
    default_start =
      as.Date("2020-01-01"),
    revision_buffer_days = 7
  )

  testthat::expect_equal(
    result,
    as.Date("2020-01-01")
  )
}
)

testthat::test_that(
  "incremental refresh rewinds by the revision buffer",
{
  stored_dates <- as.Date(
    c(
      "2026-08-20",
      "2026-08-21",
      "2026-08-22"
    )
  )

  result <- calculate_refresh_start(
    stored_dates =
      stored_dates,
    default_start =
      as.Date("2020-01-01"),
    revision_buffer_days = 7
  )

  testthat::expect_equal(
    result,
    as.Date("2026-08-15")
  )
}
)

testthat::test_that(
  "refresh start never precedes the configured default",
{
  result <- calculate_refresh_start(
    stored_dates =
      as.Date(
        c(
          "2020-01-02",
          "2020-01-03"
        )
      ),
    default_start =
      as.Date("2020-01-01"),
    revision_buffer_days = 7
  )

  testthat::expect_equal(
    result,
    as.Date("2020-01-01")
  )
}
)

testthat::test_that(
  "negative revision buffers are rejected",
{
  testthat::expect_error(
    calculate_refresh_start(
      stored_dates =
        as.Date("2026-08-22"),
      revision_buffer_days = -1
    ),
    "Revision buffer cannot be negative"
  )
}
)