library(DBI)
library(duckdb)

connect_database <- function(
  database_path
) {
  DBI::dbConnect(
    duckdb::duckdb(
      shared_home = FALSE
    ),
    dbdir = database_path
  )
}

disconnect_database <- function(
  connection
) {
  DBI::dbDisconnect(
    connection,
    shutdown = TRUE
  )
}