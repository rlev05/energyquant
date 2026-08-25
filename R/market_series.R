market_series <- tibble::tribble(
  ~series_key,   ~display_name,                     ~category,   ~source, ~source_route,          ~source_id,  ~frequency, ~unit,
  "brent",       "Brent Crude Oil",                 "energy",    "eia",   "petroleum/pri/spt",    "RBRTE",     "daily",    "USD/barrel",
  "wti",         "WTI Crude Oil",                   "energy",    "eia",   "petroleum/pri/spt",    "RWTC",      "daily",    "USD/barrel",
  "natural_gas", "Henry Hub Natural Gas",           "energy",    "eia",   "natural-gas/pri/fut",  "RNGWHHD",   "daily",    "USD/MMBtu",
  "sp500",       "S&P 500",                         "financial", "fred",  NA_character_,           "SP500",     "daily",    "index",
  "usd_index",   "Nominal Broad U.S. Dollar Index", "macro",     "fred",  NA_character_,           "DTWEXBGS",  "daily",    "index",
  "fed_funds",   "Federal Funds Effective Rate",    "macro",     "fred",  NA_character_,           "DFF",       "daily",    "percent"
)

get_market_series <- function() {
  market_series
}

get_series_by_key <- function(series_key) {
  result <- market_series[
  market_series$series_key == series_key,
  ]

  if (nrow(result) == 0) {
    stop(
      sprintf(
        "Unknown market series: %s",
        series_key
      )
    )
  }


  result
}




get_series_by_source <- function(source) {
  market_series[
  market_series$source == source,
  ]
}

