import configparser
import sqlalchemy
import pandas as pd
import string, os, re
import yaml, json, itertools
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
        data[col].nunique() == 2 and not re.search('_[ABCDF]$', col)))
    string_cols = set(col for col in data if data[col].dtype == 'O')
    categoricals = binary_cols.union(string_cols)
    data_categorical = data.astype({col: 'category' for col in categoricals})
    return data_categorical


def describe_model(filename, engine):
    """
    """
    with open(filename) as f:
        model_opts = yaml.load(f)

    algorithm_name = model_opts['algorithm_name']
    algorithm_description = json.dumps(model_opts)

    feature_tbls = {"'vw$features${}'".format(tbl_name): cols_to_drop
        for tbl_name, cols_to_drop
        in model_opts['features'].items()}

    column_query = """select column_name
    from information_schema.columns
    where table_name in ({feature_string})
    and column_name not in ('aamc_id', 'application_year');""".format(
        feature_string = ", ".join(feature_tbls.keys()))

    column_names = pd.read_sql_query(column_query, engine)
    column_names = set(column_names.column_name)
    drop_cols = set(itertools.chain(*feature_tbls.values()))

    if drop_cols:
        column_names = column_names - drop_cols

    algorithm_details = json.dumps(list(column_names))

    x = pd.DataFrame({'algorithm_name': [algorithm_name],
            'algorithm_description': [algorithm_description],
            'algorithm_details': [algorithm_details]})
    x.to_sql('algorithm', engine, index = False, if_exists = 'append')

    algorithm_id = pd.read_sql_query('select max(id) from algorithm',
        engine).iloc[0,0]
    return model_opts, algorithm_id


def get_data_for_prediction(filename, engine):
    """Return a dataframe for the desired data for the current unlabeled
    cohort with the features specified in the yaml file.

    Args:
        filename (str): path to YAML file with cohort, outcome, and
            feature specification for desired model data
        engine (sqlalchemy.Engine): a connection to the MySQL database
    Returns:
        Pandas.DataFrame: dataframe with Multi-index of aamc id and application year
            for applicants with known outcomes and qualifying cohort variables
        str: algorithm_id description for database and pkl file to denote
            which algorithm settings were used in fitting the model
    """
    with open(filename) as f:
        model_opts = yaml.load(f)

    current_applicants_query = """select aamc_id, application_year
        from vw$filtered${}""".format(model_opts['predictions'])

    features = loop_through_features(engine, model_opts['features'],
        subquery = current_applicants_query)

    current_data = features[0].join(features[1:])
    return current_data


def loop_through_features(engine, features_dict, subquery):
    """
    """
    feature_tbls = {"vw$features${}".format(tbl_name): cols_to_drop
        for tbl_name, cols_to_drop
        in features_dict.items()}

    features = list()
    for feature_tbl, drop_cols in feature_tbls.items():
        get_features = """select * from `{feature_tbl}`
        where (aamc_id, application_year) in ({query})""".format(
            feature_tbl = feature_tbl,
            query = subquery)
        feature_data = pd.read_sql_query(get_features, engine,
            index_col = ['aamc_id', 'application_year'])
        if drop_cols:
            feature_data.drop(drop_cols, axis = 1, inplace = True)
        features.append(feature_data)
    return features


def get_data_for_modeling(filename, engine):
    """Return a dataframe containing features specified by the yaml file for
    records meeting the cohort criteria specified in the yaml file.
    Includes the true outcome label from the database.

    Args:
        filename (str): path to YAML file with cohort, outcome, and
            feature specification for desired model data
        engine (sqlalchemy.Engine): a connection to the MySQL database
    Returns:
        Pandas.DataFrame: dataframe with Multi-index of aamc id and application year
            for applicants with known outcomes and qualifying cohort variables
        str: algorithm_id description for database and pkl file to denote
            which algorithm settings were used in fitting the model
    """
    model_opts, algorithm_id = describe_model(filename, engine)

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

    features = loop_through_features(engine, model_opts['features'],
        subquery = get_cohort)

    model_data = outcome_data.join(features)
    model_data = convert_categorical(model_data)
    return model_data, algorithm_id


def split_data(model_matrix, outcome_name = 'outcome',
        seed = 1100, test_size = .25):
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
