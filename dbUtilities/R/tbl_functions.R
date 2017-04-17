#BUILDING AND EXECUTING SQL QUERIES

#' Build and execute SQL query
#'
#' @param query SQL query
#' @param conn database connection object
#' @param commit Boolean value, TRUE to explicitly write to database FALSE to not
#' @param ... Additional paramaters, for passing in skeleton query for SQL query above
#'
#' @return Executed SQL query on the datbase, changes the databse in commit is TRUE
#' @export
#'
interpolate_and_execute <- function(query, conn, commit = FALSE, ...) {

  args <- list(...)

  map2(names(args), args, assign, envir=environment())

  query %>%
    str_replace_all("[[:cntrl:]]", "") %>%
    str_interp() %>%
    dbEscapeStrings(conn, .) %>%
    dbExecute(conn, .)

  if (commit) dbCommit(conn) else FALSE
}




#FUNCTIONS FOR GETTING DATA FROM DATABASE

# Helper function to parse dates

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
#' covert dates to the appropriate date format
#'
#' @param conn database connection object
#' @param tbl_name name of table in MySQL database
#'
#' @return a tibble
#'
#'@export
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
#' @param in_memory if true, put tbl_df in memory, if false, lazy evaluation
#'
#' @return a list of tibbles, either in memory or lazily evaluated
#' @export
#'
get_tbls_by_pattern <- function(conn, pattern, in_memory = TRUE) {
  tbl_names <- dbListTables(conn)
  f <- if(in_memory) put_tbl_to_memory else dplyr::tbl

  get_tbls_by_pattern <- function(conn, pattern, in_memory = TRUE) {

  tbl_names <- dbListTables(conn)

  f <- if(in_memory) put_tbl_to_memory else dplyr::tbl

  names <- tbl_names %>%
    str_detect(regex(pattern, ignore.case = TRUE)) %>%
    extract(tbl_names, .)

  names %>%
    map(function(tbl_name) f(conn, tbl_name)) %>%
    set_names(get_tbl_suffix(names))
}



#'Find tibble with specified column name
#'
#' @param tbl_list a list of table names
#' @param col_name column name in tibble
#' @param conn database connection object
#'
#' @return return table that contain the specified table name
#' @export
#'
find_tbls_with_col <- function(tbl_list, col_name, conn) {
  tbl_list %>%
    map(function(tbl_name) dbListFields(conn, tbl_name)) %>%
    set_names(tbl_list) %>%
    map_lgl(function(tbl) is_in(col_name, tbl)) %>%
    extract(tbl_list, .)
}




#' Get tibble name by stage and status
#'
#' @param conn database connection object
#' @param id id from database naming schema
#' @param status status from database naming schema
#'
#' @return a list of tibble that matches id and staus
#' @export
#'
get_tbl_names_by_stage <- function(conn, id, status) {
  tbl_names <- dbListTables(conn)

  str_interp("^${id}\\W${status}\\W[[:alnum:]]") %>%
    str_detect(tbl_names, .) %>%
    extract(tbl_names, .)
}





### FUNCTIONS FOR WRITING DATA TO DATABASE

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



### FUNCTIONS FOR MANAGING DATA AFTER GETTING FROM DATABASE

#' Helper function to prase_yaml_cols, either drops for keeps columns based on input from a yaml file
#'
#' @param df_list a list of tibbles
#' @param cols_list a list of length one containing many column names
#'
#' @return
#'
select_by_keyword <- function(df_list, cols_list) {

  drop <- function(df, cols) {select(df, -one_of(cols))}
  keep <- function(df, cols) {select(df, one_of(cols))}

  stopifnot(length(cols_list) == 1)

  f <- if (names(cols_list ) == "keep") {keep
  } else if (names(cols_list) == "drop") {drop
      } else {function(...) NULL}

  f(df, flatten_chr(cols_list))

}


#' Get the suffix of tibble names
#'
#' @param tbl_names names of tiblles
#'
#' @return return suffix of tibble names
#' @export
#'
get_tbl_suffix <- function(tbl_names) {
  tbl_names %>%
    str_split("\\$", n=3) %>%
    map_chr(tail, n=1L)
}


#' For a list of tibbles, either keep or drop columns based on input from a yaml file
#'
#' @param df_list a list of tibbles
#' @param col_list_path path to yaml file
#'
#' @return a list of tibbles only with selected columns based on imput from yaml files
#' @export
#'
parse_yaml_cols <- function(df_list, col_list_path) {

  cols_dict <- yaml::yaml.load_file(col_list_path)

  df_list %>%
    names() %>%
    get_tbl_suffix() %>%
    stringr::str_extract("[[:alpha:]]+(.?[[:alpha:]])*") %>%
    extract(cols_dict, .) -> cols_dict

  map2(df_list, cols_dict, select_by_keyword)
}



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


### Output data functions

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
