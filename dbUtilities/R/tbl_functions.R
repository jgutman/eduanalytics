#FUNCTIONS FOR GETTING DATA FROM DATABASE

#helper function

#' convert_or_retain converts column variables to dates where possible
#' otherwise retain original column type
#'
#' @param col column variable
#'
#' @return a date-time variable where possible, otherwise original column type
#'
convert_or_retain <- function(col) {
  quietly_parse_time <- quietly(function(.x)
    parse_date_time(.x, "YmdHMS",
              tz = "America/New_York", truncated = 3))
  col_mutated <- quietly_parse_time(col)
  no_errors <- is_empty(col_mutated$warnings)
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
  tbl(conn, tbl_name) %>%
    collect(n = Inf) %>%
    mutate_if(is.character, convert_or_retain)
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
  tbl_names <- dbListTables(conn)

  tbl_names %>%
    str_detect(regex(pattern, ignore_case = TRUE)) %>%
    extract(tbl_names, .) %>%
    map(function(tbl_name) put_tbl_to_memory(conn, tbl_name))
}


#FUNCTIONS FOR WRITING DATA TO DATABASE

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
  dbWriteTable(conn, tbl_name, df,
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
    map2(., names(.), function(df, tbl_name)
      write_to_database_single(df, conn, tbl_name)
    )
}


#' Function to build a de-identified table from a hashed table in database.
#' It takes a database connection and strings to find table matching pattern `{id}${status}${tbl_name}` and
#' characters list conatining names of fields to be dropped and returns a deidentified table
#'
#' @param conn database connection
#' @param tbl_name table name in database
#' @param ... variables names to be dropped
#' @param id table id from database schema
#' @param status table status from database schema
#'
#' @return a deidentified dataset that can be written to the table
#'
#' @export
deidentify_hashed <- function(conn, tbl_name, ...,
                              id = "hashed", status = "raw") {

  pattern <- sprintf("^%s\\W%s\\W%s$",
                     id, status, tbl_name)
  cols_to_drop <- as.character(c(...))

  conn %>%
    get_tbls_by_pattern(pattern) %>%
    flatten_df() %>%
    select(-one_of(cols_to_drop))
}



#' Function to create a clean table from raw table in database. It takes a database connection,
#' strings to find matching pattern `{id}${status}${tbl_name}`, range of years to filter applicantions by,
#' and using the first application for each applicant.
#'
#' @param conn database connection object
#' @param tbl_name table name, shold be deidentified
#' @param min_year minimum application year
#' @param max_year maximum application year
#' @param id table id from database schema
#' @param status table status from database schema
#'
#' @return a clean deidentified table for analysis
#' @export
#'
clean_deidentified <- function(conn, tbl_name,
                               min_year = 2014, max_year = 2017,
                               id = "deidentified", status = "raw") {

  pattern <- sprintf("^%s\\W%s\\W%s$", id, status, tbl_name)

  conn %>%
    get_tbls_by_pattern(pattern) %>%
    flatten_df() %>%
    filter(appl_year >= min_year, appl_year <= max_year) %>%
    group_by(study_id) %>%
    filter(appl_year == min(appl_year))
}



#FUNCTIONS FOR MANAGING DATA AFTER GETTING FROM DATABASE

#' Fix all column names to standard format across tibbles
#'
#' @param df_list list of tibbles
#'
#' @return a list of tibles with formatted column names
#' @export
#'
fix_colnames <- function(df_list) {
  df_list %>%
    map(function(df) set_names(df,
                      str_replace_all(colnames(df), " ", "_"))) %>%
    map(function(df) set_names(df,
                      tolower(colnames(df))))
}



#' When the same data is stored in multiple tables/tibbles and you want to merge them together
#' use this function to check if COLUMN NAMES and COLUMN TYPES match
#'
#' @param df a data frame, can contain columns names across a list of tibbles or column types across a list of tibbles
#'
#' @return TRUE if column names or column types match, depends on what is being tested
#' @export
all_equal_across_row <- function(df) {
  is_single_value <- . %>%
    flatten_chr() %>%
    n_distinct() %>%
    equals(1)

  df %>%
    by_row(is_single_value,
                  .collate = "rows", .to = "all_cols_match") %>%
    use_series(all_cols_match) %>%
    all()
}



#Drop column functions for tibbles

#' Read in from a textfile with names for columns to keep in tibbles
#'
#' @param df_list list of tibbles
#' @param col_keep_path name of file with columns to keep
#'
#' @return a list of tibbles with formatted column names
#' @export
#'
keep_cols_from_list <- function(df_list, col_keep_path) {
  cols_to_keep <- readr::read_lines(col_keep_path)

  map(df_list, function(df)
     select_(df, .dots = cols_to_keep))
}


#' Drop columns in tibbles that have only NA values
#'
#' @param df a tibble to check of NA in columns
#'
#' @return a tibble with only non-empty columnn
#' @export
drop_empty_cols <- function(df) {
  # Return true if a column is non-empty
  # Return false if a column contains NAs
  non_empty <- . %>%
    is.na() %>%
    mean() %>%
    is_less_than(1)

  df %>%
    select_if(non_empty)
}



#misc functions

#' Write data to local machine or share drive
#'
#' @param df tibble
#' @param path path to directory where file will be saved
#' @param filename filename
#' @export
write_to_file <- function(df, path, filename) {
  full_path <- file.path(path, filename)
  write_csv(df, full_path)
}

