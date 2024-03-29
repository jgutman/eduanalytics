% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/missingness_functions.R
\name{explore_missingness}
\alias{explore_missingness}
\title{Function to create a list of aggr objects from a list of tibbles}
\usage{
explore_missingness(df_list, plot = TRUE)
}
\arguments{
\item{df_list}{a list of tibbles or data frames}

\item{plot}{a logical indicating whether the results should be plotted. if
plot = TRUE, plots missing proportions and patterns and prints
proportions of missings in each var for each tibble in list. if plot = FALSE outputs
only the number of observations missing for each variable. if plot = FALSE and output
is saved to an object, nothing automaitcally prints}
}
\value{
a list of aggr objects
}
\description{
Function to create a list of aggr objects from a list of tibbles
}
