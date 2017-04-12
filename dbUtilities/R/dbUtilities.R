#' dbUtilities: a package to organize a data science pipeline with a mySQL research database
#'
#' @section database connection functions:
#' Functions for connecting and disconnecting from the database
#'
#' @section ETL and cleaning functions:
#' Functions for reading and writing to the database
#'
#' @docType package
#' @name dbUtilities
#'
#' @importFrom DBI dbConnect
#' @importFrom DBI dbListConnections
#' @importFrom DBI dbDisconnect
#' @importFrom DBI dbListTables
#' @importFrom DBI dbWriteTable
#' @importFrom purrr map
#' @importFrom purrr quietly
#' @importFrom purrr is_empty
#' @importFrom purrr map2
#' @importFrom purrr flatten_df
#' @importFrom purrr set_names
#' @importFrom purrr flatten_chr
#' @importFrom purrr by_row
#' @importFrom purrr map_lgl
#' @importFrom lubridate parse_date_time
#' @importFrom RMySQL MySQL
#' @importFrom magrittr %>%
#' @importFrom magrittr extract
#' @importFrom magrittr equals
#' @importFrom magrittr use_series
#' @importFrom magrittr is_less_than
#' @importFrom magrittr not
#' @import dplyr
#' @importFrom stringr str_detect
#' @importFrom stringr str_extract
#' @importFrom stringr regex
#' @importFrom stringr str_replace_all
#' @importFrom readr write_csv
#'
NULL
