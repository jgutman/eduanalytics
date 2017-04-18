filter_first_app_only <- function(df_list, min_year, max_year) {
  df_list %>%
    # limit to application years in specified range
    map(function(df) filter(df,
        appl_year >= min_year,
        appl_year <= max_year)) %>%
    # convert to in-memory in order to apply group by
    map_if(function(df) not(tibble::is_tibble(df)),
           collect, n = Inf) %>%
    # group by applicant
    map(function(df) group_by(df, study_id)) %>%
    # for each applicant, take only data from earliest application year in range
    map(function(df) filter(df, appl_year == min(appl_year)))
}

write_to_separate_files <- function(df_nested, output_dir, filename_template) {
  df_nested %>%
    mutate(data = map(data, drop_empty_cols)) %>%
    mutate(data = fix_colnames(data)) %>%
    mutate(data = map(data, function(df) arrange(df, desc(appl_year)))) %>%
    invoke_rows(list, ., .to = "filename") %>%
    mutate(filename = map_chr(filename,
                str_interp, string = filename_template)) %>%
    mutate(path = file.path(output_dir, filename)) %>%
    {map2(.$data, .$path, write_csv)}
}

unload_workspace <- function() {
  sessionInfo() %>%
    magrittr::use_series(otherPkgs) %>%
    names() %>%
    paste0('package:', .) -> pkgs

  detach_pkg <- purrr::partial(detach,
                character.only = TRUE,
                force = TRUE)

  purrr::map(pkgs, detach_pkg)
  rm(list = ls(all.names = TRUE, envir = .GlobalEnv),
        envir = .GlobalEnv)
}
