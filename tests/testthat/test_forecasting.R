testthat::test_that(
  "naive forecasts use the latest observed value",
{
  values <- c(
    100,
    102,
    101,
    105
  )

  result <- forecast_naive(
    values
  )

  testthat::expect_equal(
    as.numeric(result),
    105
  )
}
)