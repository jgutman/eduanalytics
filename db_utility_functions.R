require(dplyr)

# convert character columns to dates if possible
# leave unchanged if conversion raises warnings
convert_or_retain <- function(col) {
  quietly_parse_time <- purrr::quietly(function(.x) 
    lubridate::parse_date_time(.x, "YmdHMS", 
      tz = "America/New_York", truncated = 3))
  
  col_mutated <- quietly_parse_time(col)
  no_errors <- purrr::is_empty(col_mutated$warnings)
  if (no_errors) col_mutated$result else col
}

# takes as input path to db credentials file
# return database connection object to mysql database
get_mysql_conn <- function(path, credentials_file) {
  credentials <- file.path(path, credentials_file) %>%
    yaml::yaml.load_file()
  
  DBI::dbConnect(RMySQL::MySQL(),
    user = credentials$user,
    password = credentials$password,
    dbname = credentials$dbname,
    host = credentials$host,
    port = credentials$port)
}

# pull down a table from the database into memory 
# and convert dates to appropriate format
put_tbl_to_memory <- function(conn, tbl_name) {
  dplyr::tbl(conn, tbl_name) %>%
    dplyr::collect(n = Inf) %>%
    dplyr::mutate_if(is.character, convert_or_retain)
}

# fix all colnames to standard format across tables
fix_colnames <- function(df_list) {
  df_list %>%
    purrr::map(function(df) purrr::set_names(df, 
        stringr::str_replace_all(colnames(df), " ", "_"))) %>%
    purrr::map(function(df) purrr::set_names(df, 
        tolower(colnames(df))))
}

# severe all active MySQL connections
disconnect_all <- function() {
  purrr::map(DBI::dbListConnections(
    RMySQL::MySQL()), DBI::dbDisconnect)
}

# get list of tables matching regex pattern
get_tbls_by_pattern <- function(conn, pattern) {
  tbl_names <- DBI::dbListTables(conn)
  
   tbl_names %>%
    stringr::str_detect(stringr::regex(pattern, ignore_case = TRUE)) %>%
    magrittr::extract(tbl_names, .) %>%
    purrr::map(function(tbl_name) put_tbl_to_memory(conn, tbl_name))
}

# add schema prefix to list of bare table names
# id: identified/hashed/deidentified
# status: raw/clean/generated
add_tbl_prefix <- function(tbl_names, 
      id = "deidentified", status = "clean") {
  paste(id, status, tbl_names, sep = "$")
}

# read in a text file naming the cols to keep in the dataframes
# may want to change this to work in dictionary-like format
drop_cols_from_list <- function(df_list, col_keep_path) {
  cols_to_keep <- readr::read_lines(col_keep_path)
  purrr::map(df_list, function(df) 
    dplyr::select_(df, .dots = cols_to_keep))
}

# for every row, check if all columns are equal
all_equal_across_row <- function(df) {
  is_single_value <- . %>% 
    purrr::flatten_chr() %>%
    dplyr::n_distinct() %>%
    magrittr::equals(1)
  
  df %>% 
    purrr::by_row(is_single_value, 
          .collate = "rows", .to = "all_cols_match") %>% 
    magrittr::use_series(all_cols_match) %>%
    all()
}

# write a named list of tibbles to the database
write_to_database <- function(df_list, conn) {
  df_list %>%
    purrr::map2(., names(.), function(df, tbl_name)
      write_to_database_single(df, conn, tbl_name)
      )
}

# write single tibble to the database
write_to_database_single <- function(df, conn, tbl_name) {
    RMySQL::dbWriteTable(conn, tbl_name, df,
      # setting types to timestamp seems to be ignored by the DB
      types = data_types_mysql(conn, df),
      row.names = FALSE, overwrite = TRUE)
}

# internal method for write_to_database
# correctly write field types to mysql
data_types_mysql <- function(df, conn) {
  dplyr::db_data_type(conn, df) %>%
    str_replace_all("datetime", "timestamp") %>%
    str_replace_all("(?<=varchar)\\(\\d*\\)", "(255)")
}

deidentify_hashed <- function(conn, tbl_name, ...,
      id = "hashed", status = "raw") {
  
  pattern <- sprintf("^%s\\W%s\\W%s$", 
                     id, status, tbl_name)
  cols_to_drop <- c(...)
  
  conn %>% 
  get_tbls_by_pattern(pattern) %>%
    purrr::flatten_df() %>% 
    dplyr::select(-dplyr::one_of(cols_to_drop))
}

clean_deidentified <- function(conn, tbl_name, ...,
      min_year = 2013, max_year = 2017,
      id = "deidentified", status = "raw") {
  
  pattern <- sprintf("^%s\\W%s\\W%s$", 
                     id, status, tbl_name)
  cols_to_distinct <- c(...)
  
  conn %>%
    get_tbls_by_pattern(pattern) %>%
    purrr::flatten_df() %>%
    dplyr::filter(appl_year >= min_year, appl_year <= max_year) %>%
    dplyr::distinct_(.dots = cols_to_distinct, .keep_all = TRUE)
}