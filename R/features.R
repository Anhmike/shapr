#' Get combinations
#'
#' @inheritParams global_arguments
#'
#' @details
#' The returned data.table contains the following columns
#' \describe{
#' \item{ID}{Positive integer. Unique key for combination}
#' \item{features}{List of integer vectors}
#' \item{nfeatures}{Positive integer}
#' \item{N}{Positive integer}
#' }
#'
#' @return data.table
#'
#' @export
#'
#' @author Nikolai Sellereite, Martin Jullum
feature_combinations <- function(m, exact = TRUE, noSamp = 200, shapley_weight_inf_replacement = 10^6, reduce_dim = TRUE) {

  # Not supported for m > 30
  if (m > 30) {
    stop("Currently we are not supporting cases where m > 30.")
  }

  if (!exact && noSamp > (2^m - 2) && !reduce_dim) {
    noSamp <- 2^m - 2
    cat(sprintf("noSamp is larger than 2^m = %d. Using exact instead.", 2^m))
  }

  if (exact) {
    dt <- feature_exact(m, shapley_weight_inf_replacement)
  } else {
    dt <- feature_not_exact(m, noSamp, shapley_weight_inf_replacement, reduce_dim)
  }

  return(dt)
}

#' @keywords internal
#' @export
feature_exact <- function(m, shapley_weight_inf_replacement = 10^6) {

  dt <- data.table::data.table(ID = seq(2^m))
  combinations <- lapply(0:m, utils::combn, x = m, simplify = FALSE)
  dt[, features := unlist(combinations, recursive = FALSE)]
  dt[, nfeatures := length(features[[1]]), ID]
  dt[, N := .N, nfeatures]
  dt[, shapley_weight := shapley_weights(m = m, N = N, s = nfeatures, shapley_weight_inf_replacement)]
  dt[, no := 1]

  return(dt)
}

#' @keywords internal
#' @export
feature_not_exact <- function(m, noSamp = 200, shapley_weight_inf_replacement = 10^6, reduce_dim = TRUE) {

  # Find weights for given number of features ----------
  nfeatures <- seq(m - 1)
  n <- sapply(nfeatures, choose, n = m)
  w <- shapley_weights(m = m, N = n, s = nfeatures) * n
  p <- w / sum(w)

  # Sample number of chosen features ----------
  X <- data.table::data.table(
    nfeatures = c(
      0,
      sample(
        x = nfeatures,
        size = noSamp,
        replace = TRUE,
        prob = p
      ),
      m
    )
  )
  X[, nfeatures := as.integer(nfeatures)]

  # Sample specific set of features -------
  data.table::setkey(X, nfeatures)
  feature_sample <- sample_features_cpp(m, X[["nfeatures"]])

  # Get number of occurences and duplicated rows-------
  r <- helper_feature(m, feature_sample)
  X[, no := r[["no"]]]
  X[, is_duplicate := r[["is_duplicate"]]]
  X[, ID := .I]

  # Populate table and remove duplicated rows -------
  X[, features := feature_sample]
  if (reduce_dim && any(X[["is_duplicate"]])) {
    X <- X[is_duplicate == FALSE]
    X[, no := 1]
  }
  X[, is_duplicate := NULL]
  nms <- c("ID", "nfeatures", "features", "no")
  data.table::setcolorder(X, nms)

  # Add shapley weight and number of combinations
  X[, shapley_weight := shapley_weight_inf_replacement]
  X[, N := 1]
  X[between(nfeatures, 1, m - 1), ind := TRUE]
  X[ind == TRUE, shapley_weight := p[nfeatures]]
  X[ind == TRUE, N := n[nfeatures]]
  X[, ind := NULL]

  # Set column order and key table
  nms <- c("ID", "features", "nfeatures", "N", "shapley_weight", "no")
  data.table::setcolorder(X, nms)
  data.table::setkey(X, nfeatures)
  X[, ID := .I]
  X[, N := as.integer(N)]

  return(X)
}

#' @keywords internal
helper_feature <- function(m, feature_sample) {

  x <- feature_matrix_cpp(feature_sample, m)
  dt <- data.table::data.table(x)
  cnms <- paste0("V", seq(m))
  data.table::setnames(dt, cnms)
  dt[, no := as.integer(.N), by = cnms]
  dt[, is_duplicate := duplicated(dt)]
  dt[, (cnms) := NULL]

  return(dt)
}