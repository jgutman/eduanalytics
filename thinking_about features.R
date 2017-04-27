#gpa

#get data
gpa <- dbUtilities::put_tbl_to_memory(edu_db_con, "deidentified$clean$gpa")

gpa_subset <- gpa %>% select(-aca_status_cd) %>% 
  filter(aca_status_desc == "Cumulative" | aca_status_desc == "Postbaccalaureate Undergraduate") 


find_and_replace <- function(dat_tbl, pattern, val) {
  dat_tbl %>% 
    names(.) %>% 
    stringr::str_replace_all(., pattern, map_chr(names(dat_tbl), function(x) {paste(x, val, sep = "_") })) 

}

gpa_cumulative <- gpa_subset %>% filter(aca_status_desc == "Cumulative")
names(gpa_cumulative) <- find_and_replace(gpa_cumulative, "bcpm_gpa|ao_gpa|total_gpa", "cumulative")


gpa_post_bac <- gpa_subset %>% filter(aca_status_desc == "Postbaccalaureate Undergraduate")
names(gpa_post_bac) <- find_and_replace(gpa_post_bac, "bcpm_gpa|ao_gpa|total_gpa", "postbac")

gpa_ready <- gpa_cumulative %>% 
  select(-aca_status_desc) %>% 
  left_join(., select(gpa_post_bac, -appl_year, -aca_status_desc), by = "study_id")





#grades 
grades <- dbUtilities::put_tbl_to_memory(edu_db_con, "deidentified$clean$grades")

as_tibble(grades)






#schools 
school <- dbUtilities::put_tbl_to_memory(edu_db_con, "deidentified$clean$school")
View(school)


#experiences 
experiences <- dbUtilities::put_tbl_to_memory(edu_db_con, "deidentified$clean$experiences")
  

#old mcat
old_mcat <- dbUtilities::put_tbl_to_memory(edu_db_con, "deidentified$clean$old_mcat")

names(old_mcat)


#new mcat
new_mcat <- dbUtilities::put_tbl_to_memory(edu_db_con, "deidentified$clean$new_mcat")


#applicants
applicants <- dbUtilities::put_tbl_to_memory(edu_db_con, "deidentified$clean$all_applicants")
applicants_screened <- applicants %>% filter(is_faculty_screened == 1)


app_2016 <- dbUtilities::put_tbl_to_memory(edu_db_con, "hashed$raw$2016_all_applicants")
  
  