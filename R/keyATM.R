#' keyATM main function
#'
#' Fit keyATM models.
#'
#' @param docs texts read via [keyATM_read()]
#' @param model keyATM model: \code{base}, \code{covariates}, \code{dynamic}, and \code{label}
#' @param no_keyword_topics the number of regular topics
#' @param keywords a list of keywords
#' @param model_settings a list of model specific settings (details are in the online documentation)
#' @param priors a list of priors of parameters
#' @param options a list of options \itemize{
#'      \item \strong{seed}: A numeric value for random seed. If it is not provided, the package randomly selects a seed.
#'      \item \strong{iterations}: An integer. Number of iterations. Default is \code{1500}.
#'      \item \strong{verbose}: If \code{TRUE}, it prints loglikelihood and perplexity. Default is \code{FALSE}.
#'      \item \strong{llk_per}: An integer. If the value is \code{j} \strong{keyATM} stores loglikelihood and perplexity every \eqn{j} iteration. Default value is \code{10} per iterations
#'      \item \strong{use_weights}: If \code{TRUE} use weight. Default is \code{TRUE}.
#'      \item \strong{weights_type}: There are four types of weights. Weights based on the information theory (\code{information-theory}) and inverse frequency (\code{inv-freq}) and normalized versions of them (\code{information-theory-normalized} and \code{inv-freq-normalized}). Default is \code{information-theory}.
#'      \item \strong{prune}: If \code{TRUE} rume keywords that do not appear in the corpus. Default is \code{TRUE}.
#'      \item \strong{store_theta}: If \code{TRUE} or \code{1}, it stores \eqn{\theta} (document-topic distribution) for the iteration specified by thinning. Default is \code{FALSE} (same as \code{0}).
#'      \item \strong{store_pi}: If \code{TRUE} or \code{1}, it stores \eqn{\pi} (the probability of using keyword topic word distribution) for the iteration specified by thinning. Default is \code{FALSE} (same as \code{0}).
#'      \item \strong{thinning}: An integer. If the value is \code{j} \strong{keyATM} stores following parameters every \code{j} iteration. The default is \code{5}. \itemize{
#'            \item \emph{theta}: For all models. If \code{store_theta} is \code{TRUE} document-level topic assignment is stored (sufficient statistics to calculate document-topic distributions \code{theta}).
#'            \item \emph{alpha}: For the base and dynamic models. In the base model alpha is shared across all documents whereas each state has different alpha in the dynamic model.
#'            \item \emph{lambda}: coefficients in the covariate model.
#'            \item \emph{R}: For the dynamic model. The state each document belongs to.
#'            \item \emph{P}: For the dynamic model. The state transition probability.
#'      }
#'      \item \strong{parallel_init}: Parallelize processes to speed up initialization. Default is \code{FALSE}. Note that even if you use the same \code{seed}, the initialization will become different between with and without parallelization.
#' }
#' @param keep a vector of the names of elements you want to keep in output
#' 
#' @return A \code{keyATM_output} object containing:
#'   \describe{
#'     \item{keyword_k}{number of keyword topics}
#'     \item{no_keyword_topics}{number of no-keyword topics}
#'     \item{V}{number of terms (number of unique words)}
#'     \item{N}{number of documents}
#'     \item{model}{the name of the model}
#'     \item{theta}{topic proportions for each document (document-topic distribution)}
#'     \item{phi}{topic specific word generation probabilities (topic-word distribution)}
#'     \item{topic_counts}{number of tokens assigned to each topic}
#'     \item{word_counts}{number of times each word type appears}
#'     \item{doc_lens}{length of each document in tokens}
#'     \item{vocab}{words in the vocabulary (a vector of unique words)}
#'     \item{priors}{priors}
#'     \item{options}{options}
#'     \item{keywords_raw}{specified keywords}
#'     \item{model_fit}{perplexity and log-likelihood}
#'     \item{pi}{estimated \eqn{\pi} (the probability of using keyword topic word distribution) for the last iteration}
#'     \item{values_iter}{values stored during iterations}
#'     \item{kept_values}{outputs you specified to store in \code{keep} option}
#'     \item{information}{information about the fitting}
#'   }
#'
#' @seealso [save.keyATM_output()], \url{https://keyatm.github.io/keyATM/articles/pkgdown_files/Options.html}
#'
#' @examples
#' \dontrun{
#'   library(keyATM)
#'   library(quanteda)
#'   data(keyATM_data_bills)
#'   bills_keywords <- keyATM_data_bills$keywords
#'   bills_dfm <- keyATM_data_bills$doc_dfm  # quanteda dfm object
#'   keyATM_docs <- keyATM_read(bills_dfm)
#'
#'   # keyATM Base
#'   out <- keyATM(docs = keyATM_docs, model = "base",
#'                 no_keyword_topics = 5, keywords = bills_keywords)
#'
#'   # keyATM Covariates
#'   bills_cov <- as.data.frame(keyATM_data_bills$cov)
#'   out <- keyATM(docs = keyATM_docs, model = "covariates",
#'                 no_keyword_topics = 5, keywords = bills_keywords,
#'                 model_settings = list(covariates_data = bills_cov,
#'                                       covariates_formula = ~ RepParty))
#'
#'   # keyATM Dynamic
#'   bills_time_index <- keyATM_data_bills$time_index
#'   # Time index should start from 1 and increase by 1
#'   bills_time_index <- as.integer(bills_time_index - 100)
#'   out <- keyATM(docs = keyATM_docs, model = "dynamic",
#'                 no_keyword_topics = 5, keywords = bills_keywords,
#'                 model_settings = list(num_states = 5,
#'                                       time_index = bills_time_index))
#'
#'   # Visit our website for full examples: https://keyatm.github.io/keyATM/
#' }
#'
#' @export
keyATM <- function(docs, model, no_keyword_topics,
                   keywords = list(), model_settings = list(),
                   priors = list(), options = list(), keep = c())
{
  # Check type
  if (length(keep) != 0)
    check_arg_type(keep, "character")

  model <- full_model_name(model, type="keyATM")

  # Fit keyATM
  fitted <- keyATM_fit(
                       docs, model, no_keyword_topics,
                       keywords, model_settings, priors, options
                      )

  # 0 iterations
  if (fitted$options$iterations == 0) {
    return(fitted) 
  }

  # Get output
  out <- keyATM_output(fitted)

  # Keep some objects if specified
  keep <- check_arg_keep(keep, model)
  if (length(keep) != 0) {
    kept_values <- list()
    use_elements <- keep[keep %in% names(fitted)]
    for (i in 1:length(use_elements)) {
      kept_values[use_elements[i]]  <- fitted[use_elements[i]]
    }
    out$kept_values <- kept_values
  }

  # A bit of clean up
  if (fitted$options$store_theta && "stored_values" %in% keep) {
    # The same information
    out$kept_values$stored_values$Z_tables <- NULL
  }

  return(out)
}


