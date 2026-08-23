ensure_directory <- function(path) {
  if (!dir.exists(path)) {
    dir.create(
      path,
      recursive = TRUE
    )
  }

  invisible(path)
}

utc_now <- function() {
  as.POSIXct(
    Sys.time(),
    tz = "UTC"
  )
}