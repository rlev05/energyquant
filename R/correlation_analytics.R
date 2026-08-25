validate_correlation_input <- function(analytics) {
  required_columns <- c(
    "series_key",
    "date",
    "simple_return"
  )

  missing_columns <- setdiff(
    required_columns,
    names(analytics)
  )

  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Correlation input is missing required columns: %s",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }

  invisible(TRUE)
}

prepare_return_matrix <- function(analytics) {
  validate_correlation_input(
    analytics
  )

  analytics |>
    dplyr::select(
      date,
      series_key,
      simple_return
    ) |>
    dplyr::filter(
      is.finite(simple_return)
    ) |>
    tidyr::pivot_wider(
      names_from = series_key,
      values_from = simple_return
    ) |>
    dplyr::arrange(
      date
    )
}

calculate_correlation_matrix <- function(
  analytics
) {
  return_matrix <- prepare_return_matrix(
    analytics
  )

  numeric_returns <- return_matrix |>
    dplyr::select(
      -date
    )

  stats::cor(
    numeric_returns,
    use = "pairwise.complete.obs"
  )
}

prepare_pair_returns <- function(
  analytics,
  first_series,
  second_series
) {
  validate_correlation_input(
    analytics
  )

  available_series <- unique(
    analytics$series_key
  )

  if (!first_series %in% available_series) {
    stop(
      sprintf(
        "Unknown series in analytics data: %s",
        first_series
      )
    )
  }

  if (!second_series %in% available_series) {
    stop(
      sprintf(
        "Unknown series in analytics data: %s",
        second_series
      )
    )
  }

  first_returns <- analytics |>
    dplyr::filter(
      series_key == first_series
    ) |>
    dplyr::select(
      date,
      first_return = simple_return
    )

  second_returns <- analytics |>
    dplyr::filter(
      series_key == second_series
    ) |>
    dplyr::select(
      date,
      second_return = simple_return
    )

  dplyr::inner_join(
    first_returns,
    second_returns,
    by = "date"
  ) |>
    dplyr::filter(
      is.finite(first_return),
      is.finite(second_return)
    ) |>
    dplyr::arrange(
      date
    )
}

calculate_pair_correlation <- function(
  analytics,
  first_series,
  second_series
) {
  pair_returns <- prepare_pair_returns(
    analytics = analytics,
    first_series = first_series,
    second_series = second_series
  )

  if (nrow(pair_returns) < 2) {
    return(
      NA_real_
    )
  }

  stats::cor(
    pair_returns$first_return,
    pair_returns$second_return
  )
}

rolling_correlation <- function(
  first_returns,
  second_returns,
  window = 60
) {
  if (window < 2) {
    stop(
      "Correlation window must be at least 2."
    )
  }

  result <- rep(
    NA_real_,
    length(first_returns)
  )

  for (index in seq_along(first_returns)) {
    start_index <- index - window + 1

    if (start_index < 1) {
      next
    }

    first_window <- first_returns[
      start_index:index
    ]

    second_window <- second_returns[
      start_index:index
    ]

    if (
      all(is.finite(first_window)) &&
        all(is.finite(second_window))
    ) {
      result[[index]] <- stats::cor(
        first_window,
        second_window
      )
    }
  }

  result
}

calculate_rolling_correlation <- function(
  analytics,
  first_series,
  second_series,
  window = 60
) {
  pair_returns <- prepare_pair_returns(
    analytics = analytics,
    first_series = first_series,
    second_series = second_series
  )

  correlations <- rolling_correlation(
    first_returns =
      pair_returns$first_return,
    second_returns =
      pair_returns$second_return,
    window = window
  )

  tibble::tibble(
    date = pair_returns$date,

    first_series = rep(
      first_series,
      nrow(pair_returns)
    ),

    second_series = rep(
      second_series,
      nrow(pair_returns)
    ),

    correlation = correlations
  )
}

summarise_rolling_correlation <- function(
  results
) {
  valid_results <- results |>
    dplyr::filter(
      is.finite(correlation)
    )

  if (nrow(valid_results) == 0) {
    return(
      tibble::tibble(
        first_series = dplyr::first(
          results$first_series
        ),

        second_series = dplyr::first(
          results$second_series
        ),

        observations = 0L,
        average_correlation = NA_real_,
        minimum_correlation = NA_real_,
        maximum_correlation = NA_real_,
        latest_correlation = NA_real_
      )
    )
  }

  tibble::tibble(
    first_series = dplyr::first(
      valid_results$first_series
    ),

    second_series = dplyr::first(
      valid_results$second_series
    ),

    observations = nrow(
      valid_results
    ),

    average_correlation = mean(
      valid_results$correlation
    ),

    minimum_correlation = min(
      valid_results$correlation
    ),

    maximum_correlation = max(
      valid_results$correlation
    ),

    latest_correlation = dplyr::last(
      valid_results$correlation
    )
  )
}