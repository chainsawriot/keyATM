% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/posterior.R
\name{by_strata_DocTopic}
\alias{by_strata_DocTopic}
\title{Estimate document-topic distribution by strata (for covariate models)}
\usage{
by_strata_DocTopic(
  x,
  by_var,
  labels,
  by_values = NULL,
  burn_in = NULL,
  parallel = TRUE,
  mc.cores = NULL,
  posterior_mean = TRUE
)
}
\arguments{
\item{x}{the output from the covariate keyATM model (see \code{\link[=keyATM]{keyATM()}})}

\item{by_var}{character. The name of the variable to use.}

\item{labels}{character. The labels for the values specified in \code{by_var} (ascending order).}

\item{by_values}{numeric. Specific values for \code{by_var}, ordered from small to large. If it is not specified, all values in \code{by_var} will be used.}

\item{burn_in}{integer. Burn-in period. If not specified, it is the half of samples. Default is \code{NULL}.}

\item{parallel}{logical. If \code{TRUE}, parallelization for speeding up. Default is \code{TRUE}.}

\item{mc.cores}{integer. The number of cores to use. Default is \code{NULL}.}

\item{posterior_mean}{logical. If \code{TRUE}, the quantity of interest to estimate is the posterior mean. Default is \code{TRUE}.}
}
\value{
strata_topicword object (a list)
}
\description{
Estimate document-topic distribution by strata (for covariate models)
}
