library(magrittr)
steps <- list("parse_big_csv_files",
              "upload_raw_identified_data",
              "make_hashed_tables_all",
              "extract_from_applicant_data",
              "deidentify_data",
              "prepare_for_cleaning_tbls")

# Create .R scripts from .Rmd notebooks
render <- function (input) {
    rmarkdown::render(input,
        output_format = c("html_document", "html_notebook"),
        envir = new.env())
}

steps %>%
  paste0(".Rmd") %>%
  purrr::map(render)
