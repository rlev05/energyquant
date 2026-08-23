source("R/config.R")
source("R/database.R")

config <- load_config()

connection <- connect_database(
  config$database_path
)

result <- DBI::dbGetQuery(
  connection,
  "SELECT 'EnergyQuant ready' AS status"
)

print(result)

disconnect_database(connection)