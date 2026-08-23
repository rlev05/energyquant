library(dotenv)

load_config <- function() {
  if (file.exists(".env")) {
    dotenv::load_dot_env(".env")
  }

  list(
    eia_api_key = Sys.getenv(
      "EIA_API_KEY"
    ),
    fred_api_key = Sys.getenv(
      "FRED_API_KEY"
    ),
    database_path = Sys.getenv(
      "ENERGYQUANT_DB_PATH",
      unset = "data/energyquant.duckdb"
    )
  )
}