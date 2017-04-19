library(magrittr)
steps <- list("parse_big_csv_files",
              "upload_raw_identified_data",
              "make_hashed_tables_all",
              "deidentify_data",
              "prepare_for_cleaning_tbls")
              # "master_ready_for_analysis")

# Create .R scripts from .Rmd notebooks
steps %>%
  paste0(".Rmd") %>%
  rmarkdown::render(envir = new.env(parent = baseenv()))
