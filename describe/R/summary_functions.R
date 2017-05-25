## CORRELATION FUNCTIONS 

#' Get correlation matrix for numeric variables in a data frame or tibble
#'
#' @param dat a data frame or tibble
#' @param use a character string giving a method for computing covariances in the presence of missing values
#' @param round_digits number of digits used for rounding correlation matrix
#'
#' @return correlation matrix for a single tibble
#' @export
#'
get_cor_mat_single <- function(dat, use = 'pairwise.complete.obs', round_digits = 3) {
  
  dat %>% 
    select_if(is.numeric) %>% 
    cor(., use = use) %>%
    round(round_digits)
}


#' Function to get correlation matrices for all numeric variables in a list of tibbles (or data frames)
#'
#' @param df_list a list of tibbles or data frames
#' @param use can be any of the character strings from the use argument in cor function
#' @param round_digits number of digits used for rounding correlation matrices
#'
#' @return a list of correlation matrices
#' @export
#'
get_cor_mat <- function(df_list, use = 'pairwise.complete.obs', round_digits = 3) {
  
  df_list %>% 
    map(., function(df)
      get_cor_mat_single(df, use = use, round=round_digits))
  
}



#' Get correlation matrices by year for a list of tibbles or data frames
#'
#' @param df_list a list of tibbles or data frames
#'
#' @return a list of correlation matrices
#' @export
#'
get_cor_mat_by_year <- function(df_list, varname) {

  quo_group_by <- enquo(varname)
  
  df_list %>%
    map(., function(df) {
      group_var <- df %>% select(!!quo_group_by) %>% pull()
      
      df %>% 
        split(group_var) %>% 
        lapply(select, -!!quo_group_by) %>%
        lapply(get_cor_mat_single)
    } 
  )
}





## SUMMARY STATISTIC FUNCTIONS FOR NUMERIC AND DATE VARIABLES

#' Helper function to return the first quartile within summarize functions
#'
#' @param a_vec 
#' @param ... other arguments passed to quantile function
#'
#' @return value or first quartile
#' 
twentyfive_quantile <- function(a_vec,...) {
  unname(quantile(a_vec, .25, ...))
}


#' Helper function to return the third quartile within summarize functions
#'
#' @param a_vec 
#' @param ... 
#'
#' @return value of third quartile
#'
seventyfive_quantile <- function(a_vec,...) {
  unname(quantile(a_vec, .75, ...))
}



#' Function to easily summarize numeric or date variables in a tibble or dataframe 
#' grouped by another variable (generally application year)  
#'
#' @param dat a tibble or data frame
#' @param varname variable to group by (generally appl_year)
#' @param data_type class of variables to summarize. should be is.numeric or is.POSIXct
#'
#' @return a list containing summary statistics for each variable stored in a df
#' @export
#'
get_basic_summaries_single <- function(dat, varname, data_type = is.numeric, digits = 3) {
  
  quo_group_by <- enquo(varname)
  
  num_dat <- dat %>% select_if(data_type)
  
  if (ncol(num_dat)==0) return("There are no variables of specified data type.")
  
  else {
    # make sure the grouping variable (probably appl_year) is included
    # necessary when grouping variable is a different class than vars to summarize
    group_var <- dat %>% select(!!quo_group_by)
    if (names(group_var) %in% names(num_dat)==FALSE) {
      num_dat %<>% bind_cols(group_var, num_dat)
    }
  
    # make sure grouping var is first the first column in the dataframe
    num_dat %<>% select(!!quo_group_by, everything()) 
    
    # empty list for summary statistics
    summstats <- list()
  
    for (i in 2:ncol(num_dat)) {
      summstats[[i-1]] <- num_dat %>% 
        group_by(!!quo_group_by) %>% 
        extract(c(1,i)) %>% 
        summarise_all(funs(min, twentyfive_quantile, median, mean, 
                           seventyfive_quantile, max, sd), na.rm = TRUE) %>%
        as.data.frame() %>%
        round(digits)
    }
    names(summstats) <- names(num_dat[-1])
    return(summstats)
  }
}



#' Function to get summary statistics for numeric or date variables from a list of tibbles or
#' data frames
#'
#' @param df_list a list of tibbles or data frame
#' @param varname grouping variables (generally appl_year)
#'
#' @return a list of lists each consisting of a data frame of summary statistics
#' @export
#'
get_basic_summaries <- function(df_list, varname, data_type = is.numeric, digits = 2) {
  
  quo_group_by <- enquo(varname)
  
  lapply(df_list, get_basic_summaries_single, varname = !!quo_group_by, data_type = data_type, digits = digits)
}