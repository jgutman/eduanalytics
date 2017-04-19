---
title: "Prepare raw versions of MMI and Experiences data"
subtitle: "Separate data from 2014 to present from older data"
author: "Jacqueline Gutman, Suvam Paul"
date: 'Last updated: April 18, 2017 '
output:
  html_document:
    toc: yes
    toc_depth: '4'
  html_notebook:
    highlight: tango
    theme: cosmo
    toc: yes
    toc_depth: 4
---

# Setup
## Load packages
## Read in database credentials and open connection




```r
library(RMySQL)
library(yaml)
library(data.table)
library(knitr)
library(tidyverse)
library(stringr)
library(magrittr)
library(lubridate)

##  devtools::install("dbUtilities",
#    dependencies = FALSE, quiet = TRUE)
library(dbUtilities)

knitr::opts_chunk$set(
    message = FALSE,
    warning = FALSE,
    comment = "   ",
    cache = TRUE,
    autodep = TRUE,
    cache.comments = FALSE)

credentials_path <- "/Volumes/IIME/EDS/data/admissions/db_credentials"
reconnect <- function() {
    get_mysql_conn(path = credentials_path,
                   group = "edu_db_owner") %>%
    assign("edu_db_con", ., envir = .GlobalEnv)
}

reconnect()
```


```
    bindrcpp 0.1
    dbUtilities 0.1.0
    lubridate 1.6.0
    magrittr 1.5
    stringr 1.2.0
    dplyr 0.5.0.9002
    purrr 0.2.2
    readr 1.1.0
    tidyr 0.6.1
    tibble 1.3.0
    ggplot2 2.2.1
    tidyverse 1.1.1
    knitr 1.15.1
    data.table 1.10.0
    yaml 2.1.14
    RMySQL 0.10.11
    DBI 0.6-1
```

## Load data from shared drive


```r
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
```


```r
fread_na <- purrr::partial(data.table::fread, na.strings = c("NA","N/A","null", ""))
```



```r
# File containing all experiences data for all years
experiences_path <- file.path(edudw_pull_path, 
                              "experiences.csv") %>% print()
```

```
    [1] "/Volumes/IIME/EDS/data/admissions/data_from_edudw_pull_nivedha/experiences.csv"
```

`experiences_2006_2013.csv` for 2006-2013 application cycle extracurriculars (avg hrs per week)
`experiences.csv` for 2014-2017 application cycle extracurriculars (total hrs per week)


```r
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
```

```
    Read 0.0% of 1129666 rowsRead 15.9% of 1129666 rowsRead 39.8% of 1129666 rowsRead 62.9% of 1129666 rowsRead 66.4% of 1129666 rowsRead 87.6% of 1129666 rowsRead 1129666 rows and 26 (of 30) columns from 0.304 GB file in 00:00:13
```


```r
exp %>%
  write_to_separate_files(identified_raw_edudw_path, "experiences${year_range}.csv") %>% 
  invisible()
```


```r
# File containing MMI data for all years
mmi_path <- file.path(edudw_pull_path, 
                      "mmi_scores.csv") %>% print()
```

```
    [1] "/Volumes/IIME/EDS/data/admissions/data_from_edudw_pull_nivedha/mmi_scores.csv"
```

`mmi_scores_2013.csv` for 1-on-1 2013 application cycle interviews
`mmi_scores.csv` for MMI application cycle 2014-2017 interviews


```r
mmi_path %>%
  fread_na() %>%
  rename(appl_year = app_year) %>%
  mutate(year_range = if_else(appl_year <= 2013, "_2013", "")) %>% 
  group_by(year_range) %>% 
  nest() -> mmi
```


```r
mmi %>%
  write_to_separate_files(identified_raw_edudw_path, "mmi_scores${year_range}") %>%
  invisible()
```


```r
# File containing all grades data for all years
grades_path <- file.path(edudw_pull_path, 
                         "Grades.csv") %>% print()
```

```
    [1] "/Volumes/IIME/EDS/data/admissions/data_from_edudw_pull_nivedha/Grades.csv"
```

```r
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
```


```r
grades_path %>%
  fread_na(select = keep_cols) %>%
  mutate(year_range = if_else(appl_year <= 2009, "_2006_2009", 
                      if_else(appl_year <= 2013, "_2010_2013", ""))) %>% 
  group_by(year_range) %>% 
  nest() -> grades
```

```
    Read 0.0% of 4810222 rowsRead 11.2% of 4810222 rowsRead 29.3% of 4810222 rowsRead 46.8% of 4810222 rowsRead 64.7% of 4810222 rowsRead 82.5% of 4810222 rowsRead 98.3% of 4810222 rowsRead 4810222 rows and 14 (of 21) columns from 0.798 GB file in 00:00:22
```



```r
grades %>%
  write_to_separate_files(identified_raw_edudw_path, "grades${year_range}.csv") %>%
  invisible()
```
