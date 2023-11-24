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

