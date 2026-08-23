source("R/config.R")
source("R/database.R")
source("R/observation_store.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

test_observations <- tibble::tibble(
  series_key = c(
    "test_series",
    "test_series"
  ),
  source = c(
    "test",
    "test"
  ),
  source_id = c(
    "TEST",
    "TEST"
  ),
  date = as.Date(
    c(
      "2026-01-01",
      "2026-01-02"
    )
  ),
  value = c(
    100,
    105
  ),
  unit = c(
    "index",
    "index"
  ),
  frequency = c(
    "daily",
    "daily"
  ),
  ingested_at = as.POSIXct(
    Sys.time(),
    tz = "UTC"
  )
)

upsert_observations(
  connection,
  test_observations
)

stored <- get_observations(
  connection,
  "test_series"
)

print(stored)

disconnect_database(connection)

