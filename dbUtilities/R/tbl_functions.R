#' convert_or_retain converts column variables to dates where possible
#' otherwise retain original column type
#'
#' @param col column variable
#'
#' @return a date-time variable where possible, otherwise original column type
#'
convert_or_retain <- function(col) {
  quietly_parse_time <- purrr::quietly(function(.x)
    lubridate::parse_date_time(.x, "YmdHMS",
                               tz = "America/New_York", truncated = 3))

  col_mutated <- quietly_parse_time(col)
  no_errors <- purrr::is_empty(col_mutated$warnings)
  if (no_errors) col_mutated$result else col
}


#' put_tbl_to_memory pulls down a table into memory from database and where applies,
#' covert dates to the approprite date format
#'
#' @param conn database connection object
#' @param tbl_name name of table in MySQL database
#'
#' @return a tibble
#'
put_tbl_to_memory <- function(conn, tbl_name) {
  dplyr::tbl(conn, tbl_name) %>%
    dplyr::collect(n = Inf) %>%
    dplyr::mutate_if(is.character, convert_or_retain)
}


#' get tbl_by_pattern returns a list of tibbles into memory from database and where applies,
#' converts dates to the approprite date functions
#'
#' @param conn database connection object
#' @param pattern regular expression pattern for matching with tables names
#'
#' @return a list of tibbles
#' @export
#'
get_tbls_by_pattern <- function(conn, pattern) {
  tbl_names <- DBI::dbListTables(conn)

  tbl_names %>%
    stringr::str_detect(stringr::regex(pattern, ignore_case = TRUE)) %>%
    magrittr::extract(tbl_names, .) %>%
    purrr::map(function(tbl_name) put_tbl_to_memory(conn, tbl_name))
}




#' Add database storing schema to table names
#'
#' @param tbl_names table name
#' @param id identified/hashed/deidentified
#' @param status raw/clean/generated
#'
#' @return a table in database with the apporpriate schemas
#' @export
#'
add_tbl_prefix <- function(tbl_names,
                           id = "deidentified", status = "clean") {
  paste(id, status, tbl_names, sep = "$")
}



#' Function to write a single tibble to database
#'
#' @param df tibble
#' @param conn database connection object
#' @param tbl_name name for table in database
#'
#' @return TRUE if written to database, FALSE otherwise
#' @export
#'
write_to_database_single <- function(df, conn, tbl_name) {
  RMySQL::dbWriteTable(conn, tbl_name, df,
                       # setting types to timestamp seems to be ignored by the DB
                       types = data_types_mysql(conn, df),
                       row.names = FALSE, overwrite = TRUE)
}



#' Function to write a named list of tibbles to database
#'
#' @param df_list a list of tibbles
#' @param conn database connection object
#'
#' @return TRUE if written to database, FALSE otherwise
#' @export
#'
write_to_database <- function(df_list, conn) {
  df_list %>%
    purrr::map2(., names(.), function(df, tbl_name)
      write_to_database_single(df, conn, tbl_name)
    )
}
