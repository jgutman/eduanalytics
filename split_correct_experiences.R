require(dplyr)
require(stringr)
require(readr)
require(magrittr)

# Path containing all data directors
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

# File containing all experiences data for all years
experiences_path <- file.path(edudw_pull_path, "experiences.csv")

# Reference contact info to remove
drop_cols <- c("CONTACT_FNAME", "CONTACT_LNAME",
               "CONTACT_PHONE", "CONTACT_EMAIL")

drop_empty_cols <- function(df) {
  # Return true if a column is non-empty
  # Return false if a column contains NAs
  non_empty <- . %>%
    is.na() %>%
    mean() %>%
    is_less_than(1)
  
  df %>% 
    select_if(non_empty)
}

exp <- read_csv(experiences_path, na = "null")

clean_experiences <- . %>%
  select(-one_of(drop_cols)) %>%
  drop_empty_cols() %>% 
  arrange(desc(appl_year))

exp_old <- exp %>%
  filter(appl_year <= 2013) %>%
  clean_experiences()

exp_current <- exp %>%
  filter(appl_year > 2013) %>%
  clean_experiences()

rm(exp)

identified_raw_edudw_path %>%
  file.path("experiences_2006_2012.csv") %>%
  write_csv(exp_old, .)

identified_raw_edudw_path %>%
  file.path("experiences_2013_2017.csv") %>%
  write_csv(exp_current, .)

rm(exp_old)
rm(exp_current)