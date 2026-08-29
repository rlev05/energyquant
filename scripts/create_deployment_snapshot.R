source("R/config.R")
source("R/database.R")
source("R/observation_store.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

on.exit(
  disconnect_database(
    connection
  ),
  add = TRUE
)

observations <- get_observations(
  connection
)

if (nrow(observations) == 0) {
  stop(
    "No observations are available for the deployment snapshot."
  )
}

dir.create(
  "data/deployment",
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  observations,
  "data/deployment/market_observations.rds"
)

cat(
  sprintf(
    "Saved %s deployment observations.\n",
    format(
      nrow(observations),
      big.mark = ","
    )
  )
)

cat(
  sprintf(
    "Latest observation date: %s\n",
    max(
      observations$date,
      na.rm = TRUE
    )
  )
)