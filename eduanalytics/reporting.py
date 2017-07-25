import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, precision_recall_curve, roc_auc_score
from eduanalytics import model_data
import itertools, os
from collections import OrderedDict
from sklearn.externals import joblib

def get_results(clf, X, y, lb):
    """Takes a trained model, model matrix, and output data and
    returns a DataFrame of true and predicted output for all X, y

    Args:
        clf (sklearn.estimator): a fitted estimator with predict_proba
            method (could eventually be extended to decision_function)
        X (Pandas.DataFrame): df with index or Multi-index and all
            features needed for clf.predict_proba method
        y (Numpy array): a numpy array transformed with lb.transform
            to hold a column for each class in lb.classes_, giving
            true outcome in binarized one-hot encoded format
        lb (sklearn.LabelBinarizer): a label binarizer holding the
            original class labels and transformation mechanism

    Returns:
        Pandas.DataFrame: a dataframe with index or Multi-index, and a
        column for the true outcome, as well as one column per class (in
        multiclass problems) giving the prediction score for that class
    """
    raw_scores = clf.predict_proba(X)
    if len(lb.classes_) > 2:
        scores = convert_multiclass_predictions(raw_scores, lb, X.index)
    else:
        scores = convert_binary_predictions(raw_scores, lb, X.index)
    if y is not None:
        y_flat = lb.inverse_transform(y)
        y_flat = pd.DataFrame(y_flat,
            columns = ['outcome'], index = X.index)
        scores = y_flat.join(scores)
    return scores


def convert_multiclass_predictions(scores, lb, ids):
    """Converts raw numpy array of one-hot encoded prediction scores to a
    one row per record Pandas DataFrame with index and column names

    Args:
        scores (list[Numpy array]): raw prediction scores in a list of
            numpy arrays, with each element of the list giving binary
            predictions in two columns i.e. (not class X, class X)
        lb (sklearn.LabelBinarizer): a label binarizer holding the
            original class labels
        ids (Pandas.index): an index or Multi-index for the raw scores
    Returns:
        Pandas.DataFrame: df with index and columns labeled
        predicted_{class_name} for each class in LabelBinarizer
    """
    scores_per_class = [p[:,1] for p in scores]
    scores_flat = np.vstack(scores_per_class).T
    class_names = ['predicted_{}'.format(p) for p in lb.classes_]
    scores_df = pd.DataFrame(scores_flat,
        columns = class_names, index = ids)
    return scores_df


def convert_binary_predictions(scores, lb, ids):
    """Converts raw numpy array of one-hot encoded prediction scores to a
    one row per record Pandas DataFrame with index and column names

    Args:
        scores (Numpy array): raw prediction scores with the second
            column giving the probability of the positive class
        lb (sklearn.LabelBinarizer): a label binarizer holding the
            original positive and negative class labels
        ids (Pandas.index): an index or Multi-index for the raw scores
    Returns:
        Pandas.DataFrame: df with index and 1 column labeled
        predicted_{class_name} for positive class in LabelBinarizer
    """
    class_names = 'predicted_{}'.format(lb.classes_[1])
    scores_df = pd.DataFrame(scores[:,1],
        columns = class_names, index = ids)
    return scores_df


def output_predictions(train_results, test_results, conn,
    alg_id = 'debug', tbl_name = 'screening_train_val'):
    """Write the true labels and prediction scores to a table in the database.

    Args:
        train_results (Pandas.DataFrame): indexed true and predicted output for
            all training data
        test_results (Pandas.DataFrame): indexed true and predicted output for
            all test data
        conn (sqlalchemy.Engine): a connection to the MySQL database
        alg_id (str): a name for the algorithm id to store the model results by
        tbl_name (str): a name for the database table holding all results
    Returns:
        str: the name of the table in the database
    """
    name = "out$predictions${}".format(tbl_name)
    train_results['set'] = 'train'
    test_results['set'] = 'test'
    results = pd.concat([train_results, test_results])
    results['algorithm_id'] = alg_id
    results.to_sql(name, conn, if_exists = 'append',
        index_label = results.index.names)
    return "Added to database {}: algorithm_id = {}".format(name, alg_id)


