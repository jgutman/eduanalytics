get_binary <- function(df) {
  df %>%
    summarise_all(funs(n_distinct(., na.rm = FALSE))) %>%
    t() %>% as.data.frame() %>%
    rownames_to_column("col_name") %>%
    filter(V1 == 2) %>%
    use_series(col_name)
}

get_binary_cols <- function(df) {
  df %>%
    get_binary() %>%
    {select(df, study_id, appl_year, one_of(.))}
}

recode_Y_indicator <- function(df) {
    # not written yet
}
