import eduanalytics
from eduanalytics import model_data, pipeline_tools, reporting

import re, os, sys, logging
import pandas as pd
import numpy as np

from sklearn.pipeline import make_pipeline
from sklearn import ensemble, feature_selection, preprocessing
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV
from argparse import ArgumentParser

args = dict()
args['data_yaml'] = ['all_features_non_urm.yaml', 'all_features_urm.yaml']
args['path'] = eduanalytics.credentials_path
args['group'] = eduanalytics.credentials_group
args['grid_path'] = 'grid_options_simple.yaml'
args['pkldir'] = 'pkls'
args['train_model'] = True
args['predict_new'] = True
args['alg_id'] = None

engine = model_data.connect_to_database(args['path'], args['group'])

def fit_pipeline(model_matrix, grid_path, pkldir,
    alg_id = 'debug', alg_name = 'screening_rf',
    scoring = 'roc_auc', # 'f1_micro',
    write_predictions = True, path = None, group = None):
    """Train a new model over a grid search and optionally write train and test
    set predictions to the database.

    Args:
        model_matrix (Pandas.DataFrame): features and outcome variables for
            train and test set
        grid_path (str): path to file containing all pipeline options for the
            grid search as a yaml file
        pkldir (str): path to the directory to output the compressed model
            pickle file for the fitted model
        alg_id (str/int): an algorithm id to denote the fitted model in both
            the database and the saved pickle file
        alg_name (str): a short descriptor of the algorithm pulled from the
            model options file
        scoring (str): can also be a scorer callable object / function with
            signature scorer(estimator, X, y) for grid search optimization
        write_predictions (bool):
        path (str): credentials path to reconnect to the database in order to
            output predictions on train and test set
        group (str): credentials group to reconnect to the database
    Returns:
        (GridSearchCV, LabelBinarizer)
    """

    pipeline = make_pipeline(pipeline_tools.DummyEncoder(),
            preprocessing.Imputer(),
            feature_selection.VarianceThreshold(),
            ensemble.RandomForestClassifier(random_state = 1100))
    param_grid = pipeline_tools.build_param_grid(pipeline, grid_path)
    grid_search = GridSearchCV(pipeline, n_jobs = -1, cv = 5,
        param_grid = param_grid, scoring = scoring,
        verbose = 2) # show folds and model fits as they complete

    # Adjust test_size for debugging runs
    X_train, X_test, y_train, y_test, lb = model_data.split_data(
        model_matrix, test_size = .75)

    with pipeline_tools.Timer() as t:
        logging.info('fitting the grid search')
        grid_search.fit(X_train, y_train)

    logging.info(reporting.pickle_model(grid_search,
        pkldir, lb, alg_id, model_tag = alg_name))

    if write_predictions:
        engine = model_data.connect_to_database(path, group)
        train_results = reporting.get_results(grid_search, X_train, y_train, lb)
        test_results = reporting.get_results(grid_search, X_test, y_test, lb)
        logging.info(reporting.output_predictions(
            train_results, test_results, engine, alg_id = alg_id))
    return grid_search, lb

alg_id_list = []
pipelines = []
for dyaml in args['data_yaml']:
    model_matrix, alg_id, alg_name = model_data.get_data_for_modeling(
        filename = dyaml, engine = engine)
    alg_id_list.append(alg_id)
    pipelines.append(fit_pipeline(
        model_matrix, args['grid_path'], args['pkldir'],
        alg_id, alg_name, path = args['path'], group = args['group']))

assert len(pipelines)==len(alg_id_list), "IDs don't match models"

for pipeline, dyaml, alg_id in zip(
        pipelines, args['data_yaml'], alg_id_list):
    logging.info(reporting.write_current_predictions(
        pipeline[0], filename = dyaml, conn = engine,
        label_encoder = pipeline[1], alg_id = alg_id))
