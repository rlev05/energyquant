prepare_single_event_study <- function(
  analytics,
  series_key,
  event_date,
  pre_window = 5,
  post_window = 5
) {
  series_data <- analytics |>
    dplyr::filter(
      series_key == .env$series_key,
      is.finite(simple_return)
    ) |>
    dplyr::arrange(
      date
    )

  if (nrow(series_data) == 0) {
    stop(
      sprintf(
        "No analytics data found for series '%s'.",
        series_key
      )
    )
  }

  event_date <- as.Date(
    event_date
  )

  event_candidates <- which(
    series_data$date >= event_date
  )

  if (length(event_candidates) > 0) {
    event_index <- event_candidates[[1]]
  } else {
    event_index <- nrow(
      series_data
    )
  }

  window_start <- max(
    1,
    event_index - pre_window
  )

  window_end <- min(
    nrow(series_data),
    event_index + post_window
  )

  event_data <- series_data[
    window_start:window_end,
  ]

  event_position <- event_index -
    window_start +
    1

  event_data |>
    dplyr::mutate(
      event_date =
        series_data$date[[event_index]],

      event_day =
        seq_len(
          nrow(event_data)
        ) -
          event_position,

      cumulative_event_return =
        cumprod(
          1 + simple_return
        ) - 1
    )
}

summarise_single_event_study <- function(
  event_data
) {
  if (nrow(event_data) == 0) {
    return(
      tibble::tibble()
    )
  }

  event_row <- event_data |>
    dplyr::filter(
      event_day == 0
    )

  pre_event <- event_data |>
    dplyr::filter(
      event_day < 0
    )

  post_event <- event_data |>
    dplyr::filter(
      event_day > 0
    )

  tibble::tibble(
    series_key =
      dplyr::first(
        event_data$series_key
      ),

    event_date =
      dplyr::first(
        event_data$event_date
      ),

    pre_event_return =
      if (nrow(pre_event) > 0) {
        prod(
          1 + pre_event$simple_return
        ) - 1
      } else {
        NA_real_
      },

    event_day_return =
      if (nrow(event_row) > 0) {
        event_row$simple_return[[1]]
      } else {
        NA_real_
      },

    post_event_return =
      if (nrow(post_event) > 0) {
        prod(
          1 + post_event$simple_return
        ) - 1
      } else {
        NA_real_
      },

    total_window_return =
      prod(
        1 + event_data$simple_return
      ) - 1
  )
}

prepare_cross_market_event_study <- function(
  analytics,
  event_date,
  pre_window = 5,
  post_window = 5
) {
  series_keys <- unique(
    analytics$series_key
  )

  studies <- lapply(
    series_keys,
    function(series_key) {
      prepare_single_event_study(
        analytics = analytics,
        series_key = series_key,
        event_date = event_date,
        pre_window = pre_window,
        post_window = post_window
      )
    }
  )

  summaries <- lapply(
    studies,
    summarise_single_event_study
  )

  list(
    studies = studies,
    summary = dplyr::bind_rows(
      summaries
    )
  )
}