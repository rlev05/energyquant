source("R/config.R")
source("R/market_series.R")
source("R/fred_client.R")
source("R/observations.R")

config <- load_config()

series_metadata <- get_series_by_key(
  "fed_funds"
)

raw_observations <- fetch_fred_observations(
  series_id = series_metadata$source_id[[1]],
  api_key = config$fred_api_key,
  observation_start = "2026-01-01"
)

observations <- standardise_series_observations(
  observations = raw_observations,
  series_metadata = series_metadata
)

print(
  dplyr::slice_tail(
    observations,
    n = 10
  )
)