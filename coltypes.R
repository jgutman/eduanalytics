applicants_data %>% at_depth(2, typeof) -> coltypes

coltypes %>% 
  as_data_frame() %>% 
  mutate_all(flatten_chr) -> coltypes_df

coltypes %>% 
  map(names) %>% 
  as_data_frame() %>% 
  by_row(function(a) n_distinct(flatten_chr(a)) == 1, .collate = "rows") %>% 
  use_series(.out) %>%
  all()

coltypes %>% 
  extract2(1) %>% 
  names() %>%
  mutate(coltypes_df, colname = .) %>%
  select(colname, everything()) %>%
  by_row(function(a) n_distinct(flatten_chr(a[-1])) == 1, .collate = "rows") %>% 
  filter(colname %in% c("study_id", "biological_mcat_score"))
