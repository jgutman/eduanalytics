# Admissions Screening modeling process

## Feature generation
Feature generation used to be done in R using the `dbUtilities` package developed by Suvam Paul and Jacqueline Gutman (see [our deprecated README](README_old.md)) but is now done predominantly in the research database directly using SQL views. For detailed documentation on the structure of these views and how they are generated, see documentation in the [Google Drive](https://drive.google.com/open?id=0B__nBZCrcLwjc2t4eU5pd0V3RGM) for this project, specifically our [data dictionary](https://docs.google.com/document/d/1OnS4kOclTdohz-5x7vS5auKelp7B4DySRKl6F-EU3cI/edit?usp=sharing) and [view construction specification](https://docs.google.com/a/med.nyu.edu/document/d/1OWY1iZsXPYPBHA8oou08APH5wQGFfYNZPpK1K7bTF_w/edit?usp=sharing). Raw input data for the views is provided by AMP developers and managed by EDS.

## Model specification
Each trained algorithm corresponds to a particular subgroup of the population (which may be the entire population) and a particular set of generated features available to the model (which may be all generated features in the database). These subgroups and features are specified in a `.yaml` file (see the model specification file for [algorithm id 13](all_features_non_urm.yaml) or [algorithm id 23](all_features_urm.yaml) for examples.) This file should have the following sections:

### cohorts
A cohort is a particular group of applicants, both historical and current, to whom a particular algorithm should be applied (for example this might be all URM applicants). There should be a table or view in the database which labels all applicants as part of a particular cohort. This section specifies the name of that table, the column where the cohort label for each `(aamc_id, application_year)` is specified, and the value(s) of that column for the desired cohort. To train multiple algorithms on different values of that cohort label (i.e. `urm = "urm"` vs. `urm = "not urm"`), a model specification file should be constructed for each cohort.

### features
For every block of features to include in the model, there should be a table or view in the database called `vw$features$<feature_name>`. The last part of the table name, the `feature_name`, needs to be listed in this sections in order for its features to be available by the model. To include all features in a particular table, specify that `feature_name` with an empty list to exclude no features (e.g. `gpa: []`). To exclude specific features from the model without excluding the entire table, specify that `feature_name` with a list of features to be explicitly excluded (e.g. `gpa: [did_postbacc, attended_grad_school]`).

### outcomes
There should be a table or view in the database with the `(aamc_id, application_year)` for every eligible applicant (however eligible is defined), regardless of cohort status, in the historical data where the outcome is known. For example, we might define eligible as all applicants who submitted a complete application in 2013-2017, are not applying MD/PhD, passed an admissions pre-screening filter, and have not been previously considered eligible. All such eligible applicants will be listed in the table known as `vw$filtered$<historical_eligibility>` which is used to construct the outcomes table, `vw$outcomes$<outcome_name>`. This outcomes table lists each eligible applicant in the historical data along with their true outcome label to be used as the classification target for prediction. Classification may be binary or multiclass. This part of the model specification file should list the `outcome_name` associated with the appropriate outcome table for the classification task.

### predictions
There should be a table or view in the database with the `(aamc_id, application_year)` for every eligible applicant (however eligible is defined), regardless of cohort status, in the current testing data where the outcome may not be known. For example, we might define eligible as all applicants who submitted a complete application in 2018, are not applying MD/PhD, and passed an admissions pre-screening filter. All such eligible applicants will be listed in the table known as `vw$filtered$<current_eligibility>`. This part of the model specification file should list the `current_eligibility` part of the table name associated with the appropriate eligibility table.

### algorithm_name
This part of the model specification file should list a model tag to be used as the `algorithm_name` to refer to the algorithm constructed from this specification. This `algorithm_name` will be referenced in the `algorithm` table in the database linking an `algorithm_id` with its specification details. This `algorithm_name` will also be referenced in the compressed model `.pkl.z` file storing the binary representation of the trained model.

## Constructing training, validation, and test sets
### Training and validation sets
Currently, all applicants eligible under the algorithm for the training and validation sets (regardless of cohort) are listed in the table `vw$filtered$screened`. This table begins with applicants from application year 2013 and excludes the maximum application year (currently 2018). Since these application cycles have all been completed, all of these applicants should have known screening outcomes (currently listed in `vw$outcomes$screening`, see [Model specification](#model-specification) for further details). The view construction defines who is eligible: they must not have previously been eligible in an earlier application cycle (the first eligible application for each re-applicant will be selected), they must have a valid application submit date, application complete date, and screening complete date, they must be either Regular M.D. or Combined Medical Degree/Graduate (not MD/PhD), they must be applying in application years 2013-2017, and their combined faculty screening score must be known. Out of all these applicants, 20% will be randomly assigned to the hold-out validation set, and the remaining 80% will be used to train the model. Scores for each of these applicants will be written to the database in the `out$predictions$screening_train_val` table, and the column `set` will specify whether they were part of the training set (`set = "train"`) or part of the held-out validation set (`set = "test"`).
### Test set (current cohort)
Currently, all applicants eligible under the algorithm for the test set (regardless of cohort) are listed in the table `vw$filtered$screening_eligible`. If the current application cycle is underway, some of these may have already been screened, however, their true screening outcome will be ignored. Applicants are considered eligible for screening if they have a valid application submit date and application complete date, they are either Regular M.D. or Combined Medical Degree/Graduate (not MD/PhD), they are applying as part of the current application cycle, and they either have already been screened by faculty, are currently assigned to faculty for screening (`status = "SI"`) or they are eligible for screening under one of the screening eligibility filters provided by AMP (standard, URM, or postbacc). Scores for each of these applicants will be written to the database in the `out$predictions$screening_current_cohort`. Once a prediction for a particular `(aamc_id, application_year, algorithm_id)` has been written to the table, that prediction will not be generated again unless a new `algorithm_id` is provided.

## Cohorts: generating predictions for multiple subgroups
*Note that I refer to differing subgroups (i.e. URM, financially disadvantaged, postbacc) here as cohorts, but they are not cohorts in the traditional sense of belonging to a particular class year/application year.*

By creating multiple model specification files, we can train parallel models over multiple subgroups of eligible applicants. For each cohort grouping, there should be a column in a cohort specification view in the database (`vw$cohorts$<cohort_name>`) identifying which subgroup each eligible applicant (both historical and current) belongs to. A separate model will be fitted for each subgroup, each with its own corresponding `algorithm_id`, and we can make the same features available to each subgroup model. If we have subgroups A, B, and C, an algorithm will be trained only on the historical data for subgroup A and will generate predictions only on the current data for subgroup A, a second algorithm will be trained only on the historical data for subgroup B and will generate predictions only on the current data for subgroup B, and so on. Therefore there may be multiple algorithms marked as in production at a given time, each corresponding to a different cohort. When generating new predictions, the Bash script should specify all relevant production-level algorithms, and the modeling code will look up each new applicant in the database and determine which algorithm is appropriate to apply to that applicant. Scores for each of these applicants will be written to the database in the `out$predictions$screening_current_cohort` along with the `algorithm_id` that was used to generate the score. If this `algorithm_id` is `in_production = 1` and the score has not yet been sent to Admissions, the score will appear in the `vw$screen$send$predictions` table until the nightly push to EduDW and AMP.

# Training a model (once per application cycle)
Once all the relevant views have been created in the database (generated features, historical outcome labels, eligibility criteria, cohort membership) and the model specification files have been created, the models are ready to be trained.

If the conda environment has not yet been created, use the [`environment.yml`](environment.yml) file from this repo to create the environment. Update the `prefix` of the `environment.yml` file to the desired path for the conda environment.

```
conda env create -f environment.yml 
```

## Running the training script
To train new models, we need to run the `run_and_save_model.py` script with the `--fit` flag. Use the `--dyaml` flag to list the paths to each model specification file.

```
python run_and_save_model.py --fit \
    --pkldir <path to store pkls> \
    --dyaml <model specification 1> <model specification 2> ... \
    --credpath <path to db credentials> &> <path to store logs>
```
See [train_models.sh shell script](train_models.sh) for an example.

## Evaluating models and putting into production
Once the models have been trained, they should be evaluated by examining the predictions for the held-out validation data along with their corresponding features and cohort values. The algorithm names are specified in the model specification file for each algorithm under `algorithm_name`.

```
select p.* from out$predictions$screening_current_cohort p
where `set` = "test"
and algorithm_id in
(select id from algorithm
where algorithm_name in (<list of algorithm names>)
);
```
You can get the model data (features and outcomes) for each algorithm by running the following in Python:

```
from eduanalytics import model_data
conn = model_data.connect_to_database(
    <credentials path>, <credentials group>)

data, algorithm_id, algorithm_name = model_data.get_data_for_modeling(
    <model specification path>, conn)
```

If the models appear to be performing reasonably, set the new algorithms into production (and phase out any now-deprecated algorithms out of production).

```
update algorithm
set is_production = if(id in (<list of algorithm IDs>), 1, 0);
```

# Generating new predictions (once per day during admissions season)
Once a set of models has been selected for production, predictions can be generated by running the `run_and_save_model.py` script with the `--predict` flag. Use the `--dyaml` flag to list the paths to each model specification file and use the `--id` flag to list the algorithm ID corresponding to each model specification (algorithm IDs and model specification should be provided in the same order).

```
python run_and_save_model.py --predict \
    --id <id for model 1> <id for model 2> ... \
    --pkldir <path to store pkls> \
    --dyaml <model specification 1> <model specification 2> ... \
    --credpath <path to db credentials> &> <path to store logs>
```
See [run_simple.sh shell script](run_simple.sh) for an example.

Predictions will be generated only for `(aamc_id, application_year, algorithm_id)` that do not yet exist in the predictions table (`out$predictions$screening_current_cohort`). New predictions will then populate the `vw$screen$send$predictions` view as long as the `algorithm_id` is marked as `in_production = 1`. If these predictions do not appear in the AMP database, they will be pushed to AMP in the nightly scheduled Jenkins job.

## Running the prediction generation task on the server
The task of generating predictions should run on the server within a Docker container and should be scheduled to run daily (i.e. every weekday at noon). Detailed instructions for setting up the server and the Dockerfile for the container can be found in the [`admissions_server repo`](https://stash.nyumc.org/users/gutmaj03/repos/admissions_server/browse). If necessary, update the Bash script to be executed in the container with the appropriate arguments and paths.
