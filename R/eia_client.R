EIA_BASE_URL <- "https://api.eia.gov/v2"

validate_eia_api_key <- function(api_key) {
  if (is.null(api_key) || !nzchar(api_key)) {
    stop(
      "EIA_API_KEY is missing. Add it to your local .env file."
    )
  }

  invisible(TRUE)
}

build_eia_data_request <- function(
  route,
  series_id,
  api_key,
  frequency = "daily",
  observation_start = NULL,
  observation_end = NULL,
  offset = 0,
  length = 5000
) {
  validate_eia_api_key(
    api_key
  )

  request <- httr2::request(
    paste0(
      EIA_BASE_URL,
      "/",
      route,
      "/data/"
    )
  ) |>
    httr2::req_url_query(
      api_key = api_key,
      frequency = frequency,
      `data[0]` = "value",
      `facets[series][]` = series_id,
      `sort[0][column]` = "period",
      `sort[0][direction]` = "asc",
      offset = offset,
      length = length
    ) |>
    httr2::req_timeout(
      seconds = 30
    ) |>
    httr2::req_retry(
      max_tries = 3
    )

  if (!is.null(observation_start)) {
    request <- request |>
      httr2::req_url_query(
        start = observation_start
      )
  }

  if (!is.null(observation_end)) {
    request <- request |>
      httr2::req_url_query(
        end = observation_end
      )
  }

  request
}

fetch_eia_observations <- function(
  route,
  series_id,
  api_key,
  frequency = "daily",
  observation_start = NULL,
  observation_end = NULL,
  page_size = 5000
) {
  offset <- 0
  pages <- list()

  repeat {
    request <- build_eia_data_request(
      route = route,
      series_id = series_id,
      api_key = api_key,
      frequency = frequency,
      observation_start = observation_start,
      observation_end = observation_end,
      offset = offset,
      length = page_size
    )

    response <- request |>
      httr2::req_perform()

    payload <- httr2::resp_body_json(
      response,
      simplifyVector = TRUE
    )

    data <- tibble::as_tibble(
      payload$response$data
    )

    if (nrow(data) == 0) {
      break
    }

    pages[[length(pages) + 1]] <- data

    offset <- offset + nrow(data)

    total <- suppressWarnings(
      as.integer(
        payload$response$total
      )
    )

    if (
      !is.na(total) &&
        offset >= total
    ) {
      break
    }

    if (nrow(data) < page_size) {
      break
    }
  }

  if (length(pages) == 0) {
    return(
      tibble::tibble(
        date = as.Date(character()),
        value = numeric()
      )
    )
  }

  dplyr::bind_rows(
    pages
  ) |>
    dplyr::transmute(
      date = as.Date(period),
      value = suppressWarnings(
        as.numeric(value)
      )
    ) |>
    dplyr::filter(
      !is.na(date),
      !is.na(value)
    ) |>
    dplyr::arrange(
      date
    )
}