def write_current_predictions(clf, filename, conn, label_encoder, alg_id,
    tbl_name = 'screening_current_cohort'):
    """

    Args:
    Returns:
    """
    current_data = model_data.get_data_for_prediction(filename, conn)
    results = get_results(clf, current_data,
        y = None, lb = label_encoder)
    name = "out$predictions${}".format(tbl_name)
    results['algorithm_id'] = alg_id
    results.to_sql(name, conn, if_exists = 'append',
        index_label = results.index.names)
    return "Added to database {}: algorithm_id = {}".format(name, alg_id)


def build_confusion_matrix(true, predicted, class_names,
        model_name = None, normalize = False, plot = True):
    """Return and optionally plot a confusion matrix for the true and
    predicted class labels.

    Args:
        true (numpy.ndarray): array of true class labels
        predicted (numpy.ndarray): array of predicted class labels
        class_names (list[str]): list of names of the classes, in order
        model_name (str): name for the model to serve as plot title
        normalize (bool): whether to normalize rows and return proportions
            for each true class
        plot (bool): whether to plot the confusion matrix
    Returns:
        Pandas.DataFrame: dataframe with true labels as rows, predicted labels
            as columns, and cell values as counts
    """
    cm = confusion_matrix(true, predicted)
    np.set_printoptions(precision=2)

    if normalize:
        cm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]

    if plot:
        title = '{model_name} ({nums})'.format(model_name = model_name,
            nums = 'proportions' if normalize else 'counts')
        plot_confusion_matrix(cm, class_names, title)

    cm = pd.DataFrame(cm, index = class_names, columns = class_names)
    return cm


def plot_confusion_matrix(cm, class_names, title,
        cmap = plt.cm.Blues):
    """Plots the confusion matrix with color gradients.

    Args:
        cm (numpy.ndarray): a square confusion matrix with true labels as rows
            and predicted labels as columns
        class_names (list[str]): list of names of the classes, in order
        title (str): plot title
        cmap (pyplot.colors): colors for plot (see more colors at
            https://matplotlib.org/examples/color/colormaps_reference.html)
    """
    plt.imshow(cm, interpolation = 'nearest', cmap = cmap)
    plt.title(title)
    plt.colorbar()
    n_classes = len(class_names)

    tick_marks = np.arange(n_classes)
    plt.xticks(tick_marks, class_names, rotation = 45)
    plt.yticks(tick_marks, class_names)
    thresh = cm.max() / 2.

    for i, j in itertools.product(range(n_classes), range(n_classes)):
        plt.text(j, i, cm[i, j],
                 horizontalalignment = "center",
                 color = "white" if cm[i, j] > thresh else "black")

    plt.tight_layout()
    plt.ylabel('True label')
    plt.xlabel('Predicted label')


def compute_feature_importances_ensemble(clf, transformed_columns,
        print_output = True):
    """Returns the overall feature importances and their variability for all .

    Args:
        clf (sklearn.ensemble.estimator): a sklearn ensemble estimator with
            .feature_importances_ and .estimators_ attributes
        transformed_columns (list[str]): list of names of the features
            as used by the estimator
        print_output (bool): whether or not to print the feature importances
            for all features along with their scores in descending order
    Returns:
        list[float]: unranked list of the feature importances
        list[float]: unranked list of standard deviation of the
            feature importances within the model
        list[int]: indices for ranking features in descending order
    """
    importances = clf.feature_importances_
    # variability in feature importance within components of the ensemble
    std = np.std([tree.feature_importances_ for tree in clf.estimators_],
             axis=0) # standard deviation of individual feature importances
    indices = np.argsort(importances)[::-1] # descending order
    n_cols = len(transformed_columns)

    # Print the feature ranking
    if print_output:
        print_feature_importances(importances, transformed_columns, indices)
    return importances, std, indices


def print_feature_importances(importances, column_labels, indices):
    """Prints the feature importances ranked in descending order along with
    their rank and importance score.

    Args:
        importances (list[float]): unranked list of the feature importances
        column_labels (list[str]): unranked list of names of the features
        indices (list[int]): indices for ranking features in descending order
    """
    labeled_importances = OrderedDict(zip(
        column_labels[indices], importances[indices]))

    for rank, (feature, score) in enumerate(labeled_importances.items()):
        print('{num}: {feature} = {score:0.3f}'.format(
            num = rank + 1, feature = feature, score = score))


