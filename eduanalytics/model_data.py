import configparser
import sqlalchemy
import pandas as pd
import os
from sklearn.model_selection import train_test_split

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


def get_data_for_modeling(engine, tbl_name,
        id = 'deidentified', status = 'model_data'):
    """Return a dataframe for the desired table from the database.
    Currently does not handle datetime variables or unstructured text.

    Args:
        engine (sqlalchemy.Engine): a connection to the MySQL database
        tbl_name (str): name of the table to pull down from the db
    Returns:
        Pandas.DataFrame: dataframe with row index of study id and mix of
            categoricals and numeric variables
    """
    get_table = 'select * from {id}${status}${tbl_name}'.format(
        id = id, status = status, tbl_name = tbl_name)
    model_matrix = pd.read_sql_query(get_table, engine)
    model_matrix = model_matrix.set_index('study_id')
    model_matrix = model_matrix.astype({'appl_year': int})
    model_matrix = convert_categorical(model_matrix)
    return model_matrix


def convert_categorical(data):
    """Converts binary and string columns to Pandas Categoricals.

    Args:
        data (Pandas.DataFrame): a dataframe containing some binary
            (of any dtype) or string columns to be converted to categorical
    Returns:
        Pandas.DataFrame: dataframe with mix of categoricals and numeric cols
    """
    binary_cols = set(col for col in data if (
        data[col].nunique() == 2 and not col.endswith('counts')))
    string_cols = set(col for col in data if data[col].dtype == 'O')
    categoricals = binary_cols.union(string_cols)
    categoricals.add('appl_year')
    data_categorical = data.astype({col: 'category' for col in categoricals})
    return data_categorical


def split_data(model_matrix, outcome_name = 'outcome',
        seed = 1100, test_size = .20):
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
    """
    X, y = model_matrix.drop(outcome_name, axis = 1), model_matrix[outcome_name]
    X_train, X_test, y_train, y_test = train_test_split(X, y,
                            test_size = test_size, random_state = seed)
    y_train, y_test = y_train.astype(int), y_test.astype(int)
    return X_train, X_test, y_train, y_test
