# Admissions Screening process

## Feature generation
Feature generation used to be done in R using the `dbUtilities` package developed by Suvam Paul and Jacqueline Gutman (see [our deprecated README](README_old.md)) but is now done predominantly in the research database directly using SQL views. For detailed documentation on the structure of these views and how they are generated, see documentation in the [Google Drive](https://drive.google.com/open?id=0B__nBZCrcLwjc2t4eU5pd0V3RGM) for this project, specifically our [data dictionary](https://docs.google.com/document/d/1OnS4kOclTdohz-5x7vS5auKelp7B4DySRKl6F-EU3cI/edit?usp=sharing) and [view construction specification](https://docs.google.com/a/med.nyu.edu/document/d/1OWY1iZsXPYPBHA8oou08APH5wQGFfYNZPpK1K7bTF_w/edit?usp=sharing). Raw input data for the views is provided by AMP developers and managed by EDS.

## Model specification
Each trained algorithm corresponds to a particular subgroup of the population (which may be the entire population) and a particular set of generated features available to the model (which may be all generated features in the database). These subgroups and features are specified in a `.yaml` file (see the model specification file for [algorithm id 13](all_features_non_urm.yaml) or [algorithm id 23](all_features_urm.yaml) for examples.) This file should have the following sections:

### cohorts
A cohort is a particular group of applicants, both historical and current, to whom a particular algorithm should be applied (for example this might be all URM applicants). There should be a table or view in the database which labels all applicants as part of a particular cohort. This section specifies the name of that table, the column where the cohort label for each `aamc_id, application_year` is specified, and the value(s) of that column for the desired cohort. To train multiple algorithms on different values of that cohort label (i.e. `urm = "urm"` vs. `urm = "not urm"`), a model specification file should be constructed for each cohort.

### features
For every block of features to include in the model, there should be a table or view in the database called `vw$features$<feature_name>`. The last part of the table name, the `feature_name`, needs to be listed in this sections in order for its features to be available by the model. To include all features in a particular table, specify that `feature_name` with an empty list to exclude no features (e.g. `gpa: []`). To exclude specific features from the model without excluding the entire table, specify that `feature_name` with a list of features to be explicitly excluded (e.g. `gpa: [did_postbacc, attended_grad_school]`).

### outcomes
There should be a table or view in the database with the `aamc_id, application_year` for every eligible applicant (however eligible is defined), regardless of cohort status, in the historical data where the outcome is known. For example, we might define eligible as all applicants who submitted a complete application in 2013-2017, are not applying MD/PhD, passed an admissions pre-screening filter, and have not been previously considered eligible. All such eligible applicants will be listed in the table known as `vw$filtered$<historical_eligibility>` which is used to construct the outcomes table, `vw$outcomes$<outcome_name>`. This outcomes table lists each eligible applicant in the historical data along with their true outcome label to be used as the classification target for prediction. Classification may be binary or multiclass. This part of the model specification file should list the `outcome_name` associated with the appropriate outcome table for the classification task.

### predictions
There should be a table or view in the database with the `aamc_id, application_year` for every eligible applicant (however eligible is defined), regardless of cohort status, in the current testing data where the outcome may not be known. For example, we might define eligible as all applicants who submitted a complete application in 2018, are not applying MD/PhD, and passed an admissions pre-screening filter. All such eligible applicants will be listed in the table known as `vw$filtered$<current_eligibility>`. This part of the model specification file should list the `current_eligibility` part of the table name associated with the appropriate eligibility table.

### algorithm_name
This part of the model specification file should list a model tag to be used as the `algorithm_name` to refer to the algorithm constructed from this specification. This `algorithm_name` will be referenced in the `algorithm` table in the database linking an `algorithm_id` with its specification details. This `algorithm_name` will also be referenced in the compressed model `.pkl.z` file storing the binary representation of the trained model.

## Constructing training, validation, and test sets
### Training and validation sets
Currently, all applicants eligible under the algorithm for the training and validation sets (regardless of cohort) are listed in the table `vw$filtered$screened`. This table begins with applicants from application year 2013 and excludes the maximum application year (currently 2018). Since these application cycles have all been completed, all of these applicants should have known screening outcomes (currently listed in `vw$outcomes$screening`, see [Model Specification](#model-specification) for further details).
