require(purrr)

quietly_parse_time <- quietly(function(.x) 
  parse_date_time(.x, "YmdHMS", 
      tz = "America/New_York", truncated = 3))

convert_or_retain <- function(col) {
  col_mutated <- quietly_parse_time(col)
  
  no_errors <- is_empty(col_mutated$warnings)
  
  if (no_errors) col_mutated$result else col
}

system.time(
  all_apps_2013 %>%
    mutate_if(is.character, convert_or_retain) -> converted)
