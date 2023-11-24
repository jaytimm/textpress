#' Find Nearest Neighbors Based on Cosine Similarity
#'
#' This function calculates the nearest neighbors of a given term or vector
#' based on cosine similarity using a specified matrix.
#' It returns the top 'n' nearest neighbors.
#'
#' @param x A character vector (term) or numeric vector.
#' @param matrix A matrix against which the similarity of 'x' is calculated.
#' @param n The number of nearest neighbors to return.
#' @return A data frame with the rank, terms, and their cosine similarity scores.
#' @importFrom text2vec sim2
#' @examples
#' # Example usage
#' # matrix <- matrix(rnorm(100), ncol = 10)
#' # wd_get_NN("example_term", matrix, 5)

#' @export
#' @rdname x_get_neighbors
#'

x_get_neighbors <- function(x,
                              matrix,
                              n = 10) {


  # Validate inputs
  if (!is.character(x) && !is.numeric(x)) {
    stop("The first argument 'x' must be either a character or numeric vector.")
  }

  if (!is.matrix(matrix)) {
    stop("The second argument 'matrix' must be a matrix.")
  }

  if (!is.numeric(n) || length(n) != 1) {
    stop("The 'n' must be a single numeric value.")
  }


  if(is.character(x)){
    t0 <- matrix[x, , drop = FALSE]} else{
      ## a vector -- in theory --
      t0 <- x}

  cos_sim <- sim2(x = matrix,
                            y = t0,
                            method = "cosine",
                            norm = "l2")

  x1 <- head(sort(cos_sim[,1], decreasing = TRUE), n)

  data.frame(rank = 1:n,
             term1 = rownames(t0),
             term2 = names(x1),
             cos_sim = round(x1, 3),
             row.names = NULL)
}




sim2 = function(x,
                y = NULL,
                method = c("cosine", "jaccard"),
                norm = c("l2", "none")) {

  norm = match.arg(norm)
  method = match.arg(method)
  # check first matrix
  stopifnot(inherits(x, "matrix") || inherits(x, "Matrix"))

  FLAG_TWO_MATRICES_INPUT = FALSE
  if (!is.null(y)) {
    FLAG_TWO_MATRICES_INPUT = TRUE
  }
  # check second matrix
  if (FLAG_TWO_MATRICES_INPUT) {
    stopifnot(inherits(y, "matrix") || inherits(y, "Matrix"))
    stopifnot(ncol(x) == ncol(y))
    stopifnot(colnames(x) == colnames(y))
  }

  RESULT = NULL

  if (method == "cosine") {
    x = normalize(x, norm)
    if (FLAG_TWO_MATRICES_INPUT) {
      y = normalize(y, norm)
      RESULT = tcrossprod(x, y)
    }
    else
      RESULT = tcrossprod(x)
  }

  RESULT
}


#' @name normalize
#' @title Matrix normalization
#' @description normalize matrix rows using given norm
#' @param m \code{matrix} (sparse or dense).
#' @param norm \code{character} the method used to normalize term vectors
#' @seealso \link{create_dtm}
#' @return normalized matrix
#' @export
normalize = function(m, norm = c("l1", "l2", "none")) {
  stopifnot(inherits(m, "matrix") || inherits(m, "sparseMatrix"))
  norm = match.arg(norm)

  if (norm == "none")
    return(m)

  norm_vec = switch(norm,
                    l1 = 1 / rowSums(m),
                    l2 = 1 / sqrt(rowSums(m ^ 2))
  )
  # case when sum row elements == 0
  norm_vec[is.infinite(norm_vec)] = 0

  if(inherits(m, "sparseMatrix"))
    Matrix::rowScale(m, norm_vec)
  else
    m * norm_vec
}


embs <- pubmedtk::data_mesh_embeddings()
x_get_neighbors(x = 'Abdominal Muscles', matrix = embs)
