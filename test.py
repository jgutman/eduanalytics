import eduanalytics
from eduanalytics import model_data, pipeline_tools, reporting
from sklearn.pipeline import make_pipeline
from sklearn import ensemble, linear_model, metrics, preprocessing
from sklearn.model_selection import GridSearchCV
import pandas as pd

path = eduanalytics.credentials_path
group = eduanalytics.credentials_group
dyaml = 'model_data_opts.yaml'
grid_path = 'grid_options.yaml'
pkldir = 'pkls'

engine = model_data.connect_to_database(path, group)


model_matrix = model_data.get_data_for_modeling(
    filename = dyaml, engine = engine)
scoring = 'roc_auc'

pipeline = make_pipeline(pipeline_tools.DummyEncoder(),
            preprocessing.Imputer(),
            ensemble.RandomForestClassifier(random_state = 1100))

param_grid = pipeline_tools.build_param_grid(
    pipeline, grid_path)
grid_search = GridSearchCV(pipeline,
    n_jobs = -1,
    cv = 5,
    param_grid = param_grid,
    scoring = scoring)

X_train, X_test, y_train, y_test, lb = model_data.split_data(
    model_matrix, test_size = .99)

with pipeline_tools.Timer() as t:
    print('fitting the grid search')
    grid_search.fit(X_train, y_train)

train_results = reporting.get_results(grid_search, X_train, y_train, lb)
test_results = reporting.get_results(grid_search, X_test, y_test, lb)


############

import eduanalytics
from eduanalytics import model_data, reporting, pipeline_tools

pkl_path = eduanalytics.pkl_path
engine = model_data.connect_to_database(eduanalytics.credentials_path,
    eduanalytics.credentials_group)
alg_id = 3
model_tag = "screening_rf"
clf, label_encoder = reporting.load_model(pkl_path, alg_id, model_tag)

filename = "model_data_opts.yaml"
current_data = model_data.get_data_for_prediction(filename, engine)

results = reporting.get_results(clf, current_data,
    y = None, lb = label_encoder)
