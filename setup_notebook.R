## ---- setup_notebook

library(tidyverse)
library(RMySQL)
library(yaml)
library(knitr)
library(stringr)
library(magrittr)
library(lubridate)

devtools::install("dbUtilities",
    dependencies = FALSE, quiet = TRUE)
library(dbUtilities)

knitr::opts_chunk$set(
    message = FALSE,
    warning = FALSE,
    comment = "   ",
    cache = TRUE,
    autodep = TRUE,
    cache.comments = FALSE)

credentials_path <- "/Volumes/IIME/EDS/data/admissions/db_credentials/"
edu_db_con <- get_mysql_conn(credentials_path, group = "edu_db_owner")
