testthat::test_that(
  "market returns ignore invalid negative price pairs",
{
  observations <- tibble::tibble(
    series_key = rep(
      "test_market",
      4
    ),

    source = rep(
      "test",
      4
    ),

    source_id = rep(
      "TEST",
      4
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
      50,
      55,
      -10,
      20
    ),

    unit = rep(
      "USD",
      4
    ),

    frequency = rep(
      "daily",
      4
    )
  )

  results <- calculate_market_analytics(
    observations
  )

  testthat::expect_true(
    is.na(
      results$simple_return[[1]]
    )
  )

  testthat::expect_equal(
    results$simple_return[[2]],
    0.1
  )

  testthat::expect_true(
    is.na(
      results$simple_return[[3]]
    )
  )

  testthat::expect_true(
    is.na(
      results$simple_return[[4]]
    )
  )

  testthat::expect_true(
    is.na(
      results$log_return[[3]]
    )
  )

  testthat::expect_true(
    is.na(
      results$log_return[[4]]
    )
  )
}
)