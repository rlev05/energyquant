source("R/config.R")
source("R/database.R")
source("R/observation_store.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

observations <- get_observations(
  connection
)

summary <- observations |>
  dplyr::filter(
    source %in% c(
      "fred",
      "eia"
    )
  ) |>
  dplyr::group_by(
    source,
    series_key
  ) |>
  dplyr::summarise(
    rows = dplyr::n(),
    first_date = min(date),
    latest_date = max(date),
    latest_value = value[
    which.max(date)
    ],
    .groups = "drop"
  ) |>
  dplyr::arrange(
    source,
    series_key
  )

print(
  summary
)

disconnect_database(
  connection
)
