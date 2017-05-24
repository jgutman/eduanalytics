## FUNCTIONS EXPLORING MISSINGNESS


#' Function to create a matrix with the percent of observations missing in each variable 
#' in a data frame or tibble grouped by another variable (generally appl_year)
#'
#' @param dat tibble or data frame 
#' @param varname grouping variable
#' @param round_digits number of digits for rounding
#'
#' @return a matrix 
#' @export
#'
pct_miss_table_single <- function(dat, varname, round_digits = 1) {
  
  quo_group_by <- enquo(varname)
  colname <- dat %>% select(!!quo_group_by) %>% colnames()
  
  dat %>%
    group_by(!!quo_group_by) %>%
    summarize_all(funs(mean(is.na(.)))) %>%
    column_to_rownames(colname) %>%
    t() %>% multiply_by(100) %>% round(round_digits)
}



#' Function to create a matrix with the percent of observations missing in each variable 
#' in a list of data frames or tibbles grouped by another variable (generally appl_year)
#'
#' @param tbl_list list of tibbles or data frames 
#' @param varname grouping variable
#' @param round number of digits for rounding
#'
#' @return a list of matrices
#' @export
#'
pct_miss_table <- function(df_list, varname, round_digits = 1) {
  
  quo_group_by <- enquo(varname)

  df_list %>% 
    map(., function(df) 
      df %>% pct_miss_table_single(varname = !!quo_group_by) 
  )
}




## VISUALIZATION FUNCTIONS 

#' Function to create an aggr object for a single tibble or data frame
#'
#' @param dat tibble or data frame
#' @param plot a logical indicating whether hte reslts should be plotted
#'
#' @return an aggr object. if plot=T plots missingness patterns and barplot of missingness proportions.
#' @export 
#'
explore_missingness_single <- function(dat, plot = TRUE) {
  
  miss_obj <- aggr(dat, bars = FALSE, sortVars = TRUE, numbers = TRUE, plot = plot, cex.axis=.8)
  #summary(miss_obj)
  
}



#' Function to create a list of aggr objects from a list of tibbles
#'
#' @param df_list a list of tibbles or data frames
#' @param plot a logical indicating whether the results should be plotted. if 
#' plot = TRUE, plots missing proportions and patterns and prints
#' proportions of missings in each var for each tibble in list. if plot = FALSE outputs 
#' only the number of observations missing for each variable. if plot = FALSE and output 
#' is saved to an object, nothing automaitcally prints 
#'
#' @return a list of aggr objects
#' @export
#'
explore_missingness <- function(df_list, plot = TRUE) {
  
  df_list %>% 
    map(., function(df)
      explore_missingness_single(df, plot = plot))
}




## COMPLETE CASES FUNCTIONS ##

#' Function to get the proportion of oberservations with complete data in a tibble
#'
#' @param dat a tibble or data frame
#' @varname an optional grouping variable 
#'
#' @return a data frame. if varname is not specified data frame contains 1 observation. otherwise a two
#' column data frame is returned. 
#' @export. 
#'
get_complete_cases_single <- function(dat, varname) {
  
  quo_group_by <- enquo(varname)
  
  dat %>% group_by(!!quo_group_by) %>%
    summarize(pct_complete = sum(complete.cases(.)/n() * 100)) %>%
    as.data.frame() 
}



# proportion of complete cases by year

#' Function to get the proportion of complete observations for each tibble in a
#' list of tibbles or data frames
#'
#' @param df_list a list of tibbles or data frames
#' @param varname an optional grouping variable
#'
#' @return a list of data frames
#' @export
#'
get_complete_cases <- function(df_list, varname) {
  
  quo_group_by <- enquo(varname)
  #print(quo_group_by)
  
  df_list %>% 
    map(., function(df)
      df %>%
        group_by(!!quo_group_by) %>%
        summarize(pct_complete = sum(complete.cases(.)/n())) %>%
        as.data.frame
    )
}


