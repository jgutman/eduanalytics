parent_path <- "/Volumes/IIME/EDS/data/admissions"
(data_dirs <- list.dirs(parent_path, full.names = TRUE, recursive = FALSE))
data_dirs %>%
  str_detect("from_.*admissions") %>%
  extract(data_dirs, .) %>%
  file.path(., "Data") ->
  identified_raw_admissions_path

list.files(identified_raw_admissions_path, full.names = TRUE) %>%
  print() -> identified_raw_admissions_files
identified_raw_admissions_files %>%
  map(function(path) readxl::read_excel(path)) %>%
  fix_colnames() %>%
  map(drop_empty_cols) ->
  identified_raw_admissions_list
paste(rep(2013:2017, each = 3),
        c("all_applicants", "matriculated_report", "tracking_report"), sep = "_") %>%
  add_tbl_prefix(id = "identified", status = "raw") %>%
  extract(1:length(identified_raw_admissions_list)) %>%
  print() -> table_names

identified_raw_admissions_list %<>%
  set_names(table_names) %>%
  map(function(df) set_names(df, str_replace(colnames(df), "recevied", "received")))

identified_raw_admissions_list %>%
  write_to_database(edu_db_con)
identified_raw_edudw_path <- data_dirs %>%
  str_detect("raw.*identified.*edudw") %>%
  extract(data_dirs, .)

list.files(identified_raw_edudw_path, full.names = TRUE) %>%
  print() -> identified_raw_edudw_files
identified_raw_edudw_files %>%
  map(function(path) fread(path)) %>%
  fix_colnames() %>%
  map(drop_empty_cols) ->
  identified_raw_edudw_list
identified_raw_edudw_files %>%
  str_replace(identified_raw_edudw_path, "") %>%
  str_replace_all(c("/" = "", ".csv" = "")) %>%
  add_tbl_prefix(id = "identified", status = "raw") %>%
  print() -> table_names

identified_raw_edudw_list %<>%
  set_names(table_names) %>%
  map(function(df) set_names(df,
        str_replace(colnames(df), "(?<=(low)|(high))_p$", "_percentile"))) %>%
  map(function(df) set_names(df, str_replace(colnames(df), "meaningfull", "meaningful")))
parse_time_mod <- purrr::partial(lubridate::parse_date_time,
      orders = c("%Y-%m-%d %H:%M:%S", "%d-%b-%y"),
      tz = "America/New_York", truncated = 3)

identified_raw_edudw_list$`identified$raw$mmi_scores` %<>%
  mutate(start_time = parse_time_mod(start_time))

identified_raw_edudw_list$`identified$raw$new_mcat` %<>%
  mutate(new_mcat_test_date = parse_time_mod(new_mcat_test_date),
         new_mcat_percentile_effe_date = parse_time_mod(new_mcat_percentile_effe_date))

identified_raw_edudw_list$`identified$raw$old_mcat` %<>%
  mutate(test_date = parse_time_mod(test_date))

identified_raw_edudw_list$`identified$raw$school` %<>%
  mutate(attend_start_dt = parse_time_mod(attend_start_dt),
         attend_finish_dt = parse_time_mod(attend_finish_dt))
identified_raw_edudw_list$`identified$raw$experiences` %<>%
  mutate(avg_hrs_per_week = if_else(appl_year >= 2015, 
                                    NA_integer_, avg_hrs_per_week))
identified_raw_edudw_list %>%
  write_to_database(edu_db_con)
disconnect_all()
