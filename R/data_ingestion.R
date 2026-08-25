refresh_fred_series <- function(
connection,
series_key,
fred_api_key,
observation_start = NULL,
observation_end = NUll
) {
  series_metadata <- get_series_by_key(
    series_key
  )

  if (series_metadata$source[[1]] != "fred") {
    stop(
      sprintf(
        "Series '%s' is not a FRED series.",
        series_key
      )
    )
  }

  raw_observations <- fetch_fred_observations(
    series_id = series_metadata$source_id[[1]],
    api_key = fred_api_key,
    observation_start = observation_start,
    observation_end = observation_end
  )

  observations <- standardise_series_observations(
    observations = raw_observations,
    series_metadata = series_metadata
  )

  upsert_observations(
    connection = connection,
    observations = observations
  )

  observations
}

refresh_all_fred_series <- function(
connection,
fred_api_key,
observation_start = NULL,
observation_end = NULL
) {
  fred_series <- get_series_by_source(
    "fred"
  )

  results <- lapply(
    fred_series$series_key,
    function(series_key) {
      refresh_fred_series(
        connection = connection,
        series_key = series_key,
        fred_api_key = fred_api_key,
        observation_start = observation_start,
        observation_end = observation_end
      )
    }
  )

  dplyr::bind_rows(
    results
  )
}