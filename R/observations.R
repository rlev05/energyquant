standardise_observations <- function(
observations,
series_key,
source,
source_id,
unit,
frequency
) {
  required_columns <- c(
    "date",
    "value"
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

  observations |>
    dplyr::transmute(
      series_key = series_key,
      source = source,
      source_id = source_id,
      date = as.Date(date),
      value = as.numeric(value),
      unit = unit,
      frequency = frequency,
      ingested_at = as.POSIXct(
        Sys.time(),
        tz = "UTC"
      )
    )
}

standardise_series_observations <- function(
observations,
series_metadata
) {
  if (nrow(series_metadata) != 1) {
    stop(
      "series_metadata must contain exactly one row."
    )
  }

  standardise_observations(
    observations = observations,
    series_key = series_metadata$series_key[[1]],
    source = series_metadata$source[[1]],
    source_id = series_metadata$source_id[[1]],
    unit = series_metadata$unit[[1]],
    frequency = series_metadata$frequency[[1]]
  )
}