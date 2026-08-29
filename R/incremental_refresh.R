calculate_refresh_start <- function(
  stored_dates,
  default_start = as.Date("2020-01-01"),
  revision_buffer_days = 7
) {
  default_start <- as.Date(
    default_start
  )

  if (revision_buffer_days < 0) {
    stop(
      "Revision buffer cannot be negative."
    )
  }

  stored_dates <- as.Date(
    stored_dates
  )

  stored_dates <- stored_dates[
    !is.na(stored_dates)
  ]

  if (length(stored_dates) == 0) {
    return(
      default_start
    )
  }

  latest_date <- max(
    stored_dates
  )

  buffered_start <- latest_date -
    revision_buffer_days

  max(
    default_start,
    buffered_start
  )
}

get_series_refresh_start <- function(
  connection,
  series_key,
  default_start = as.Date("2020-01-01"),
  revision_buffer_days = 7
) {
  stored <- get_observations(
    connection = connection,
    series_key = series_key
  )

  calculate_refresh_start(
    stored_dates = stored$date,
    default_start = default_start,
    revision_buffer_days =
      revision_buffer_days
  )
}

refresh_market_series_incrementally <- function(
  connection,
  fred_api_key,
  eia_api_key,
  default_start = as.Date("2020-01-01"),
  revision_buffer_days = 7,
  observation_end = NULL
) {
  market_series <- get_market_series()

  results <- lapply(
    seq_len(
      nrow(market_series)
    ),

    function(index) {
      metadata <- market_series[
        index,
      ]

      series_key <-
        metadata$series_key[[1]]

      source <-
        metadata$source[[1]]

      refresh_start <-
        get_series_refresh_start(
          connection = connection,
          series_key = series_key,
          default_start = default_start,
          revision_buffer_days =
            revision_buffer_days
        )

      stored_before <- nrow(
        get_observations(
          connection,
          series_key
        )
      )

      cat(
        sprintf(
          "Refreshing %s from %s...\n",
          series_key,
          refresh_start
        )
      )

      refreshed <-
        if (source == "fred") {
          refresh_fred_series(
            connection = connection,
            series_key = series_key,
            fred_api_key = fred_api_key,
            observation_start =
              as.character(
                refresh_start
              ),
            observation_end =
              observation_end
          )
        } else if (source == "eia") {
          refresh_eia_series(
            connection = connection,
            series_key = series_key,
            eia_api_key = eia_api_key,
            observation_start =
              as.character(
                refresh_start
              ),
            observation_end =
              observation_end
          )
        } else {
          stop(
            sprintf(
              "Unsupported data source: %s",
              source
            )
          )
        }

      stored_after_data <-
        get_observations(
          connection,
          series_key
        )

      stored_after <- nrow(
        stored_after_data
      )

      latest_stored_date <-
        if (
          stored_after > 0
        ) {
          max(
            stored_after_data$date,
            na.rm = TRUE
          )
        } else {
          as.Date(
            NA
          )
        }

      tibble::tibble(
        series_key = series_key,
        source = source,
        refresh_start = refresh_start,
        observations_received =
          nrow(refreshed),
        stored_before = stored_before,
        stored_after = stored_after,
        net_new_rows =
          stored_after -
            stored_before,
        latest_stored_date =
          latest_stored_date
      )
    }
  )

  dplyr::bind_rows(
    results
  )
}