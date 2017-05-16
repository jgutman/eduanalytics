import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, precision_recall_curve, roc_auc_score
import itertools, os
from collections import OrderedDict
from sklearn.externals import joblib

def get_results(clf, X, y, lb):
    """Get a data frame with study_id, appl_year, outcome

    Args:
    Returns:
    """
    multiclass = y.shape[1] > 2
    y_flat = lb.inverse_transform(y)
    y_flat = pd.DataFrame(y_flat,
        columns = ['outcome'], index = X.index)
    raw_scores = clf.predict_proba(X)
    if multiclass:
        scores = convert_multiclass_predictions(raw_scores, lb, X.index)
    else:
        scores = convert_binary_predictions(raw_scores, lb, X.index)
    return scores.join([y_flat, X.appl_year])


def convert_multiclass_predictions(scores, lb, study_ids):
    """

    Args:
    Returns:
    """
    scores_per_class = [p[:,1] for p in scores]
    scores_flat = np.vstack(scores_per_class).T
    class_names = ['predicted_{}'.format(int(p)) for p in lb.classes_]
    scores_df = pd.DataFrame(scores_flat,
        columns = class_names, index = study_ids)
    return scores_df

def convert_binary_predictions(scores, lb, study_ids):
    """

    Args:
    Returns:
    """
    scores_df = pd.DataFrame(scores[:,1],
        columns = ['predicted'], index = study_ids)
    return scores_df


def output_predictions(train_results, test_results, conn, name,
        id = 'deidentified', status = 'predictions'):
    """Write the true labels and prediction scores to a table in the database.

    Args:
    Returns:
    """
    name = '{id}${status}${name}'.format(
        id = id, status = status, name = name)
    train_results['set'] = 'train'
    test_results['set'] = 'test'
    results = pd.concat([train_results, test_results]).reset_index()
    results.to_sql(name, conn, if_exists = 'replace', index = False)


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
    ax1.set_ylabel('precision', color='b')
    ax2 = ax1.twinx()
    ax2.plot( pct_positive_at_thresh, recall, 'r' )
    ax2.set_ylabel('recall', color='r')
    ax1.set_ylim([0,1])
    ax1.set_ylim([0,1])
    ax2.set_xlim([0,1])

    plt.suptitle(model_name)
    plt.title('Precision vs. Recall by Percent Identified: AUC = {:0.2f}'.format(
        roc_auc_score(y_true, y_score)))
    plt.show()


def pickle_model(clf, pkl_path, tbl_name, model_tag):
    """Write a sklearn object to disk in binary compressed format.

    Args:
        clf (sklearn.GridSearchCV/Estimator): the model to persist to disk
        pkl_path (str): name of the directory to store the pkl files
        tbl_name (str): shortname of the model data to tag the model with
        model_tag (str): other info such as model type to tag the model with
    """
    filename = '{tbl_name}_{model_tag}.pkl.z'.format(
        tbl_name = tbl_name, model_tag = model_tag)
    joblib.dump(clf, os.path.join(pkl_path, filename))
    print('Written to: {} in {}'.format(filename, pkl_path))


def load_model(pkl_path, tbl_name, model_tag):
    """Load a sklearn object from disk saved in binary compressed format.

    Args:
        pkl_path (str): name of the directory to store the pkl files
        tbl_name (str): shortname of the model data to tag the model with
        model_tag (str): other info such as model type to tag the model with
    Returns:
        sklearn.GridSearchCV or Estimator: uncompressed sklearn model
    """
    filename = '{tbl_name}_{model_tag}.pkl.z'.format(
        tbl_name = tbl_name, model_tag = model_tag)
    clf = joblib.load(os.path.join(pkl_path, filename))
    return clf