check_arg_keep <- function(obj, model)
{
  if (model %in% c("cov", "ldacov")) {
    if (!"stored_values" %in% obj)
      obj <- c("stored_values", obj) 

    if (!"model_settings" %in% obj)
      obj <- c("model_settings", obj) 
  }

  return(obj)
}



#' Weighted LDA main function
#'
#' Fit weighted LDA models.
#'
#' @param docs texts read via [keyATM_read()]
#' @param model Weighted LDA model: \code{base}, \code{covariates}, and \code{dynamic}
#' @param number_of_topics the number of regular topics
#' @param model_settings a list of model specific settings (details are in the online documentation)
#' @param priors a list of priors of parameters
#' @param options a list of options (details are in the documentation of [keyATM()])
#' @param keep a vector of the names of elements you want to keep in output
#'
#' @return A \code{keyATM_output} object containing:
#'   \describe{
#'     \item{V}{number of terms (number of unique words)}
#'     \item{N}{number of documents}
#'     \item{model}{the name of the model}
#'     \item{theta}{topic proportions for each document (document-topic distribution)}
#'     \item{phi}{topic specific word generation probabilities (topic-word distribution)}
#'     \item{topic_counts}{number of tokens assigned to each topic}
#'     \item{word_counts}{number of times each word type appears}
#'     \item{doc_lens}{length of each document in tokens}
#'     \item{vocab}{words in the vocabulary (a vector of unique words)}
#'     \item{priors}{priors}
#'     \item{options}{options}
#'     \item{keywords_raw}{\code{NULL} for LDA models}
#'     \item{model_fit}{perplexity and log-likelihood}
#'     \item{pi}{estimated pi for the last iteration (\code{NULL} for LDA models)}
#'     \item{values_iter}{values stored during iterations}
#'     \item{number_of_topics}{number of topics}
#'     \item{kept_values}{outputs you specified to store in \code{keep} option}
#'     \item{information}{information about the fitting}
#'   }
#'
#' @seealso [save.keyATM_output()], \url{https://keyatm.github.io/keyATM/articles/pkgdown_files/Options.html}
#'
#' @examples
#' \dontrun{
#'   library(keyATM)
#'   library(quanteda)
#'   data(keyATM_data_bills)
#'   bills_dfm <- keyATM_data_bills$doc_dfm  # quanteda dfm object
#'   keyATM_docs <- keyATM_read(bills_dfm)
#'
#'   # Weighted LDA
#'   out <- weightedLDA(docs = keyATM_docs, model = "base",
#'                      number_of_topics = 5)
#'
#'   # Weighted LDA Covariates
#'   bills_cov <- as.data.frame(keyATM_data_bills$cov)
#'   out <- weightedLDA(docs = keyATM_docs, model = "covariates",
#'                      number_of_topics = 5,
#'                      model_settings = list(covariates_data = bills_cov,
#'                                            covariates_formula = ~ RepParty))                   
#'
#'   # Weighted LDA Dynamic
#'   bills_time_index <- keyATM_data_bills$time_index
#'   # Time index should start from 1 and increase by 1
#'   bills_time_index <- as.integer(bills_time_index - 100)
#'   out <- weightedLDA(docs = keyATM_docs, model = "dynamic",
#'                      number_of_topics = 5,
#'                      model_settings = list(num_states = 5,
#'                                            time_index = bills_time_index))
#'
#'   # Visit our website for full examples: https://keyatm.github.io/keyATM/
#' }
#'
#' @export
weightedLDA <- function(docs, model, number_of_topics,
                        model_settings = list(),
                        priors = list(), options = list(), keep = c())
{
  # Check type
  if (length(keep) != 0)
    check_arg_type(keep, "character")

  model <- full_model_name(model, type="lda")

  # Fit keyATM
  fitted <- keyATM_fit(
                       docs, model, number_of_topics,
                       keywords = list(),
                       model_settings = model_settings,
                       priors = priors,
                       options = options
                      )

  # 0 iterations
  if (fitted$options$iterations == 0) {
    return(fitted) 
  }

  # Get output
  out <- keyATM_output(fitted)
  out$number_of_topics <- number_of_topics
  out$no_keyword_topics <- NULL
  out$keyword_k <- NULL

  # Keep some objects if specified
  if (length(keep) != 0) {
    kept_values <- list()
    use_elements <- keep[keep %in% names(fitted)]
    for(i in 1:length(use_elements)) {
      kept_values[use_elements[i]] <- fitted[use_elements[i]]
    }
    out$kept_values <- kept_values
  }

  return(out)
}


