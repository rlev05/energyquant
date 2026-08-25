validate_observation_schema <- function(observations) {
  required_columns <- c(
    "series_key",
    "source",
    "source_id",
    "date",
    "value",
    "unit",
    "frequency",
    "ingested_at"
  )

  missing_columns <- setdiff(
    required_columns,
    names(observations)
  )

  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Observations are missing required columns: %s",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }

  invisible(TRUE)
}

find_duplicate_observations <- function(observations) {
  validate_observation_schema(
    observations
  )

  observations |>
    dplyr::count(
      series_key,
      date,
      name = "duplicates"
    ) |>
    dplyr::filter(
      duplicates > 1
    )
}

find_invalid_observations <- function(observations) {
  validate_observation_schema(
    observations
  )

  observations |>
    dplyr::filter(
      is.na(series_key) |
        is.na(date) |
        is.na(value) |
        !is.finite(value)
    )
}

summarise_data_quality <- function(
  observations,
  expected_series,
  reference_date = Sys.Date(),
  stale_after_days = 14
) {
  validate_observation_schema(
    observations
  )

  expected_keys <- expected_series$series_key

  observations |>
    dplyr::filter(
      series_key %in% expected_keys
    ) |>
    dplyr::group_by(
      series_key
    ) |>
    dplyr::summarise(
      rows = dplyr::n(),
      first_date = min(
        date,
        na.rm = TRUE
      ),
      latest_date = max(
        date,
        na.rm = TRUE
      ),
      missing_values = sum(
        is.na(value)
      ),
      non_finite_values = sum(
        !is.finite(value),
        na.rm = TRUE
      ),
      duplicate_dates = sum(
        duplicated(date)
      ),
      .groups = "drop"
    ) |>
    dplyr::right_join(
      expected_series |>
        dplyr::select(
          series_key,
          display_name,
          source
        ),
      by = "series_key"
    ) |>
    dplyr::mutate(
      rows = dplyr::coalesce(
        rows,
        0L
      ),
      missing_values = dplyr::coalesce(
        missing_values,
        0L
      ),
      non_finite_values = dplyr::coalesce(
        non_finite_values,
        0L
      ),
      duplicate_dates = dplyr::coalesce(
        duplicate_dates,
        0L
      ),
      days_since_latest = as.integer(
        reference_date - latest_date
      ),
      stale = dplyr::if_else(
        is.na(latest_date),
        TRUE,
        days_since_latest > stale_after_days
      ),
      status = dplyr::case_when(
        rows == 0 ~ "FAIL",
        missing_values > 0 ~ "FAIL",
        non_finite_values > 0 ~ "FAIL",
        duplicate_dates > 0 ~ "FAIL",
        stale ~ "WARN",
        TRUE ~ "PASS"
      )
    ) |>
    dplyr::arrange(
      source,
      series_key
    )
}

data_quality_passed <- function(quality_summary) {
  !any(
    quality_summary$status == "FAIL"
  )
}