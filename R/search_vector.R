#' Nearest neighbors by cosine similarity (vector search)
#'
#' Returns the top-\code{n} nearest rows in an embedding matrix to a query
#' (row name or numeric vector). Local search over a dense/sparse matrix you
#' provide. textpress does not generate embeddings; use packages such as
#' \pkg{reticulate} (sentence-transformers), \pkg{word2vec}, or \pkg{fastText}
#' to create the matrix, then pass it here.
#'
#' @param x A character (row name in \code{matrix}) or numeric vector (query embedding).
#' @param matrix A numeric or sparse matrix of embeddings (rows = documents/units).
#' @param n Number of nearest neighbors to return (default 10).
#'
#' @return A data frame with \code{rank}, \code{term1}, \code{term2}, \code{cos_sim}.
#' @export
#' @examples
#' \dontrun{
#' # Assume you have an embedding matrix from another package
#' # m <- your_embed_function(corpus)
#' # search_neighbors("doc_1", matrix = m, n = 5)
#' }
search_neighbors <- function(x,
                                  matrix,
                                  n = 10) {
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
  cos_sim <- .get_sim(matrix, t0, norm = "l2")

  # Extract the top 'n' similar terms
  sim_scores <- cos_sim[, 1]
  top_n_indices <- order(sim_scores, decreasing = TRUE)[1:n]
  top_n_scores <- sim_scores[top_n_indices]

  # Create a data frame with results
  data.frame(
    rank = 1:n,
    term1 = rownames(t0),
    term2 = rownames(matrix)[top_n_indices],
    cos_sim = round(top_n_scores, 3),
    row.names = NULL
  )
}


#' Vector search over an embedding matrix
#'
#' Alias for \code{\link{search_neighbors}}. Returns the top-\code{n} nearest
#' rows by cosine similarity. Use this name when you want the trio
#' \code{search_corpus} (regex), \code{search_index} (BM25), \code{search_vector} (embeddings).
#'
#' @param x Query: row name in \code{matrix} or numeric vector (embedding).
#' @param matrix Embedding matrix (rows = documents/units).
#' @param n Number of results (default 10).
#' @return A data frame with \code{rank}, \code{term1}, \code{term2}, \code{cos_sim}.
#' @export
search_vector <- function(x, matrix, n = 10) {
  search_neighbors(x = x, matrix = matrix, n = n)
}


#' Compute Similarity Between Matrices
#'
#' This function computes the cosine similarity between two matrices,
#' normalizing them based on the specified norm. Logic from text2vec package
#' (Selivanov, 2016) <doi:10.32614/CRAN.package.text2vec>.
#'
#' @param x A numeric matrix or a sparse matrix.
#' @param y An optional numeric matrix or a sparse matrix to be compared with `x`.
#' @param norm Character, either "l2" or "none" for normalization method.
#'
#' @return A matrix of cosine similarity values.
#' @noRd
#'
.get_sim <- function(x,
                     y = NULL,
                     norm = c("l2", "none")) {
  # Match the 'norm' argument with one of the specified options ("l2", "none")

  norm <- match.arg(norm)

  # Ensure 'x' is either a matrix or a sparse matrix
  stopifnot(is.matrix(x) || inherits(x, "sparseMatrix"))

  # If 'y' is provided, perform checks similar to 'x' and ensure dimension compatibility
  if (!is.null(y)) {
    stopifnot(is.matrix(y) || inherits(y, "sparseMatrix"))
    stopifnot(ncol(x) == ncol(y))
    stopifnot(all(colnames(x) == colnames(y)))
  }

  # Define a nested function 'normalize' to normalize matrices
  normalize <- function(m, norm) {
    # If no normalization is required, return the matrix as-is
    if (norm == "none") {
      return(m)
    }

    # Calculate the normalization vector based on L2 norm or unit norm
    norm_vec <- if (norm == "l2") {
      1 / sqrt(rowSums(m^2))
    } else {
      rep(1, nrow(m))
    }

    # Replace infinite values in the normalization vector with zeros
    norm_vec[is.infinite(norm_vec)] <- 0

    # Apply normalization to the matrix, supporting both dense and sparse matrices
    if (inherits(m, "sparseMatrix")) {
      Matrix::rowScale(m, norm_vec)
    } else {
      m * norm_vec
    }
  }

  # Normalize 'x' and optionally 'y' using the specified norm
  x <- normalize(x, norm)
  if (!is.null(y)) {
    y <- normalize(y, norm)
    # Return the cross-product of the normalized matrices
    return(tcrossprod(x, y))
  } else {
    # Return the cross-product of 'x' with itself if 'y' is not provided
    return(tcrossprod(x))
  }
}
