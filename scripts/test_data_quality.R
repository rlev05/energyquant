source("R/data_quality.R")

test_observations <- tibble::tibble(
  series_key = c(
    "test",
    "test",
    "test"
  ),
  source = c(
    "test",
    "test",
    "test"
  ),
  source_id = c(
    "TEST",
    "TEST",
    "TEST"
  ),
  date = as.Date(
    c(
      "2026-08-20",
      "2026-08-21",
      "2026-08-21"
    )
  ),
  value = c(
    100,
    101,
    101
  ),
  unit = c(
    "index",
    "index",
    "index"
  ),
  frequency = c(
    "daily",
    "daily",
    "daily"
  ),
  ingested_at = rep(
    as.POSIXct(
      "2026-08-22 12:00:00",
      tz = "UTC"
    ),
    3
  )
)

duplicates <- find_duplicate_observations(
  test_observations
)

stopifnot(
  nrow(duplicates) == 1
)

stopifnot(
  duplicates$duplicates[[1]] == 2
)

cat(
  "Data quality validation tests passed.\n"
)