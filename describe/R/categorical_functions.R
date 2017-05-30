## CATEGORICAL VARIABLE FUNCTIONS 

#' Function to get the number of categories for each categorical variable in a tibble or data frame
#'
#' @param dat a tibble or data frame
#' @param varname an optional grouping variable (generally appl_year)
#'
#' @return a tibble with number of distinct categories in each categorical variable
#' @export
#'
get_ndistinct_single <- function(dat, varname) {
  
  quo_group_by <- enquo(varname)
  #print(quo_group_by)
  
  dat %>% 
    group_by(!!quo_group_by) %>% 
    summarise_if(., is.character, funs(n_distinct(., na.rm = TRUE)))
}


#' Function to get the number of distinct categories for each categorical variable in a list of tibbles or data frames
#'
#' @param df_list a list of tibbles or data frames
#' @param varname an optional grouping variable (generally appl_year)
#'
#' @return a list of tibbles containing the number of distinct categories for each categorical variable
#'  within each tibble from df_list
#' @export
#'
get_ndistinct <- function(df_list, varname) {
  
  quo_group_by <- enquo(varname)
  
  df_list %>% 
    map(., function(df) {
      get_ndistinct_single(df, varname = !!quo_group_by)
    } )
}




#' Helper function for get_cat_tables_single to get a list of tables for all categorical variables
#'
#' @param dat a tibble or dataframe
#' @param varname grouping variable (generally appl_year)
#' @param digits number of digits for rounding proportions 
#'
#' @return a list of tables each containing the proportion of observations in each category grouped
#'  by the grouping variable
#'
initialize_cat_tables <- function(dat, varname, digits = 3) {
  
  quo_group_by <- enquo(varname)
  #print(quo_group_by)
  
  group_var <- dat %>% select(!!quo_group_by) %>% pull()
  
  table_list <- dat %>% 
    select_if(is.character) %>%
    apply(2, table, group_var, useNA = "ifany") %>% 
    lapply(t)
  
  table_list <- map(table_list, function(x) 
    round(prop.table(x, margin = 1), digits)
  )
  
  return(table_list)
}



#' Displays a table showing the proportion of observations in the N largest categories for each categorical variable in 
#' a tibble or data frame
#' 
#' @param dat tibble or data frame
#' @param varname grouping variable (generally appl_year)
#' @param digits number of digits for rounding the tables. default is 3.
#' @param n number of distinct categories to dispaly. default is 10. 
#'
#' @return a list of tables 
#' @export
#'
get_cat_tables_single <- function(dat, varname, digits = 3, n = 10) {
  
  quo_group_by <- enquo(varname)
  table_list <- initialize_cat_tables(dat, !!quo_group_by, digits = digits)
  
  names <- names(table_list) 
  
  table_list <- lapply(names, function(x) {
    many_cats <- ncol(table_list[[x]]) > n
    if (many_cats) {
      new_table <- sort(table(dat[[x]]), decreasing=TRUE)[1:n]
      table_list[[x]] <- table_list[[x]][,names(new_table)]
    } else {
      table_list[[x]] <- table_list[[x]]
    }
  })
  
  names(table_list) <- names
  return(table_list)   
}




#' Displays a table showing the proportion of observations in the N largest 
#' categories for each categorical variable in a list of tibbles or data frames
#'
#' @param df_list a list of tibbles or data frames
#' @param varname grouping variable (generally appl_year)
#' @param digits number of digits for rounding tables
#'
#' @return a list of lists, each containing a table
#' @export
#' 
get_cat_tables <- function(df_list, varname, digits = 3, n = 10) {
  
  quo_group_by <- enquo(varname)
  
  df_list %>% 
    map(., function(df) {
      get_cat_tables_single(df, varname = !!quo_group_by, digits = digits, n = n)
    } 
    )
  
}

