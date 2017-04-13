# add function to package and remove from notebook
interpolate_and_execute <- function(query, conn, ...) {
  args <- list(...)
  purrr::map2(names(args), args, assign, envir=environment())
  query %>%
    stringr::str_replace_all("[[:cntrl:]]", "") %>%
    stringr::str_interp() %>%
    RMySQL::dbEscapeStrings(conn, .) %>%
    DBI::dbExecute(conn, .)
}

# add function to package and remove from notebook
find_tbls_with_col <- function(tbl_list, col_name, conn) {
  tbl_list %>%
    map(function(tbl_name) dbListFields(conn, tbl_name)) %>%
    set_names(tbl_list) %>%
    map_lgl(function(tbl) is_in(col_name, tbl)) %>%
    extract(tbl_list, .)
}
