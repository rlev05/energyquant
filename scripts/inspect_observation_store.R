source("R/config.R")
source("R/database.R")
source("R/observation_store.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

observations <- get_observations(
  connection,
  "test_series"
)

print(observations)

disconnect_database(connection)