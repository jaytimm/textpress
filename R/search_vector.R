#' Vector search by cosine similarity
#'
#' Returns the top-\code{n} matches from an embedding matrix for one or more query vectors.
#' Subject-first: \code{embeddings} (haystack) then \code{query} (needle), pipe-friendly.
#'
#' @param embeddings A numeric or sparse matrix of embeddings (rows = searchable units).
#' @param query A character (row name in \code{embeddings}), a numeric vector (single query),
#'   or a numeric matrix (multiple queries).
#' @param n Number of results to return per query (default 10).
#' @return A data frame (or list of data frames if multiple queries are provided)
#'   containing the match identifiers and similarity scores.
#' @export
search_vector <- function(embeddings, query, n = 10) {

  # 1. Handle character lookup
  if (is.character(query)) {
    if (!all(query %in% rownames(embeddings))) stop("Character query not found in embeddings rownames.")
    query <- embeddings[query, , drop = FALSE]
  }

  # 2. Force query into a matrix for batch consistency
  if (is.numeric(query) && !is.matrix(query)) {
    query <- matrix(query, nrow = 1, dimnames = list("query", NULL))
  }

  # 3. Fast Cosine Similarity via Matrix Multiplication
  q_norm <- .normalize_matrix(query)
  m_norm <- .normalize_matrix(embeddings)

  # Resulting sim_mat: [Queries x Documents]
  sim_mat <- q_norm %*% t(m_norm)

  # 4. Extract Top N efficiently
  out <- lapply(seq_len(nrow(sim_mat)), function(i) {
    scores <- sim_mat[i, ]
    idx <- order(scores, decreasing = TRUE)[1:min(n, length(scores))]

    data.frame(
      query_id = rownames(query)[i] %||% paste0("q", i),
      match_id = names(scores)[idx] %||% idx,
      cos_sim  = as.numeric(scores[idx]),
      rank     = 1:length(idx),
      stringsAsFactors = FALSE
    )
  })

  if (length(out) == 1) return(out[[1]]) else return(out)
}

#' @noRd
.normalize_matrix <- function(x) {
  if (inherits(x, "Matrix")) {
    nrm <- sqrt(Matrix::rowSums(x^2))
  } else {
    nrm <- sqrt(rowSums(x^2))
  }
  nrm[nrm == 0] <- 1
  x / nrm
}

#' @noRd
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
