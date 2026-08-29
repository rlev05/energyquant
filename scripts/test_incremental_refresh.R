source("R/incremental_refresh.R")

default_start <- as.Date(
  "2020-01-01"
)

empty_start <-
  calculate_refresh_start(
    stored_dates =
      as.Date(character()),
    default_start =
      default_start,
    revision_buffer_days = 7
  )

stopifnot(
  empty_start ==
    as.Date("2020-01-01")
)

stored_dates <- as.Date(
  c(
    "2026-08-20",
    "2026-08-21",
    "2026-08-22"
  )
)

buffered_start <-
  calculate_refresh_start(
    stored_dates =
      stored_dates,
    default_start =
      default_start,
    revision_buffer_days = 7
  )

stopifnot(
  buffered_start ==
    as.Date("2026-08-15")
)

early_dates <- as.Date(
  c(
    "2020-01-02",
    "2020-01-03"
  )
)

bounded_start <-
  calculate_refresh_start(
    stored_dates =
      early_dates,
    default_start =
      default_start,
    revision_buffer_days = 7
  )

stopifnot(
  bounded_start ==
    default_start
)

error_raised <- FALSE

tryCatch(
{
  calculate_refresh_start(
    stored_dates =
      stored_dates,
    revision_buffer_days = -1
  )
},

  error = function(error) {
    error_raised <<- TRUE
  }
)

stopifnot(
  error_raised
)

cat(
  "Incremental refresh tests passed.\n"
)