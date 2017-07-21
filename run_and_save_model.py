import eduanalytics
from eduanalytics import model_data, pipeline_tools, reporting

import re, os, sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn

from sklearn.pipeline import make_pipeline
from sklearn import ensemble, linear_model, metrics, preprocessing
from sklearn.model_selection import GridSearchCV
from argparse import ArgumentParser


def fit_pipeline(model_matrix, grid_path,
        scoring = 'roc_auc', # 'f1_micro',
        write_predictions = False,
        path = None, group = None, tbl_name = None):
    pipeline = make_pipeline(pipeline_tools.DummyEncoder(),
                preprocessing.Imputer(),
                ensemble.RandomForestClassifier(random_state = 1100))
    param_grid = pipeline_tools.build_param_grid(pipeline, grid_path)
    grid_search = GridSearchCV(pipeline,
        n_jobs = -1,
        cv = 5,
        param_grid = param_grid,
        scoring = scoring)

    X_train, X_test, y_train, y_test, lb = model_data.split_data(model_matrix)

    with pipeline_tools.Timer() as t:
        print('fitting the grid search')
        grid_search.fit(X_train, y_train)

    if write_predictions:
        engine = model_data.connect_to_database(path, group)
        train_results = reporting.get_results(grid_search, X_train, y_train, lb)
        test_results = reporting.get_results(grid_search, X_test, y_test, lb)
        reporting.output_predictions(train_results, test_results,
            engine, name = tbl_name)

    return grid_search

def main(args=None):
    parser = ArgumentParser()
    parser.add_argument('--dyaml', dest = 'data_yaml',
        help = 'Path to the model data yaml file')
    parser.add_argument('--credpath', dest = 'path',
        help = 'Path to the db credentials file')
    parser.add_argument('--credgroup', dest = 'group',
        help = 'Name of group for db credentials file')
    parser.add_argument('--gridpath', dest = 'grid_path',
        help = 'Path to the grid search options yaml file')
    parser.add_argument('--pkldir', dest = 'pkldir',
        help = 'Path to store binary compressed model files')
    parser.set_defaults(
        path = eduanalytics.credentials_path,
        group = eduanalytics.credentials_group,
        dyaml = 'model_data_opts.yaml',
        grid_path = 'grid_options.yaml',
        pkldir = 'pkls')
    args = parser.parse_args()

    engine = model_data.connect_to_database(args.path, args.group)
    model_matrix = model_data.get_data_for_modeling(
        filename = args.dyaml, engine = engine)

    assert ('outcome' in model_matrix.columns
        ), "missing outcome column"
    assert ('aamc_id' in model_matrix.index.names
        and 'application_year' in model_matrix.index.names
        ), "invalid index cols"

    pipeline = fit_pipeline(model_matrix,
        args.grid_path,
        write_predictions = True,
        path = args.path, group = args.group, tbl_name = args.tbl_name)

    reporting.pickle_model(pipeline, args.pkldir, args.tbl_name, 'rf_grid')

if __name__ == '__main__':
    main()
