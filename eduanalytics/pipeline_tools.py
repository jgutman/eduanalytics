from sklearn.pipeline import TransformerMixin
from sklearn.base import BaseEstimator
import pandas as pd
import re
import yaml

def extract_step_from_pipeline(cv_pipeline, step_name):
    """Extract the object corresponding to an explicitly named step from the
    modeling pipeline.

    Args:
        cv_pipeline (sklearn.Pipeline): a Pipeline object embedded in a
            GridSearchCV object containing a list of named steps
        step_name (str): a step name contained in the list of steps for the best
            fitted estimator found under GridSearch
    Returns:
        obj: an object with a .fit() and .transform() method with parameters
            selected by grid search
    """
    steps = cv_pipeline.best_estimator_.named_steps
    return steps.get(step_name)


def describe_pipeline_steps(cv_pipeline):
    """Returns a list of names of all steps in a fitted modeling pipeline.

    Args:
        cv_pipeline (sklearn.Pipeline): a Pipeline object embedded in a
            GridSearchCV object containing a list of named steps
    Returns:
        list[str]: a list of strings containing all pipeline step names
    """
    steps = cv_pipeline.best_estimator_.named_steps
    return list(steps.keys())


def extract_model_from_pipeline(cv_pipeline):
    """Extract the object corresponding to the final model estimator
    (classifier or regressor) for the best fitted estimator of the pipeline.

    Args:
        cv_pipeline (sklearn.Pipeline): a Pipeline object embedded in a
            GridSearchCV object containing a list of named steps
    Returns:
        sklearn.estimator: a fitted model estimator object with a .predict()
            method (and for classifiers, .predict_proba / .decision_function)
    """
    steps = describe_pipeline_steps(cv_pipeline)
    pattern = "(classifier|regressor)$"
    prog = re.compile(pattern)
    model_step_name = [step for step in steps if bool(prog.search(step))]
    model_step = extract_step_from_pipeline(cv_pipeline, model_step_name[-1])
    return model_step


def get_transformed_columns(cv_pipeline, encoder_step, data):
    """Returns a list of column names in the transformed data after applying an
    encoder transformation to the data.

    Args:
        cv_pipeline (sklearn.Pipeline): a Pipeline object embedded in a
            GridSearchCV object containing a list of named steps
        encoder_step (sklearn.Transformer): a sklearn fitted feature encoder
            with a .fit() and .transform() method
    Returns:
        pandas.Index: an index of all column names in the transformed data
    """
    encoder_step = extract_step_from_pipeline(cv_pipeline, encoder_step)
    transformed_data = encoder_step.transform(data)
    return transformed_data.columns


def build_param_grid(pipeline, grid_path):
    """Looks up pipeline steps in grid options yaml file and builds the
    appropriate parameter grid for steps in the pipeline.

    Args:
        pipeline (sklearn.Pipeline): a pipeline object with named_steps attribute
        grid_path: path to a yaml file containing the grid options to use
    Returns:
        dict: dictionary with step names as keys and parameter options as values
    """
    with open(grid_path, 'r') as f:
        grid = yaml.load(f)
    steps = set(pipeline.named_steps.keys())

    param_grid = dict()
    for step in steps.intersection(grid.keys()):
        options = grid.get(step)
        new_options = {'{step_name}__{option_name}'.format(
            step_name = step,
            option_name = option): value for option, value in
            options.items()}
        param_grid.update(new_options)
    return param_grid


class DummyEncoder(BaseEstimator, TransformerMixin):
    """A one-hot encoder transformer with fit and transform methods.

    Suitable for use in a pipeline. Adds indicator variables for NAs,
    drops dummy for first level of categorical.
    """
    def __init__(self):
        self.columns = None
        self.transformed_columns = None

    def transform(self, X, y=None, **kwargs):
        transformed = pd.get_dummies(X,
            columns = self.columns,
            drop_first = True,
            dummy_na = True)
        return transformed[self.transformed_columns]

    def fit(self, X, y=None, **kwargs):
        self.columns = X.select_dtypes(
            include = ['object', 'category']).columns
        transformed = pd.get_dummies(X,
            columns = self.columns,
            drop_first = True,
            dummy_na = True)

        cols = transformed.apply(pd.Series.nunique)
        transformed = transformed.drop(cols[cols == 1].index, axis = 1)
        self.transformed_columns = transformed.columns
        return transformed
