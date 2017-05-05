## Descriptive Analysis functions


#####################################
## FUNCTIONS EXPLORING MISSINGNESS ##
#####################################

# creates a matrix of the percent of missingness in each variable in a dataframe
# grouped by another variable (generally appl_year)
# takes in a data frame or tibbe and grouping variable, returns a matrix 
pct_miss_table <- function(dat, varname, round=2) {
  
  quo_group_by <- enquo(varname)
  colname <- dat %>% select(!!quo_group_by) %>% colnames()
  
  dat %>%
    group_by(!!quo_group_by) %>%
    summarize_all(funs(pct_missing = mean(is.na(.)))) %>%
    column_to_rownames(colname) %>%
    t() %>% multiply_by(100) %>% round(round)
}



## VISUALIZATION FUNCTIONS ## 

# creates an aggr object for a single tibble
# if plot = TRUE, plots missingness proportions and patterns
explore_missingness_single <- function(dat, plot = TRUE) {
  
  miss_obj <- aggr(dat, bars = FALSE, sortVars = TRUE, numbers = TRUE, plot = plot, cex.axis=.8)
  #summary(miss_obj)
  
}


# creates a list of aggr objects for a list of tibbles
# if plot = TRUE, plots missing proportions and patterns and outputs 
# proportions of missings in each var for each tibble in list
# if plot = FALSE outputs only the number of observations missing for each
# variable
# if plot = FALSE and output is saved to an object, nothing automaitcally prints 
explore_missingness <- function(df_list, plot = TRUE) {
  
  df_list %>% 
    map(., function(df)
      explore_missingness_single(df, plot = plot))
}


## COMPLETE CASES FUNCTIONS ##

# proportion of complete cases in a single tibble

get_complete_cases_single <- function(dat) {
  
  sum(complete.cases(dat)/nrow(dat))
}

# proportion of complete cases for a list of tibbles

get_complete_cases <- function(df_list) {
  
  df_list %>% 
    map(., function(df)
      get_complete_cases_single(df))
  
}



#############################
## VARIABLE TYPE FUNCTIONS ##
#############################

# identifies Y/N/NA and Y/NA variables
# what to return? var names? index number?
identify_yesno <- function(dat) {
  dat %>% 
    sapply(., function(x) { all(na.omit(x) %in% c("Y", "N")) })
}

# recode yes/no - this function doesn't work yet
recode_yesno <- function(dat) {
  dat %>% 
    extract(identify_yesno(dat)) 
}



#get_binary returns a character vector with the names of the columns that are binary for a data frame
get_binary <- function(df) {
  df %>% 
    summarise_all(funs(n_distinct(., na.rm = TRUE))) %>% 
    t() %>% as.data.frame() %>% 
    rownames_to_column("col_name") %>% 
    filter(V1 <= 2) %>%   
    use_series(col_name)
}


#get_binary cols returns only the binary cols plus the appl_year and study_id cols for any data frame
get_binary_cols <- function(df) {
  df %>%
    get_binary() %>%
    {select(df, study_id, appl_year, one_of(.))}
}




###########################
## CORRELATION FUNCTIONS ##
###########################

# correlation matrix for a single tibble
get_cor_mat_single <- function(dat, use = 'pairwise.complete.obs', round_digits = 3) {
  
  dat %>% 
    select_if(is.numeric) %>% 
    cor(., use = use) %>%
    round(round_digits)
}


# correlation matrices for a list of tibbles
get_cor_mat <- function(df_list, use = 'pairwise.complete.obs', round_digits = 3) {
  
  df_list %>% 
    map(., function(df)
      get_cor_mat_single(df, use = use, round=round_digits))
  
}



######################################
## NUMERICAL SUMMARY STAT FUNCTIONS ##
######################################

# returns first quartile
twentyfive_quantile <- function(a_vec,...) {
  unname(quantile(a_vec, .25, ...))
}

# returns third quartile 
seventyfive_quantile <- function(a_vec,...) {
  unname(quantile(a_vec, .75, ...))
}



# produces tibble containing summary statistics for a numeric variables
# should this function produce one large tibble or a list of tibbles?
# one tibble per variable would be easier to read
get_basic_summaries_single <- function(dat, varname) {
  
  quo_group_by <- enquo(varname)
  print(quo_group_by)
  
  dat %>% 
    group_by(!!quo_group_by) %>% 
    summarise_if(., is.numeric, funs(min, max, mean, median, twentyfive_quantile, seventyfive_quantile), na.rm = TRUE) 
    #select(order(colnames(.)))
}

