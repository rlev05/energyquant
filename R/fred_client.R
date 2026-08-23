FRED_BASE_URL <- "https://api.stlouisfed.org/fred"

validate_fred_api_key <- function(api_key) {
  if (is.null(api_key) || !nzchar(api_key)) {
    stop(
      "FRED_API_KEY is missing. Add it to your local .env file"
    )
  }

  invisible((TRUE))
}

build_fred_observations_request <- function(
series_id,
api_key,
observation_start = NULL,
observation_end = NULL
) {
  validate_fred_api_key(api_key)

  request <- httr2::request(
    paste0(
      FRED_BASE_URL,
      "/series/observations"
    )
  ) |>
    httr2::req_url_query(
      series_id = series_id,
      api_key = api_key,
      file_type = "json"
    ) |>
    httr2::req_error(
      is_error = function(response) {
        httr2::resp_status(response) >= 400
      }
    )

  if (!is.null(observation_start)) {
    request <- request |>
      httr2::req_url_query(
        observation_start = observation_start
      )
  }

  if (!is.null(observation_end)) {
    request <- request |>
      httr2::req_url_query(
        observation_end = observation_end
      )
  }

  request
}

fetch_fred_observations <- function(
series_id,
api_key,
observation_start = NULL,
observation_end = NULL
) {
request <- build_fred_observations_request(
  series_id = series_id,
  api_key = api_key,
  observation_start = observation_start,
  observation_end = observation_end
)

  response <- request |>
    httr2::req_perform()

  payload <- httr2::resp_body_json(
    response,
    simplifyVector = TRUE
  )

  observations <- tibble::as_tibble(
    payload$observations
  )

  if (nrow(observations) == 0) {
    return(
      tibble::tibble(
        date = as.Date(character()),
        value = numeric()
      )
    )
  }

  observations |>
    dplyr::transmute(
      date = as.Date(date),
      value = suppressWarnings(
        as.numeric(value)
      )
    ) |>
    dplyr::filter(
      !is.na(value)
    )
}

