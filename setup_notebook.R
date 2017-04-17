## ---- setup_notebook
packrat::restore(overwrite.dirty = TRUE)
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
