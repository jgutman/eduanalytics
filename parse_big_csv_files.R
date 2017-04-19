# Path containing all data directories
parent_path <- "/Volumes/IIME/EDS/data/admissions"
data_dirs <- list.dirs(parent_path, 
    full.names = TRUE, recursive = FALSE)

# Contains preferred versions of raw identified edudw data
identified_raw_edudw_path <- data_dirs %>% 
    str_detect("raw.*identified.*edudw") %>% 
    extract(data_dirs, .)

# Contains pulled edudw data in original format
edudw_pull_path <- data_dirs %>%
  str_detect("edudw.*pull") %>% 
  extract(data_dirs, .)
fread_na <- purrr::partial(data.table::fread, na.strings = c("NA","N/A","null", ""))
# File containing all experiences data for all years
experiences_path <- file.path(edudw_pull_path, 
                              "experiences.csv") %>% print()
# Reference contact info to remove
drop_cols <- c("CONTACT_FNAME", 
               "CONTACT_LNAME",
               "CONTACT_PHONE", 
               "CONTACT_EMAIL")

experiences_path %>%
  fread_na(drop = drop_cols) %>%
  mutate(year_range = if_else(appl_year <= 2013, "_2006_2013", "")) %>% 
  group_by(year_range) %>% 
  nest() -> exp
exp %>%
  write_to_separate_files(identified_raw_edudw_path, "experiences${year_range}.csv") %>% 
  invisible()
# File containing MMI data for all years
mmi_path <- file.path(edudw_pull_path, 
                      "mmi_scores.csv") %>% print()
mmi_path %>%
  fread_na() %>%
  rename(appl_year = app_year) %>%
  mutate(year_range = if_else(appl_year <= 2013, "_2013", "")) %>% 
  group_by(year_range) %>% 
  nest() -> mmi
mmi %>%
  write_to_separate_files(identified_raw_edudw_path, "mmi_scores${year_range}") %>%
  invisible()
# File containing all grades data for all years
grades_path <- file.path(edudw_pull_path, 
                         "Grades.csv") %>% print()
# grades columns to keep - condensed amcas version
keep_cols <- c("appl_year",
               "aamc_id",
               "academic_year",
               "course_qp",
               toupper("aca_term_cd"),
               toupper("aca_term_desc"),
               toupper("semester_hours"),
               toupper("aca_status_cd"),
               toupper("aca_status_desc"),
               toupper("class_cd"),
               toupper("class_desc"),
               toupper("bcpm_ind"),
               toupper("amcas_grade_cd"),
               toupper("amcas_weight"))
grades_path %>%
  fread_na(select = keep_cols) %>%
  mutate(year_range = if_else(appl_year <= 2009, "_2006_2009", 
                      if_else(appl_year <= 2013, "_2010_2013", ""))) %>% 
  group_by(year_range) %>% 
  nest() -> grades
grades %>%
  write_to_separate_files(identified_raw_edudw_path, "grades${year_range}.csv") %>%
  invisible()
