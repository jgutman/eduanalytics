#' get_mysql_connection takes the input path to database credentials file stored in secure location
#' and returns database connection object to mysql database.
#'
#' @param path path to credentials file
#' @param credentials_file the name of the credentials file
#' @param group client group - eud_db_owner, edu_db_read, edu_db_write
#'
#' @return MySQL connection object
#' @export
#'
get_mysql_conn <- function(path = "~", credentials_file = ".my.cnf",
                           group = "rs-dbi") {
  credentials <- file.path(path, credentials_file)

  dbConnect(MySQL(),
                 group = group, default.file = credentials)
}


#' Severe all active MySQL connection
#'
#' @return a logical list for each database connection that's severed
#' @export
disconnect_all <- function() {
  map(dbListConnections(
    MySQL()), dbDisconnect)
}
