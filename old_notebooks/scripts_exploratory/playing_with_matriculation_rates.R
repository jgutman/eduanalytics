"screening_features_with_risk_bucket" %>%
  add_tbl_prefix(status = "predictions") %>%
  put_tbl_to_memory(edu_db_con, .) -> pred

pred %>%
  mutate(race_binary = if_else(is.na(race) | race %in% c("Asian", "Chinese", "Japanese", "Korean",
                                                         "Other Asian", "Pakistani", "Vietnamese", 
                                                         "White"), 'not_urm', 'urm'),
         urm_corrected = if_else(urm == 'Y' | is_disadvantaged == 1 | race_binary == 'urm', 
                                 1, 0)) -> pred_2

pred_2 %<>% mutate(risk_bucket = if_else(urm_corrected == 1, 0, risk_bucket))

pred_2 %<>% select(-(bcpm_gpa_cumulative:is_faculty_screened), 
                   -set, -is_committee_reviewed, 
                   -race_binary, -urm_corrected)

pred_2017 <- pred_2 %>% filter(appl_year == 2017)
pred_2 <- pred_2 %>% filter(appl_year != 2017)

pred_2 %>% mutate(model_screen = if_else(risk_bucket == 0 | (risk_bucket >= 8 & risk_bucket <= 14), 1, 0),
                  model_interview = if_else(model_screen == 1, is_interviewed, 
                                            as.numeric(risk_bucket == 15)),
                  model_accepted = if_else(model_interview == 1, is_offered_admission, 0),
                  model_matriculate = if_else(model_accepted == 1, is_matriculated, 0)) -> pred_3

pred_3 %>% group_by(risk_bucket) %>% 
  summarize(
  total = n(),
  num_interviewed = sum(is_interviewed),
  pct_interviewed = scales::percent(mean(is_interviewed)), 
  num_accepted = sum(is_offered_admission),
  pct_accepted = scales::percent(mean(is_offered_admission)),
  num_matriculated = sum(is_matriculated), 
  pct_matriculated = scales::percent(mean(is_matriculated)),
  num_screened_model = sum(model_screen),
  num_interview_model = sum(model_interview),
  num_accepted_model = sum(model_accepted),
  num_matriculated_model = sum(model_matriculate)
) -> pred_4

pred_2017 %>% group_by(risk_bucket) %>% summarize(total = n())

write_csv(pred_4, "admissions_screening.csv")

pred_4 %>% ungroup() %>% 
  summarize(n_screened_old = sum(total), n_screened_model = sum(num_screened_model),
            n_interviewed_old = sum(num_interviewed), n_interviewed_model = sum(num_interview_model),
            n_accepted_old = sum(num_accepted), n_accepted_model = sum(num_accepted_model),
            n_matriculated_old = sum(num_matriculated), n_matriculated_model = sum(num_matriculated_model)) %>% 
write_csv(., "payoff.csv")

pred_2017_v3 %>% 
  summarize(
    total = n(),
    num_interviewed = sum(is_interviewed),
    num_screened_model = sum(model_screen),
    num_interview_model = sum(model_interview)
  )