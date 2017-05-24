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



# Can't figure out how to specify grouping variable in function call rather than hard coding appl_year in function body 

#' Get correlation matrices by year for a list of tibbles or data frames
#'
#' @param df_list a list of tibbles or data frames
#'
#' @return a list of correlation matrices
#' @export
#'
get_cor_mat_by_year <- function(df_list) {
 
  df_list %>%
    map(., function(df) {
      df %>% 
        split(use_series(., appl_year)) %>% 
        lapply(select, -appl_year) %>%
        lapply(get_cor_mat_single)
    } 
  )
}



# slightly faster but doesn't maintain variable labels 
# tbl %>%
#   map(.,function(df) {
#     df %>% 
#       group_by(appl_year) %>% 
#       nest() %>%
#       mutate(var = map(data, get_cor_mat_single))
#   }) %>%
#   map(., "var", extract) 
#
#
# or could use this plyr implementation
# tbl %>%
#   map(., function(df) {
#     df %>%
#       plyr::dlply(.(appl_year), get_cor_mat_single)
#   }
# )








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
#' @return a list containing summary statistics for each variable
#' @export
#'
get_basic_summaries_single <- function(dat, varname, data_type = is.numeric, digits = 2) {
  
  quo_group_by <- enquo(varname)
  
  num_dat <- dat %>% select_if(data_type)
  
  # making sure the grouping variable (probably appl_year) is included
  # necessary when grouping variable is a different class than vars to summarize
  group_var <- dat %>% select(!!quo_group_by)
  if (names(group_var) %in% names(num_dat)==FALSE) {
    num_dat %<>% bind_cols(group_var, num_dat)
  }
  
  # makes sure grouping var is first the first column in the dataframe
  num_dat %<>% select(!!quo_group_by, everything()) 
  
  summstats <- list()
  
  tryCatch( 
    
    {for (i in 2:ncol(num_dat)) {
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
  
    } , error = function(x) print("There are no variables of specified data type in data frame")
  )
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
  
  df_list %>% 
    map(., function(df) {
      df %>% get_basic_summaries_single(varname = !!quo_group_by, data_type = data_type, digits = digits) 
    } )
}


