import eduanalytics
from eduanalytics import model_data, pipeline_tools, reporting

import re, os, sys, logging
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn

from sklearn.pipeline import make_pipeline
from sklearn import ensemble, linear_model, metrics
from sklearn import feature_selection, preprocessing
from sklearn.model_selection import GridSearchCV
from argparse import ArgumentParser


def fit_pipeline(model_matrix, grid_path, pkldir,
    scoring = 'roc_auc', # 'f1_micro',
    alg_id = 'debug', write_predictions = True,
    path = None, group = None):
    """
    """

    pipeline = make_pipeline(pipeline_tools.DummyEncoder(),
            preprocessing.Imputer(),
            feature_selection.VarianceThreshold(),
            ensemble.RandomForestClassifier(random_state = 1100))
    param_grid = pipeline_tools.build_param_grid(pipeline, grid_path)
    grid_search = GridSearchCV(pipeline,
        n_jobs = -1,
        cv = 5,
        param_grid = param_grid,
        scoring = scoring)

    # Adjust test_size for debugging runs
    X_train, X_test, y_train, y_test, lb = model_data.split_data(
        model_matrix, test_size = .20)

    with pipeline_tools.Timer() as t:
        logging.info('fitting the grid search')
        grid_search.fit(X_train, y_train)

    logging.info(reporting.pickle_model(grid_search,
        pkldir, lb, alg_id, model_tag = 'screening_rf'))

    if write_predictions:
        engine = model_data.connect_to_database(path, group)
        train_results = reporting.get_results(grid_search, X_train, y_train, lb)
        test_results = reporting.get_results(grid_search, X_test, y_test, lb)
        logging.info(reporting.output_predictions(
            train_results, test_results, engine, alg_id = alg_id))
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
    parser.add_argument('--fit', dest = 'train_model',
        default = False, action = 'store_true',
        help = 'Train the model from scratch')
    parser.add_argument('--predict', dest = 'predict_new',
        default = False, action = 'store_true',
        help = 'Generate predictions on new data')
    parser.add_argument('--id', dest = 'alg_id', type = int,
        help = 'Algorithm id for pre-trained models')
    parser.set_defaults(
        path = eduanalytics.credentials_path,
        group = eduanalytics.credentials_group,
        dyaml = 'model_data_opts.yaml',
        grid_path = 'grid_options.yaml',
        pkldir = eduanalytics.pkl_path,
        alg_id = 0)
    args = parser.parse_args()

    logging.basicConfig(format = "%(asctime)s\t %(message)s",
        level = logging.DEBUG, datefmt = "%m/%d/%y %I:%M:%S %p")
    engine = model_data.connect_to_database(args.path, args.group)

    if args.train_model:
        model_matrix, alg_id = model_data.get_data_for_modeling(
            filename = args.dyaml, engine = engine)
        pipeline, label_encoder = fit_pipeline(
            model_matrix, args.grid_path,
            pkldir = args.pkldir, alg_id = alg_id,
            path = args.path, group = args.group)
    else:
        alg_id = args.alg_id
        pipeline, label_encoder = reporting.load_model(
            args.pkldir, alg_id, model_tag = "screening_rf")

    if args.predict_new:
        logging.info(reporting.write_current_predictions(
            pipeline, filename = args.dyaml, conn = engine,
            label_encoder = label_encoder, alg_id = alg_id))


if __name__ == '__main__':
    main()
