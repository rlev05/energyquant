market_series <- tibble::tribble(
  ~series_key,   ~display_name,                     ~category,   ~source, ~source_route,         ~source_id, ~frequency, ~unit,        ~return_eligible,
  "brent",       "Brent Crude Oil",                 "energy",    "eia",   "petroleum/pri/spt",   "RBRTE",    "daily",    "USD/barrel", TRUE,
  "wti",         "WTI Crude Oil",                   "energy",    "eia",   "petroleum/pri/spt",   "RWTC",     "daily",    "USD/barrel", TRUE,
  "natural_gas", "Henry Hub Natural Gas",           "energy",    "eia",   "natural-gas/pri/fut", "RNGWHHD",  "daily",    "USD/MMBtu",  TRUE,
  "sp500",       "S&P 500",                         "financial", "fred",  NA_character_,          "SP500",    "daily",    "index",      TRUE,
  "usd_index",   "Nominal Broad U.S. Dollar Index", "macro",     "fred",  NA_character_,          "DTWEXBGS", "daily",    "index",      TRUE,
  "fed_funds",   "Federal Funds Effective Rate",    "macro",     "fred",  NA_character_,          "DFF",      "daily",    "percent",    FALSE
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

