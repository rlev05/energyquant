source("R/config.R")
source("R/market_series.R")
source("R/eia_client.R")

config <- load_config()

eia_series <- get_series_by_source(
  "eia"
)

for (series_key in eia_series$series_key) {
  series_metadata <- get_series_by_key(
    series_key
  )

  cat(
    sprintf(
      "\n%s:\n",
      series_metadata$display_name[[1]]
    )
  )

  observations <- fetch_eia_observations(
    route = series_metadata$source_route[[1]],
    series_id = series_metadata$source_id[[1]],
    api_key = config$eia_api_key,
    frequency = series_metadata$frequency[[1]],
    observation_start = "2026-01-01"
  )

  print(
    dplyr::slice_tail(
      observations,
      n = 5
    )
  )
}