write_deidentified_to_file = FALSE
deidentified_output <- "/Volumes/IIME/EDS/data/admissions/data_for_itai/"
query_rename_col <- "alter table ${tbl_name} change ${old_name} ${new_name} DOUBLE;"
tbl_names <- get_tbl_names_by_stage(edu_db_con, "deidentified", "raw")

tbl_names %>%
  find_tbls_with_col("app_year", edu_db_con) %>%
  map_lgl(function(tbl_name) interpolate_and_execute(query_rename_col, edu_db_con,
          commit = TRUE, tbl_name = tbl_name,                               
           old_name = "app_year", new_name = "appl_year"))
pattern <- "^deidentified\\Wraw\\W[[:alpha:]].*[[:alpha:]]$"

edu_db_con %>%
  get_tbls_by_pattern(pattern, in_memory = FALSE) -> 
  edudw_deidentified

edudw_deidentified %<>%
  names() %>%
  add_tbl_prefix() %>%
  set_names(edudw_deidentified, .) ->
  edudw_deidentified
edudw_deidentified %<>%
  filter_first_app_only(min_year = 2014, max_year = 2017) %>%
  map(drop_empty_cols)
edudw_deidentified$`deidentified$clean$mmi_scores` %<>%
  select(-mmi_question_id, -code) %>%
  mutate(interviewer_type = str_replace(interviewer_type, "Interviewer ", "")) %>%
  mutate(interviewer_type = as.integer(interviewer_type))
edudw_deidentified$`deidentified$clean$experiences` %<>%
  replace_na(list(first_total_hrs = 0,
                  second_total_hrs = 0,
                  third_total_hrs = 0,
                  fourth_total_hrs = 0)) %>%
  mutate(total_hrs = first_total_hrs + 
                     second_total_hrs +
                     third_total_hrs + 
                     fourth_total_hrs)
edudw_deidentified %>%
  write_to_database(edu_db_con)
if (write_deidentified_to_file) {
  names(edudw_deidentified) %>%
    get_tbl_suffix() %>%
    paste("clean", "deidentified.csv", sep = "_") ->
    filenames

  edudw_deidentified %>%
    map2(filenames, function(df, name) write_to_file(df, deidentified_output, name))
}
pattern <- "^deidentified\\Wraw\\W\\d{4}.*[[:alpha:]]$"

tracking_columns <- c("appl_submit_date",
                      "appl_complete_date",
                      "screening_complete_date",
                      "interview_invite_date",
                      "interview_schedule_date",
                      "interview_day",
                      "interview_complete_date",
                      "committee_date",
                      "offer_date",
                      "accept_date")
edu_db_con %>%
  get_tbls_by_pattern(pattern) -> 
  app_data_deidentified

app_data_deidentified %<>%
  names() %>%
  add_tbl_prefix() %>%
  set_names(app_data_deidentified, .)
app_data_deidentified %>% 
  names() %>% 
  str_detect("201[4-7]") %>%
  extract(app_data_deidentified, .) %>%
  do.call(bind_rows, .) %>%
  select(study_id, appl_year, one_of(tracking_columns), everything()) ->
  applicant_data
  
filter_applications <- . %>%
  # filter out M.D./Ph.D. applicants, special programs (i.e. linkages), and 
  # deferred applicants from previous years
  filter(appl_type_desc %in% c("Regular M.D.", "Combined  Medical Degree/Graduate")) %>%
  filter(!str_detect(status, "M\\w{2}")) %>%
  filter(!is.na(appl_submit_date) & !is.na(appl_complete_date))

applicant_data %<>% 
  filter_applications() %>% 
  drop_empty_cols() %>%
  select(-mstp, -mstp_to_md)
split_screener_score <- . %>% 
  mutate(screener_a_b = recode(scr_dec, 
          `2` = "1_1", `3` = "1_2", `4` = "4", `5` = "2_3", `6` = "3_3"),
        screener_a_b = if_else(scr_dec == 4, 
                       if_else(screener_sd == 0, "2_2", "1_3"), 
                       screener_a_b)) %>%
  separate(screener_a_b, c("screener_a", "screener_b"))

applicant_data %<>%
  split_screener_score() %>%
  select(-screener_sd, -committee_sd) %>%
  rename(screener_total = scr_dec)
applicant_data %<>%
  mutate(is_faculty_screened = !is.na(screening_complete_date),
         is_invited_interview = !is.na(interview_invite_date),
         is_interviewed = !is.na(interview_day),
         is_committee_reviewed = !is.na(committee_date),
         is_offered_admission = !is.na(offer_date))
tbl_name <- "all_applicants" %>%
  add_tbl_prefix()

applicant_data %>%
  write_to_database_single(edu_db_con, tbl_name)
if (write_deidentified_to_file) {
  applicant_data %>%
  write_to_file(deidentified_output, 
                  "admissions_all_applicants_deidentified_clean.csv")
}
disconnect_all()
