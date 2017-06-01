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
    - Run `make_hashed_tables_all.Rmd`
    - Some are hashed on `aamc_id`, some are hashed on `amcas_id`
1. Extract supplemental applicant data from application tracking
    - Run `extract_from_applicant_data.Rmd`
1. Get `deidentified` versions of all datasets
    - Run `deidentify_data.Rmd`
    - Can read in column names to drop or keep from `.yaml` file
1. Upload deidentified outcomes data and new features
    - Run `upload_deidentified_outcomes_data.Rmd`
    - Outcomes can be read in from `outcomes.yaml` file



## Cleaning
1. Prepare `clean` versions of tables with basic applicant filtering and formatting fixes
    - Run `prepare_for_cleaning_tbls.Rmd`
1. Prepare `ready` versions of tables with more ad-hoc iterative data fixes
   - TODO!

## Descriptives
See detailed outline in [descriptives reporting feature requests](DescriptivesReporting.md)
1. Run `data_Reports.Rmd` to get reports on features and outcomes variables


## Feature generation
- Generate GPA features for modeling
    - Run `gpa_feature_generation.Rmd`
- Generate MCAT (old/new) features for modeling
    - Run `mcat_feature_generation.Rmd`
- Generate BCPM grade features for modeling
    - Run `feature_generate_grades.Rmd`

## Model building
1. Construct design matrix for modeling using generated features
    - Run `construct_design_matrix.Rmd`
1. Run models
    - Run script `run_all_models.sh` to save model runs in `pkls` folder and database


## Model evaluation
1. Run `explore_predictions.ipynb` for looking at overall predictions by outcomes

## Reporting
1. Run `analyze_screening_predictions.Rmd` for analysis of predictions for screening
1. Run `explore_predictions.ipynb` for looking at overall predictions by outcomes
1. Run `Lime explanations.ipynb` for looking at individualized predictions
