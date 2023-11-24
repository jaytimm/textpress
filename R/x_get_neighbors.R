#' Compute Similarity Between Matrices
#'
#' This function computes the cosine similarity between two matrices,
#' normalizing them based on the specified norm.
#'
#' @param x A numeric matrix or a sparse matrix.
#' @param y An optional numeric matrix or a sparse matrix to be compared with `x`.
#' @param norm Character, either "l2" or "none" for normalization method.
#'
#' @return A matrix of cosine similarity values.
#' @export
#'
#' @examples
#' x <- matrix(rnorm(50), nrow = 10)
#' # Self-similarity
#' sim_matrix <- get_sim(x)
#' # Similarity with another matrix
#' y <- matrix(rnorm(50), nrow = 10)
#' sim_matrix <- get_sim(x, y)

get_sim <- function(x, y = NULL, norm = c("l2", "none")) {

  norm <- match.arg(norm)

  stopifnot(is.matrix(x) || inherits(x, "sparseMatrix"))

  if (!is.null(y)) {
    stopifnot(is.matrix(y) || inherits(y, "sparseMatrix"))
    stopifnot(ncol(x) == ncol(y))
    stopifnot(all(colnames(x) == colnames(y)))
  }

  normalize <- function(m, norm) {
    if (norm == "none") {
      return(m)
    }

    norm_vec <- if (norm == "l2") {
      1 / sqrt(rowSums(m ^ 2))
    } else {
      rep(1, nrow(m))
    }

    norm_vec[is.infinite(norm_vec)] <- 0

    if (inherits(m, "sparseMatrix")) {
      Matrix::rowScale(m, norm_vec)
    } else {
      m * norm_vec
    }
  }

  x <- normalize(x, norm)
  if (!is.null(y)) {
    y <- normalize(y, norm)
    return(tcrossprod(x, y))
  } else {
    return(tcrossprod(x))
  }
}


#' Find Nearest Neighbors Based on Cosine Similarity
#'
#' This function identifies the nearest neighbors of a given term or vector
#' in a matrix based on cosine similarity.
#'
#' @param x A character or numeric vector representing the term or vector.
#' @param matrix A numeric matrix or a sparse matrix against which the similarity is calculated.
#' @param n Number of nearest neighbors to return.
#'
#' @return A data frame with the ranks, terms, and their cosine similarity scores.
#' @export
#'
#' @examples
#' matrix <- matrix(rnorm(100), ncol = 10)
#' term <- rnorm(10)
#' neighbors <- x_get_neighbors(term, matrix, 5)
#'
x_get_neighbors <- function(x, matrix, n = 10) {
  # Validate inputs
  if (!is.character(x) && !is.numeric(x)) {
    stop("The first argument 'x' must be either a character or numeric vector.")
  }

  if (!(is.matrix(matrix) || inherits(matrix, "sparseMatrix"))) {
    stop("The second argument 'matrix' must be a matrix or a sparse matrix.")
  }

  if (!is.numeric(n) || length(n) != 1) {
    stop("The 'n' must be a single numeric value.")
  }

  # Extract row from 'matrix' based on 'x'
  t0 <- if (is.character(x)) {
    matrix[x, , drop = FALSE]
  } else {
    # If 'x' is already a numeric vector
    x
  }

  # Compute cosine similarity using the 'sim2' function
  cos_sim <- get_sim(matrix, t0, norm = "l2")

  # Extract the top 'n' similar terms
  sim_scores <- cos_sim[, 1]
  top_n_indices <- order(sim_scores, decreasing = TRUE)[1:n]
  top_n_scores <- sim_scores[top_n_indices]

  # Create a data frame with results
  data.frame(rank = 1:n,
             term1 = rownames(t0),
             term2 = rownames(matrix)[top_n_indices],
             cos_sim = round(top_n_scores, 3),
             row.names = NULL)
}

