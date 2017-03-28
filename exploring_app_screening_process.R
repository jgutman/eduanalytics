applicants_all_years %>% 
  filter_applications() %>%
  filter(status == "SR") %>%
  {table(.$app_year, .$scr_dec)}

nested_applicants %>%
  mutate(screening_rejects_by_date = map2(faculty_screened, invited_for_interview, 
          function(a, b) setdiff(a$aamc_id, b$aamc_id))) %>%
  select(app_year, screening_rejects_by_date) %>%
  unnest() %>% 
  rename(aamc_id = screening_rejects_by_date) %>%
  left_join(select(applicants_all_years, app_year, aamc_id, status, scr_dec, one_of(tracking_columns)), 
            by = c("app_year", "aamc_id")) %>%
  arrange(scr_dec) -> screening_reject_inspect

View(screening_reject_inspect)

with(screening_reject_inspect, table(scr_dec, status))