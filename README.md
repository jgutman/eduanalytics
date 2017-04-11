## ETL

1. Create directory structure for raw data in secure drive
    1. Place following files in the `data_from_edudw_pull*` directory:
        - `experiences.csv`
        - `mmi_scores.csv`
    1. Place following files in the `raw_identified_edudw` directory:
        - `ethnicity.csv`
        - `gpa.csv`
        - `new_mcat.csv`
        - `old_mcat.csv`
        - `parent_guardian.csv`
        - `race.csv`
        - `school.csv`
    1. Place following files in the  `data*from*admissions` directory:
        - `* all applicants.csv`
        - `* matriculated report.csv`
        - `* tracking report.csv`
    1. Place following database credentials in the `db_credentials` directory:
        - `.my.cnf`
1. Parse large `.csv` files
    - Run `parse_big_csv_files.Rmd`
1. Upload `identified raw` data to database
    - Run `upload_raw_identified_data.Rmd`
    - `raw_identified_edudw` directory should contain 11 text files
    - `data*from*admissions/Data` directory should contain up to 3 text files per application year
1. Get `hashed` versions of all datasets
    - `hashed$raw${tbl_name}` includes study_id column
    - EDS holds the key
1. Get `deidentified` versions of all datasets
    - Run `deidentify_data.Rmd`
    - Can read in column names to drop or keep from `.yaml` file

## Cleaning
1. Prepare `clean` versions of tables with basic applicant filtering and formatting fixes
    - Run `prepare_for_cleaning_tbls.Rmd`
1. Prepare `ready` versions of tables with more ad-hoc iterative data fixes
    - Run `master_ready_for_analysis.Rmd`
    - Add individual cleaning scripts to master notebook as they are completed

## Descriptives

## Feature generation

## Model building

## Model evaluation

## Reporting
