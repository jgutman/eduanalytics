import eduanalytics
from eduanalytics import model_data, pipeline_tools, reporting

import re, os, sys, logging
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn

from sklearn.pipeline import make_pipeline
from sklearn import ensemble, linear_model, metrics, preprocessing
from sklearn.model_selection import GridSearchCV
from argparse import ArgumentParser


def fit_pipeline(model_matrix, grid_path, pkldir,
        scoring = 'roc_auc', # 'f1_micro',
        alg_id = 'debug',
        write_predictions = True,
        path = None, group = None):

    # other possible steps:
    # feature_selection.VarianceThreshold
    pipeline = make_pipeline(pipeline_tools.DummyEncoder(),
                preprocessing.Imputer(),
                ensemble.RandomForestClassifier(random_state = 1100))
    param_grid = pipeline_tools.build_param_grid(pipeline, grid_path)
    grid_search = GridSearchCV(pipeline,
        n_jobs = -1,
        cv = 5,
        param_grid = param_grid,
        scoring = scoring)

    # Adjust test_size for debugging runs
    X_train, X_test, y_train, y_test, lb = model_data.split_data(
        model_matrix, test_size = .99)

    with pipeline_tools.Timer() as t:
        logging.info('fitting the grid search')
        grid_search.fit(X_train, y_train)

    logging.info(reporting.pickle_model(grid_search,
        pkldir, lb, alg_id, model_tag = 'screening_rf'))

    if write_predictions:
        engine = model_data.connect_to_database(path, group)
        train_results = reporting.get_results(grid_search, X_train, y_train, lb)
        test_results = reporting.get_results(grid_search, X_test, y_test, lb)
        reporting.output_predictions(train_results, test_results,
            engine, alg_id = alg_id)

    return grid_search, lb

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
    parser.add_argument('--pretrain', dest = 'predict_current',
        default = True, action = 'store_false')
    parser.set_defaults(
        path = eduanalytics.credentials_path,
        group = eduanalytics.credentials_group,
        dyaml = 'model_data_opts.yaml',
        grid_path = 'grid_options.yaml',
        pkldir = eduanalytics.pkl_path)
    args = parser.parse_args()

    logging.basicConfig(format = "%(asctime)s\t%(levelname)s: %(message)s",
        level = logging.DEBUG, datefmt = "%m/%d/%y %I:%M %p")
    engine = model_data.connect_to_database(args.path, args.group)


    model_matrix, alg_id = model_data.get_data_for_modeling(
        filename = args.dyaml, engine = engine)

    pipeline, label_encoder = fit_pipeline(model_matrix, args.grid_path,
        pkldir = args.pkldir, alg_id = alg_id,
        path = args.path, group = args.group)

    if args.predict_current:
        logging.info(reporting.write_current_predictions(pipeline,
            filename = args.dyaml, conn = engine,
            label_encoder = label_encoder, alg_id = alg_id))


if __name__ == '__main__':
    main()
