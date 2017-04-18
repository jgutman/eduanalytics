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



#' Function to unload packages from workspace
#'
#' @return clean workspace
#' @export
#'
unload_workspace <- function() {

  sessionInfo() %>%
    use_series(otherPkgs) %>%
    names() %>%
    paste0('package:', .) -> pkgs

  detach_pkg <- partial(detach,
        character.only = TRUE,
        force = TRUE)

  map(pkgs, detach_pkg)
  rm(list = ls(all.names = TRUE, envir = .GlobalEnv),
     envir = .GlobalEnv)
}
