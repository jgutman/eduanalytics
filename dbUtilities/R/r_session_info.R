#' Get session info
#'
#' @return info about session
#' @export
print_loaded_pkgs <- function() {
  sessionInfo() %>%
    use_series(otherPkgs) %>%
    map_chr(function(pkg) paste(pkg$Package, pkg$Version)) %>%
    cat(sep = "\n")
}
