context("column conversition to date")

#test column conversation to date where possible
a <- tibble::data_frame(a = c("this is", "this's also"),
                b = c("not a", "also not a"),
                c = c("2017-07-24" , "2016-08-28"),
                d = c("2018-06-24 12:03:51", "2011-06-24 12:03:51"),
                e = c("2018/6/24 12:03:51", "2011/5/24 12:03:51"))


vec <- a2 %>%
  purrr::map(convert_or_retain) %>%
  purrr::map_lgl(lubridate::is.POSIXt) %>%
  unname()


test_that("check columns matched expected type for more complicated data frame", {
  expect_equal(vec, c(FALSE, FALSE, TRUE, TRUE, TRUE))
})


#test DBI connection work
test_that("check if DBI connections work", {
  expect_s4_class(get_mysql_conn(), "DBIConnection")
})
