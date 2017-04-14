print_loaded_pkgs <- function() {
  sessionInfo() %>%
  magrittr::use_series(otherPkgs) %>%
  purrr::map_chr(function(pkg) paste(pkg$Package, pkg$Version)) %>%
  cat(sep = "\n")
}