# same output as above function, but works for multiple types of data
get_basic_summaries_single2 <- function(dat, varname, data_type = is.numeric,
            functions = funs(min, twentyfive_quantile, median, mean, seventyfive_quantile, max, sd)) {

  quo_group_by <- enquo(varname)
  print(quo_group_by)

  dat %>% 
    group_by(!!quo_group_by) %>% 
    summarise_if(., data_type, functions, na.rm = TRUE)
} 



get_basic_summaries <- function(df_list, varname) {
  
  quo_group_by <- enquo(varname)
  print(quo_group_by)
  
  df_list %>% 
    map(., function(df) {
      df %>% 
        group_by(!!quo_group_by) %>% 
        summarise_if(., is.numeric, funs(min, twentyfive_quantile, median, mean, seventyfive_quantile, max), na.rm = TRUE) 
    }
    )
}


#  currently won't work with additional arguments that need to get passed to get_basic_summaries_single
get_basic_summaries2 <- function(df_list, varname, ...) {
  
  quo_group_by <- enquo(varname)
  print(quo_group_by)
  
  df_list %>% 
    map(., function(df) {
      df %>% 
        get_basic_summaries_single(!!quo_group_by, ...)
    }
    )
}





####################################
## CATEGORICAL VARIABLE FUNCTIONS ##
####################################

# number of distinct categories for categorical variables in a tibble 
get_ndistinct_single <- function(dat, varname) {
  
  quo_group_by <- enquo(varname)
  #print(quo_group_by)
  
  dat %>% 
    group_by(!!quo_group_by) %>% 
    summarise_if(., is.character, funs(n_distinct))
}


# number of distinct categories for categorical variables for a list of tibbles
get_ndistinct <- function(df_list, varname) {
  
  quo_group_by <- enquo(varname)
  
  df_list %>% 
    map(., function(df) {
      get_ndistinct_single(df, varname = !!quo_group_by)
    } )
}


## HELPER FUNCTIONS 

# creates tables for every categorical variable in a tibble 
initialize_cat_tables <- function(dat, varname) {
  
  quo_group_by <- enquo(varname)
  #print(quo_group_by)
  
  group_var <- dat %>% select(!!quo_group_by) %>% pull()
  
  table_list <- dat %>% 
    select_if(is.character) %>%
    apply(2, table, group_var, useNA = "ifany") %>% 
    lapply(t)
  
  return(table_list)
}


# keep 10 largest categories for each table 
# this function needs to be rewritten -- doesn't work anymore
keep10_categories <- function(table_list) {
  
  names <- names(table_list) 
  
  table_list <- lapply(names, function(x) {
    many_cats <- ncol(table_list[[x]]) > 10
    if (many_cats) {
      new_table <- sort(table(dat[[x]]), decreasing=TRUE)[1:10]
      table_list[[x]] <- table_list[[x]][,names(new_table)]
    } else {
      table_list[[x]] <- table_list[[x]]
    }
  })
  
  names(table_list) <- names
  return(table_list)   
}

# returns proportions instead of raw N's     
get_table_props <- function(table_list, digits = 3) {
  table_list <- lapply(table_list, function(x) {
    round(prop.table(x, margin = 1), digits)
  })
  return(table_list)
}


######################

# creates well formatted tables for a single tibbles 
get_cat_tables_single <- function(dat, varname, prop=T, digits = 3)   {
  quo_group_by <- enquo(varname)
  #print(quo_group_by)
  
  big_tables <- initialize_cat_tables(dat, !!quo_group_by)
  table_list <- keep10_categories(big_tables)
  if (prop) {
    return(get_table_props(table_list, digits))
  } else {
    return(table_list)
  }
}


# tables for a list of tibbles -- something is off here
get_cat_tables <- function(df_list, varname, prop=T, digits=3) {
  
  quo_group_by <- enquo(varname)
  #print(quo_group_by)
  
  df_list %>% 
    map(., function(df) {
      get_cat_tables_single(df, varname = !!quo_group_by, prop = prop, digits = digits)
    } )
  
}

