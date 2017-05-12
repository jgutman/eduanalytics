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
        scoring = 'roc_auc',
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

    X_train, X_test, y_train, y_test = model_data.split_data(model_matrix)

    with pipeline_tools.Timer() as t:
        print('fitting the grid search')
        grid_search.fit(X_train, y_train)

    if write_predictions:
        engine = model_data.connect_to_database(path, group)
        risk_scores = grid_search.predict_proba(X_test)[:,1]
        reporting.output_predictions(y_test, risk_scores, X_test,
            engine, name = tbl_name)

    return grid_search

def main(args=None):
    parser = ArgumentParser()
    parser.add_argument('--tbl', dest = 'tbl_name',
        help = 'Table name suffix containing model data')
    parser.add_argument('--id', dest = 'tbl_id',
        help = 'Staging area of table (first prefix)')
    parser.add_argument('--status', dest = 'tbl_status',
        help = 'Schema name of table (second prefix)')
    parser.add_argument('--credpath', dest = 'path',
        help = 'Path to the db credentials file')
    parser.add_argument('--credgroup', dest = 'group',
        help = 'Name of group for db credentials file')
    parser.add_argument('--gridpath', dest = 'grid_path',
        help = 'Path to the grid search options yaml file')
    parser.add_argument('--pkldir', dest = 'pkldir',
        help = 'Path to store binary compressed model files')
    parser.set_defaults(path = eduanalytics.credentials_path,
        group = eduanalytics.credentials_group,
        tbl_id = 'deidentified',
        tbl_status = 'model_data',
        grid_path = 'grid_options.yaml',
        pkldir = 'pkls')
    args = parser.parse_args()

    engine = model_data.connect_to_database(args.path, args.group)
    # print(*engine.table_names(), sep = '\n')
    model_matrix = model_data.get_data_for_modeling(engine,
        tbl_name = args.tbl_name,
        id = args.tbl_id, status = args.tbl_status)

    assert ('outcome' in model_matrix.columns
        ), "missing outcome column in {}${}${}".format(
        args.tbl_name, args.tbl_id, args.tbl_status)
    # print(model_matrix.outcome.value_counts())

    pipeline = fit_pipeline(model_matrix, args.grid_path,
        write_predictions = True,
        path = args.path, group = args.group, tbl_name = args.tbl_name)

    reporting.pickle_model(pipeline, args.pkldir, args.tbl_name, 'rf_grid')

if __name__ == '__main__':
    main()
