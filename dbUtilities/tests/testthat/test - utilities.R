context("column conversion to date")

#test column conversation to date where possible
a <- tibble::data_frame(a = c("this is", "this's also"),
                b = c("not a", "also not a"),
                c = c("2017-07-24" , "2016-08-28"),
                d = c("2018-06-24 12:03:51", "2011-06-24 12:03:51"),
                e = c("2018/6/24 12:03:51", "2011/5/24 12:03:51"))


vec <- a %>%
  purrr::map(convert_or_retain) %>%
  purrr::map_lgl(lubridate::is.POSIXt) %>%
  unname()


test_that("check columns matched expected type for more complicated data frame", {
  expect_equal(vec, c(FALSE, FALSE, TRUE, TRUE, TRUE))
})


system("mysql.server restart", ignore.stdout = TRUE, ignore.stderr = TRUE)

#test DBI connection work
test_that("check if DBI connections work", {
  expect_s4_class(get_mysql_conn(), "DBIConnection")
})



#test that drop_nonempty_columns drops columns that only incude NA
b <- tibble::data_frame(a = c("this is", "this's also", NA_character_, NA_character_, "this also"),
                        b = c("not a", "also not a", NA_character_, "hello", "coworker"),
                        c = c(1, 2, 3, 4, NA_integer_),
                        d = c(1, NA_integer_, NA_integer_, NA_integer_, NA_integer_),
                        e = c(NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_))

b2  <- b %>% dbUtilities::drop_empty_cols()

test <- tibble::data_frame(a = c("this is", "this's also", NA_character_, NA_character_, "this also"),
                           b = c("not a", "also not a", NA_character_, "hello", "coworker"),
                           c = c(1, 2, 3, 4, NA_integer_),
                           d = c(1, NA_integer_, NA_integer_, NA_integer_, NA_integer_))
test_that("check that functions drops nonempty columns", {
  expect_equal(b2,test)
})


#test that for a list of tibbles have/don't have equal col types and names

#test returns true
list_tib <- list( first_ele = tibble::data_frame(a = c("this is", "this's also"),
                                         b = c("not a", "also not a"),
                                         c = c(4,5),
                                         d = c(6,7),
                                         e = c(8,9)),
                  second_ele = tibble::data_frame(a = c("this is", "this's also"),
                                         b = c("not a", "also not a"),
                                         c = c(4,5),
                                         d = c(6,7),
                                         e = c(8,9)),
                  third_ele = tibble::data_frame(a = c("this is", "this's also"),
                                             b = c("not a", "also not a"),
                                             c = c(4,5),
                                             d = c(6,7),
                                             e = c(8,9))
)


list_tib %>% purrr::at_depth(2, typeof) -> coltypes
coltypes %>% tibble::as_data_frame() %>% dplyr::mutate_all(purrr::flatten_chr) -> coltypes_df

test_that("function returns true when column names are consistent across tibbles", {
  expect_true(coltypes %>%
                 purrr::map(names) %>%
                 tibble::as_data_frame() %>%
                 all_equal_across_row())
})


test_that("function returns true when column types are consistent across tibbles", {
  expect_true(coltypes %>%
                 magrittr::extract2(1) %>%
                 names() %>%
                 dplyr::mutate(coltypes_df, colnames = .) %>%
                 dplyr::select(-colnames) %>%
                 all_equal_across_row())
})


#test returns false

list_tib <- list( first_ele = tibble::data_frame(a = c("this is", "this's also"),
                                                 b = c("not a", "also not a"),
                                                 c = c(4,5),
                                                 d = c(6,7),
                                                 e = c(8,9)),
                  second_ele = tibble::data_frame(a = c("this is", "this's also"),
                                                  b2 = c(1, 2),
                                                  c = c(4,5),
                                                  d = c(6,7),
                                                  e = c(8,9)),
                  third_ele = tibble::data_frame(a = c("this is", "this's also"),
                                                 b = c("not a", "also not a"),
                                                 c = c(4,5),
                                                 d = c(6,7),
                                                 e = c(8,9))
)


list_tib %>% purrr::at_depth(2, typeof) -> coltypes2
coltypes2 %>% tibble::as_data_frame() %>% dplyr::mutate_all(purrr::flatten_chr) -> coltypes_df2

test_that("function returns true when column names are consistent across tibbles", {
  expect_false(coltypes2 %>%
                purrr::map(names) %>%
                tibble::as_data_frame() %>%
                all_equal_across_row())
})


test_that("function returns true when column types are consistent across tibbles", {
  expect_false(coltypes2 %>%
                magrittr::extract2(1) %>%
                names() %>%
                dplyr::mutate(coltypes_df2, colnames = .) %>%
                dplyr::select(-colnames) %>%
                all_equal_across_row())
})



