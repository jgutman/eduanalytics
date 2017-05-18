## VARIABLE TYPE FUNCTIONS 


#' Get names of columns that only have Yes, No, or NA responses 
#'
#' @param dat a data frame or tibble 
#'
#' @return character vector containing column names
#' @export
#'
get_yesno <- function(dat) {
  dat %>% 
    sapply(., function(x) { all(x %in% c("Y", "N", NA)) }) %>%
    {names(dat[.])}
}


#' Recodes Y/N/NA vars to 1/0/NA and converts to numeric
#'
#' @param df a data frame or tibble
#'
#' @return a tibble or data frame containing only recoded columns
#' @export
#'
recode_yesno <- function(df) {
  yesno_df <- df %>%
    select(one_of(get_yesno(.)))  %>%
    mutate_all(funs(recode(., Y = "1", N="0"))) %>%
    mutate_all(funs(as.numeric)) 
  other_cols <- df %>% select(-one_of(get_yesno(.)))
  bind_cols(other_cols, yesno_df)
}



#' Get names of columns that are binary (have two distinct values, excluding NAs) for a data frame
#'
#' @param df a data frame or tibble
#'
#' @return a character vector containing column names
#' @export
#'
get_binary <- function(df) {
  df %>% 
    summarise_all(funs(n_distinct(., na.rm=TRUE))) %>% 
    t() %>% as.data.frame() %>% 
    rownames_to_column("col_name") %>% 
    filter(V1 <= 2) %>%   
    use_series(col_name)
}


#' Get the binary columns in a data frame plus appl_year and study_id 
#'
#' @param df a data frame or tibble 
#'
#' @return tibble containing binary variables
#' @export 
#'
get_binary_cols <- function(df) {
  df %>%
    get_binary() %>%
    {select(df, study_id, appl_year, one_of(.))}
} 


