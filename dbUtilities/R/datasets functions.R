#' convert_or_retain converts column variables to dates where possible
#' otherwise retain original column type
#'
#' @param col column variable
#'
#' @return a date-time variable where possible, otherwise original column type
#' @export
convert_or_retain <- function(col) {
  quietly_parse_time <- purrr::quietly(function(.x)
    lubridate::parse_date_time(.x, "YmdHMS",
                               tz = "America/New_York", truncated = 3))

  col_mutated <- quietly_parse_time(col)
  no_errors <- purrr::is_empty(col_mutated$warnings)
  if (no_errors) col_mutated$result else col
}


