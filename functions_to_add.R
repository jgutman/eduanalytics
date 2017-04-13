# add function to package and remove from notebook
interpolate_and_execute <- function(query, conn, commit = FALSE, ...) {
  args <- list(...)
  purrr::map2(names(args), args, assign, envir=environment())
  query %>%
    stringr::str_replace_all("[[:cntrl:]]", "") %>%
    stringr::str_interp() %>%
    RMySQL::dbEscapeStrings(conn, .) %>%
    DBI::dbExecute(conn, .)

    if (commit) DBI::dbCommit(conn) else FALSE
}

# add function to package and remove from notebook
find_tbls_with_col <- function(tbl_list, col_name, conn) {
  tbl_list %>%
    map(function(tbl_name) dbListFields(conn, tbl_name)) %>%
    set_names(tbl_list) %>%
    map_lgl(function(tbl) is_in(col_name, tbl)) %>%
    extract(tbl_list, .)
}

# add function to package and remove from notebook
get_tbl_names_by_stage <- function(conn, id, status) {
  tbl_names <- dbListTables(conn)

  str_interp("^${id}\\W${status}\\W[[:alnum:]]") %>%
    str_detect(tbl_names, .) %>%
    extract(tbl_names, .)
}

get_tbl_suffix <- function(tbl_names) {
  tbl_names %>%
    str_split("\\$", n=3) %>%
    map_chr(tail, n=1L)
}

print_loaded_pkgs <- function() {
  sessionInfo() %>%
  magrittr::use_series(otherPkgs) %>%
  purrr::map_chr(function(pkg) paste(pkg$Package, pkg$Version)) %>%
  cat(sep = "\n")
}
