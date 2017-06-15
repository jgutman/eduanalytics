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


#' Recodes Y/N/NA vars to 1/0/NA and converts to numeric for a single tibble/data frame
#'
#' @param df a data frame or tibble
#'
#' @return a tibble or data frame containing only recoded columns
#' @export
#'
recode_yesno_single <- function(df) {
  yesno_df <- df %>%
    select(one_of(get_yesno(.)))  %>%
    mutate_all(funs(recode(., Y = "1", N="0"))) %>%
    mutate_all(funs(as.numeric))
  other_cols <- df %>% select(-one_of(get_yesno(.)))
  bind_cols(other_cols, yesno_df)
}



#' Recodes Y/N/NA vars to 1/0/NA and converts to numeric for a list of tibbles
#'
#' @param df_list a list of tibbles or data frames
#'
#' @return A list of tibbles with Yes/No variables recoded to 1/0
#' @export
#'
recode_yesno <- function(df_list) {
  lapply(df_list, recode_yesno_single)
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



#' Get the binary numeric columns in a data frame plus appl_year and study_id
#'
#' @param df a data frame or tibble
#'
#' @return tibble containing binary numeric variables
#' @export
#'
get_binary_num_cols <- function(df) {
  df %>%
    get_binary() %>%
    {select(df, study_id, appl_year, one_of(.))} %>%
    select_if(is.numeric)
}



## Functions to better display dates


#' Removes time stamp from date variables in a data frame or tibble for better readability
#'
#' @param df a tibble or data frame
#'
#' @return a tibble with date variables in %m-%d-%y format
#' @export
#'
format_dates_single <- function(df) {
  df %>%
    mutate_if(is.POSIXct, funs(format(as.POSIXct(., tz = "America/New_York", "%m-%d-%y"))))
}



#' Removes time stamp from date variables in a list of tibbles or data frame for better readability
#'
#' @param df_list a list of tibbles or data frames
#'
#' @return a list of tibbles with date variables in %m-%d-%y format
#' @export
format_dates <- function(df_list) {
  df_list %>%
    map(., function(df)
      df %>% format_dates_single()
    )
}




## Functions for displaying variable type


#' Prints a table containing the class of all variables in the data set along
#' with whether the variable is binary or not. In this case, binary means that
#' there are at most two distinct values for the variable, ignoring NA.
#'
#' @param df a data frame or tibble
#'
#' @return a data frame with two columns
#' @export
#'
get_var_types_single <- function(df) {
  classes <- lapply(df, class)
  classes <- as.data.frame(sapply(classes, function(x) x[1]))
  ndistinct <- df %>% summarize_all(n_distinct) %>% t() %>% as.data.frame()
  binary <- (ndistinct<=2) + 0
  classes <- cbind(classes, binary)
  colnames(classes) <- c("Variable Type", "Binary")
  return(classes)
}



#' Gets variable type information for each tibble in a list of tibbles
#'
#' @param df_list a list of data frames or tibbles
#'
#' @return a list of data frames, each containing two columns
#' @export
get_var_types <- function(df_list) {
  lapply(df_list, get_var_types_single)
}




