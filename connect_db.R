library(RMySQL)
library(yaml)
library(dplyr)

credentials_path <-  "/Volumes/IIME/EDS/data/admissions/db_credentials/"
credentials_file <- "owner_credentials.yaml"
credentials <- paste0(credentials_path, credentials_file) %>% 
  yaml::yaml.load_file()

edu_db <- dbConnect(MySQL(), 
        user = credentials$user, 
        password = credentials$password, 
        dbname = credentials$dbname, 
        host = credentials$host,
        port = credentials$port)

rm(credentials)

table_names <- db_list_tables(edu_db)

dbDisconnect(edu_db)