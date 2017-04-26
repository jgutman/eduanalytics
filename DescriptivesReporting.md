# Automated Descriptives Reporting Skeleton

We want to automatically generate a descriptives report common to all datasets, where we can add dataset-specific descriptive functionality later. These reports should inform the cleaning process as much as possible.

## Missingness Analysis
* For a dataset, grouped by application year:
    - For every column, what is the percent missingness?
          data %>%
          group_by(appl_year) %>%
          summarize_all(funs(pct_missing = mean(is.na(.))))
    - Transpose for nicer display
* Using package `VIM` display an aggregation graphic (`VIM::aggr`) showing the correlations of missingness in the data.
    - Play around with the options to find a better way of exploring and visualizing the most significant patterns of missingness in the data.

## Group Features by Column Type
* For each feature, determine whether type is
    - Categorical (text)
    - Numeric
    - Date (should be parsed as `dttm` by function `convert_or_retain` within `put_tbl_to_memory`)
* Automatically summarize each feature by report type appropriate for the given column type

## Categorical Features
* For each feature, grouped by application year:
    - What is the total number of unique categories within that column?
    - What is the proportion falling into each category (if more than 10 categories, limit to top 10)?

## Numeric Features
* For each feature, grouped by application year:
    - minimum value?
    - maximum value?
    - median value?
    - 25% value?
    - 75% value?
    - mean value?
    - standard deviation?
* For all numeric features, pairwise correlation matrix
    - omitting missing values (missingness correlation reported in missingness analysis section)
* Best way to visualize distributions?
    - histograms?
    - density plots?
    - boxplots?

## Date Features
* For each feature, grouped by application year:
    - Rank order dates and compute quantiles
    - minimum date?
    - maximum date?
    - date falling at 25% percentile of all dates?
    - date falling at 50% percentile of all dates?
    - date falling at 75% percentile of all dates?

# Organize individual descriptive functions into report
Develop reporting notebook (possibly grouping individual functions into master `generate_report` functions to string descriptive operations together) to call standard reporting template, looping through all datasets in a given list of tables (i.e. starting with all `deidentified$clean$*` tables)
