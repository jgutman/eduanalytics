## ---- setup_notebook
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
# credentials_path <- "/Users/iime/Desktop/admissions"
reconnect <- function() {
    get_mysql_conn(path = credentials_path,
        credentials_file = "edu_deid.my.cnf",
                   group = "edu_deident") %>%
    assign("edu_deid_con", ., envir = .GlobalEnv)
}

reconnect()
