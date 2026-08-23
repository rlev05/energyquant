source("R/market_series.R")

cat("EnergyQuant market universe:\n\n")

print(
  get_market_series()
)

cat("\nEIA series:\n\n")

print(
  get_series_by_source("eia")
)

cat("\nFRED series:\n\n")

print(
  get_series_by_source("fred")
)

