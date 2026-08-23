source("R/config.R")
source("R/fred_client.R")

config <- load_config()

observations <- fetch_fred_observations(
  series_id = "DFF",
  api_key = config$fred_api_key,
  observation_start = "2026-01-01"
)

print(
  dplyr::slice_tail(
    observations,
    n = 10
  )
)