ensure_observations_table <- function(connection) {
  DBI::dbExecute(
    connection,
    "
        CREATE TABLE IF NOT EXISTS market_observations (
      series_key VARCHAR NOT NULL,
      source VARCHAR NOT NULL,
      source_id VARCHAR NOT NULL,
      date DATE NOT NULL,
      value DOUBLE NOT NULL,
      unit VARCHAR NOT NULL,
      frequency VARCHAR NOT NULL,
      ingested_at TIMESTAMP NOT NULL,
      PRIMARY KEY (series_key, date)
    )
    "
  )

  invisible(TRUE)
}

upsert_observations <- function(
connection,
observations
) {
  if (nrow(observations) == 0) {
    return(
      invisible(0L)
    )
  }

  ensure_observations_table(connection)

  DBI::dbWriteTable(
    connection,
    "incoming_observations",
    observations,
    temporary = TRUE,
    overwrite = TRUE
  )

  rows_written <- DBI::dbExecute(
    connection,
    "
    INSERT into market_observations (
    series_key,
    source,
    source_id,
    date,
    value,
    unit,
    frequency,
    ingested_at
    )
    SELECT
    series_key,
      source,
      source_id,
      date,
      value,
      unit,
      frequency,
      ingested_at
    FROM incoming_observations
    ON CONFLICT (series_key, date)
    DO UPDATE SET
      source = EXCLUDED.source,
      source_id = EXCLUDED.source_id,
      value = EXCLUDED.value,
      unit = EXCLUDED.unit,
      frequency = EXCLUDED.frequency,
      ingested_at = EXCLUDED.ingested_at
    "
  )

  DBI::dbRemoveTable(
    connection,
    "incoming_observations"
  )

  invisible(rows_written)
}

get_observations <- function(
  connection,
  series_key = NULL
) {
  ensure_observations_table(connection)

  if (is.null(series_key)) {
    return(
      DBI::dbGetQuery(
        connection,
        "
        SELECT *
        FROM market_observations
        ORDER BY series_key, date
        "
      ) |>
        tibble::as_tibble()
    )
  }

  DBI::dbGetQuery(
    connection,
    "
    SELECT *
    FROM market_observations
    WHERE series_key = ?
    ORDER BY date
    ",
    params = list(series_key)
  ) |>
    tibble::as_tibble()
}