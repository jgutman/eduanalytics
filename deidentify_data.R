write_deidentified_to_file = FALSE
deidentified_output <- "/Volumes/IIME/EDS/data/admissions/data_for_itai/"
pattern <- "^hashed\\Wraw\\W\\d{4}_all_applicants"

edu_db_con %>%
  get_tbls_by_pattern(pattern, in_memory = FALSE) %>%
  # filter out irrelevant and identifying columns
  parse_yaml_cols("cols_to_keep_or_drop.yaml") -> 
  applicants_data
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

edu_db_con %>%
  get_tbls_by_pattern(pattern, in_memory = FALSE) %>%
  # filter out irrelevant and identifying columns
  parse_yaml_cols("cols_to_keep_or_drop.yaml") -> 
  edudw_df_list

names(edudw_df_list) %>%
  add_tbl_prefix(status = "raw") ->
  tbl_names

edudw_df_list %>%
  set_names(tbl_names) %>%
  map(collect, n = Inf) %>%
  write_to_database(edu_db_con)
if (write_deidentified_to_file) {
  names(edudw_df_list) %>%
    get_tbl_suffix() %>%
    paste("raw", "deidentified.csv", sep = "_") ->
    filenames
  
  edudw_df_list %>%
    map(collect, n = Inf) %>%
    map2(filenames, function(df, name) write_to_file(df, deidentified_output, name))
}
disconnect_all()
