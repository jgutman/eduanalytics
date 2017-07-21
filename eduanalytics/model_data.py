import configparser
import sqlalchemy
import pandas as pd
import string, os, re, yaml
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelBinarizer

def connect_to_database(credentials_path, group,
        filename = '.my.cnf'):
    """Read in a database credentials text file and return an engine
    connecting to the MySQL database.

    Args:
        credentials_path (str): path to the database credentials file
        group (str): name of the group containing the desired credentials
        filename (str): filename (without path) of the credentials file
    Returns:
        sqlalchemy.Engine: a connection to the MySQL database
    """
    reader = configparser.RawConfigParser()
    reader.read(os.path.join(credentials_path, filename))
    connection_string = 'mysql+pymysql://{user}:{password}@{host}:{port}/{dbname}'.format(
        user = reader.get(group, 'user'),
        password = reader.get(group, 'password'),
        host = reader.get(group, 'host'),
        port = reader.get(group, 'port'),
        dbname = reader.get(group, 'database')
    )
    engine = sqlalchemy.create_engine(connection_string)
    return engine


def convert_categorical(data):
    """Converts binary and string columns to Pandas Categoricals.

    Args:
        data (Pandas.DataFrame): a dataframe containing some binary
            (of any dtype) or string columns to be converted to categorical
    Returns:
        Pandas.DataFrame: dataframe with mix of categoricals and numeric cols
    """
    binary_cols = set(col for col in data if (
        data[col].nunique() == 2 and not re.search(
        '_[ABCDF]$', col)))
    string_cols = set(col for col in data if data[col].dtype == 'O')
    categoricals = binary_cols.union(string_cols)
    data_categorical = data.astype({col: 'category' for col in categoricals})
    return data_categorical


def get_data_for_modeling(filename, engine):
    """Return a dataframe for the desired table from the database.
    Currently does not handle datetime variables or unstructured text.

    Args:
        filename (str): path to YAML file with cohort, outcome, and
            feature specification for desired model data
        engine (sqlalchemy.Engine): a connection to the MySQL database
    Returns:
        Pandas.DataFrame: dataframe with Multi-index of aamc id and application year
            for applicants with known outcomes and qualifying cohort variables
    """
    with open(filename) as f:
        model_opts = yaml.load(f)

    cohort_vals = model_opts['cohorts']['included']
    get_cohort = """select aamc_id, application_year
        from `vw$cohorts${cohort_tbl}`
        where {cohort_col} in ({cohort_vals})""".format(
            cohort_tbl = model_opts['cohorts']['tbl'],
            cohort_col = model_opts['cohorts']['col'],
            cohort_vals = ",".join(["'{}'".format(i) for i in cohort_vals]))

    get_outcomes = """select *
        from `vw$outcomes${outcome_tbl}`
        where (aamc_id, application_year) in
        ({cohort_query})""".format(
            outcome_tbl = model_opts['outcomes'],
            cohort_query = get_cohort)

    outcome_data = pd.read_sql_query(get_outcomes, engine,
        index_col = ['aamc_id', 'application_year'])

    feature_tbls = ["vw$features${}".format(
        tbl_name) for tbl_name in model_opts['features']]

    for feature_tbl in feature_tbls:
        get_features = """select * from `{feature_tbl}`
        where (aamc_id, application_year) in
        ({cohort_query})""".format(
            feature_tbl = feature_tbl,
            cohort_query = get_cohort)
        feature_data = pd.read_sql_query(get_features, engine,
            index_col = ['aamc_id', 'application_year'])
        outcome_data = outcome_data.merge(feature_data, how = 'left',
            left_index = True, right_index = True)

    outcome_data = convert_categorical(outcome_data)
    return outcome_data


def split_data(model_matrix, outcome_name = 'outcome',
        seed = 1100, test_size = .33):
    """Splits a data set into training and test and separates features (X)
    from target variable (y).

    Args:
        model_matrix (Pandas.DataFrame): data containing features and outcome
        outcome_name (str): name of column containing outcome variable
        seed (int): integer for random state variable
        test_size (float): proportion of data to hold out for testing
    Returns:
        Pandas.DataFrame: training features
        Pandas.DataFrame: testing features
        numpy.ndarray: training target labels
        numpy.ndarray: testing target labels
        sklearn.LabelBinarizer: transforms multiclass labels into binary dummies
    """
    X, y = model_matrix.drop(outcome_name, axis = 1), model_matrix[outcome_name]
    X_train, X_test, y_train, y_test = train_test_split(X, y,
            test_size = test_size, random_state = seed, stratify = y)
    lb = LabelBinarizer().fit(y_train)
    y_train, y_test = lb.transform(y_train), lb.transform(y_test)
    if len(lb.classes_) == 2:
        y_train, y_test = y_train[:,1], y_test[:,1]
    return X_train, X_test, y_train, y_test, lb