def plot_feature_importances(importances, std, indices, transformed_columns,
        top_n = 15):
    """Plots the top n feature importances ranked in descending order along with
    an error bar corresponding to variability across components of the ensemble.

    Args:
        importances (list[float]): unranked list of the feature importances
        std (list[float]): unranked list of standard deviation of the
            feature importances within the model
        indices (list[int]): indices for ranking features in descending order
        transformed_columns (list[str]): unranked list of names of the features
        top_n (int): how many features should be included in the plot
    """
    top_n = min( len(importances), top_n)
    top_n_indices = indices[:top_n]
    plt.title("Feature importances")
    plt.bar(range(top_n), importances[top_n_indices],
       color= 'b', yerr = std[top_n_indices], align = 'center')
    plt.xticks(range(top_n), transformed_columns[top_n_indices], rotation = 90)
    plt.xlim([-1, top_n])
    plt.show()


def generate_binary_at_k(y_scores, k):
    """Thresholds predicted probability at a cutoff that will classify
    exactly k percent of the scores as 1 and the rest as 0.

    Args:
        y_scores (numpy.ndarray): predicted probabilities for a single class label
        k (float): a specified percentage to classify as class 1
    Returns:
        numpy.ndarray: binary hard predictions with k percent in class 1
    """
    k = k / 100.0 if k >= 1 else k
    cutoff_index = int(len(y_scores) * k)
    indices = np.argsort(y_scores)[::-1]
    cutoff = y_scores[indices][cutoff_index]
    test_predictions_binary = [1 if y > cutoff else 0 for y in y_scores]
    return test_predictions_binary


def plot_precision_recall_n(y_true, y_score, model_name):
    """Plots both precision and recall against the percent of population
    classified as the positive class.

    Args:
        y_true (numpy.ndarray): true class labels for the population
        y_score (numpy.ndarray): predicted probabilities for class 1
        model_name (str): title for the plot
    """
    precision, recall, thresholds = precision_recall_curve(
        y_true, y_score)

    precision = precision[:-1]
    recall = recall[:-1]

    pct_positive_at_thresh = []
    number_scored = len(y_score)

    for threshold in thresholds:
        num_above_thresh = len( y_score[y_score >= threshold] )
        pct_above_thresh = num_above_thresh / float(number_scored)
        pct_positive_at_thresh.append( pct_above_thresh )
    pct_positive_at_thresh = np.array( pct_positive_at_thresh )

    plt.clf()
    fig, ax1 = plt.subplots()
    ax1.plot( pct_positive_at_thresh, precision, 'b' )
    ax1.set_xlabel('percent of population')
    ax1.set_ylabel('positive predictive value', color='b')
    ax2 = ax1.twinx()
    ax2.plot( pct_positive_at_thresh, recall, 'r' )
    ax2.set_ylabel('true positive rate', color='r')
    ax1.set_ylim([0,1])
    ax1.set_ylim([0,1])
    ax2.set_xlim([0,1])

    plt.suptitle(model_name)
    plt.title('Precision vs. Recall by Percent Identified: AUC = {:0.2f}'.format(
        roc_auc_score(y_true, y_score)))
    plt.show()


def pickle_model(clf, pkl_path, label_encoder, alg_id, model_tag):
    """Write a sklearn object to disk in binary compressed format.

    Args:
        clf (sklearn.GridSearchCV/Estimator): the model to persist to disk
        pkl_path (str): name of the directory to store the pkl files
        tbl_name (str): shortname of the algorithm id for the model
        model_tag (str): other info to tag the model with
    Returns:
        str: a message giving the path where the model has been saved
    """
    filename = "id{}_{}.pkl.z".format(alg_id, model_tag)
    model_plus_encoder = {'pipeline': clf, 'encoder': label_encoder}
    joblib.dump(model_plus_encoder,
        os.path.join(pkl_path, filename))
    output = "Written compressed model to: {} in {}".format(
        filename, pkl_path)
    return output


def load_model(pkl_path, alg_id, model_tag):
    """Load a sklearn object from disk saved in binary compressed format.

    Args:
        pkl_path (str): name of the directory to store the pkl files
        alg_id (str): shortname of the algorithm_id for the model
        model_tag (str): other info such as model type to tag the model with
    Returns:
        sklearn.GridSearchCV or Estimator: uncompressed sklearn model
    """
    filename = "id{}_{}.pkl.z".format(alg_id, model_tag)
    model_plus_encoder = joblib.load(os.path.join(pkl_path, filename))
    clf = model_plus_encoder['pipeline']
    encoder = model_plus_encoder['encoder']
    return clf, encoder
