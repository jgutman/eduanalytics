#devtools::install("~/Desktop/Box Sync/IIME/Admissions/dbUtilities/")
credentials_path <- "/Volumes/IIME/EDS/data/admissions/db_credentials/"
conn <- dbUtilities::get_mysql_conn(path = credentials_path, group = "edu_db_owner")

conn %>%
  tbl("out$predictions$screening_current_cohort") %>%
  collect(n=Inf) -> predictions

quantile(predictions$score)

ggplot(predictions, aes(score)) + 
  geom_histogram(bins = 25) + 
  coord_cartesian(xlim = c(-1, 1), expand = FALSE)

