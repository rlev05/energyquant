refresh_fred_series <- function(
  connection,
  series_key,
  fred_api_key,
  observation_start = NULL,
  observation_end = NULL
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

refresh_eia_series <- function(
  connection,
  series_key,
  eia_api_key,
  observation_start = NULL,
  observation_end = NULL
) {
  series_metadata <- get_series_by_key(
    series_key
  )

  if (series_metadata$source[[1]] != "eia") {
    stop(
      sprintf(
        "Series '%s' is not an EIA series.",
        series_key
      )
    )
  }

  raw_observations <- fetch_eia_observations(
    route = series_metadata$source_route[[1]],
    series_id = series_metadata$source_id[[1]],
    api_key = eia_api_key,
    frequency = series_metadata$frequency[[1]],
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

refresh_all_eia_series <- function(
  connection,
  eia_api_key,
  observation_start = NULL,
  observation_end = NULL
) {
  eia_series <- get_series_by_source(
    "eia"
  )

  results <- lapply(
    eia_series$series_key,
    function(series_key) {
      refresh_eia_series(
        connection = connection,
        series_key = series_key,
        eia_api_key = eia_api_key,
        observation_start = observation_start,
        observation_end = observation_end
      )
    }
  )

  dplyr::bind_rows(
    results
  )
}

refresh_all_market_series <- function(
  connection,
  fred_api_key,
  eia_api_key,
  observation_start = NULL,
  observation_end = NULL
) {
  fred_observations <- refresh_all_fred_series(
    connection = connection,
    fred_api_key = fred_api_key,
    observation_start = observation_start,
    observation_end = observation_end
  )

  eia_observations <- refresh_all_eia_series(
    connection = connection,
    eia_api_key = eia_api_key,
    observation_start = observation_start,
    observation_end = observation_end
  )

  dplyr::bind_rows(
    fred_observations,
    eia_observations
  )
}