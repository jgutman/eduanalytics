require(devtools)
# devtools::install_github("hadley/lazyeval")
# devtools::install_github("hadley/dplyr")

require(dplyr)

a <- data_frame(col1 = 1:10, col2 = 11:20, col3 = 21:30)
a %>% mutate_if(is.character, as.factor)

b <- data_frame(col1 = 1:10, col2 = 11:20, col3 = 21:30, col4 = letters[1:10])
b %>% mutate_if(is.character, as.factor)

a %>% select_if(is.character)
b %>% select_if(is.character)
