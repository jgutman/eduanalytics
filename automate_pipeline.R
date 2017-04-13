steps <- list("parse_big_csv_files",
              "upload_raw_identified_data",
              "make_hashed_tables_all",
              "deidentify_data",
              "prepare_for_cleaning_tbls",
              "master_ready_for_analysis")

# Create .R scripts from .Rmd notebooks
steps %>%
  paste0(".Rmd") %>%
  purrr::map(knitr::purl, documentation = 0)

# Source .R scripts in a clean environment
steps %>%
  paste0(".R") %>%
  purrr::map(devtools::clean_source, quiet = TRUE)