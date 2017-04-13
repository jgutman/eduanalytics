library(tidyverse)
library(RMySQL)
library(yaml)
library(knitr)
library(stringr)
library(magrittr)
library(lubridate)

sessionInfo() %>%
  use_series(otherPkgs) %>%
  map_chr(function(pkg) paste(pkg$Package, pkg$Version)) %>%
  cat(sep = "\n")

opts_chunk$set(message = FALSE, warning = FALSE, comment = "   ",
            cache = TRUE, autodep = TRUE, cache.comments = FALSE)

#devtools::install("dbUtilities", dependencies = FALSE, quiet = TRUE)
library(dbUtilities)
credentials_path <- "/Volumes/IIME/EDS/data/admissions/db_credentials/"
edu_db_con <- get_mysql_conn(credentials_path, group = "edu_db_owner")
write_deidentified_to_file = FALSE
deidentified_output <- "/Volumes/IIME/EDS/data/admissions/data_for_itai/"
all_table_names <- dbListTables(edu_db_con) %>% print()

edu_db_con %>%
  get_tbls_by_pattern("^hashed\\Wraw\\W\\d{4}_all_applicants", in_memory = FALSE) %>%
  set_names(paste(2013:2017, "all_applicants", sep = "_")) -> 
  applicants_data
# filter out irrelevant and identifying columns
applicants_data %<>% 
  parse_yaml_cols("cols_to_keep_or_drop.yaml")
names(applicants_data) %>%
  add_tbl_prefix(status = "raw") ->
  tbl_names

applicants_data %>% 
  set_names(tbl_names) %>%
  map(collect, n = Inf) %>%
  write_to_database(edu_db_con)
if (write_deidentified_to_file) {
  applicants_data %>%
    map(collect, n = Inf) %>%
    bind_rows() %>%
    write_to_file(deidentified_output, 
                  "admissions_all_applicants_deidentified.csv")
}
pattern <- "^hashed\\Wraw\\W[[:alpha:]]"
all_table_names %>%
  str_detect(pattern) %>%
  extract(all_table_names, .) %>%
  str_replace_all("hashed", "deidentified") ->
  tbl_names

edu_db_con %>%
  get_tbls_by_pattern(pattern, in_memory = FALSE) %>%
  set_names(tbl_names) %>%
  # filter out irrelevant and identifying columns
  parse_yaml_cols("cols_to_keep_or_drop.yaml") -> 
  edudw_df_list

edudw_df_list %>%
  map(collect, n = Inf) %>%
  write_to_database(edu_db_con)
if (write_deidentified_to_file) {
  names(edudw_df_list) %>%
    str_split("\\$", n=3) %>%
    map_chr(tail, n = 1L) %>%
    paste("raw", "deidentified.csv", sep = "_") ->
    filenames
  
  edudw_df_list %>%
    map(collect, n = Inf) %>%
    map2(filenames, function(df, name) write_to_file(df, deidentified_output, name))
}
disconnect_all()
