prepare_data_health_dashboard <- function(
  observations,
  expected_series
) {
  quality_summary <- summarise_data_quality(
    observations = observations,
    expected_series = expected_series
  )

  duplicates <- find_duplicate_observations(
    observations |>
      dplyr::filter(
        series_key %in%
          expected_series$series_key
      )
  )

  invalid_observations <- find_invalid_observations(
    observations |>
      dplyr::filter(
        series_key %in%
          expected_series$series_key
      )
  )

  list(
    summary = quality_summary,
    duplicates = duplicates,
    invalid = invalid_observations,
    overall_status = if (
      data_quality_passed(
        quality_summary
      )
    ) {
      "PASS"
    } else {
      "FAIL"
    }
  )
}