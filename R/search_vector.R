#' Semantic search by cosine similarity
#'
#' Semantic search by cosine similarity. Returns top-\code{n} matches from an
#' embedding matrix for one or more query vectors. Subject-first: \code{embeddings}
#' (haystack) then \code{query} (needle). Pipe-friendly.
#'
#' @param embeddings Numeric matrix of embeddings; rows are searchable units (row names used as identifiers).
#' @param query Row name in \code{embeddings}, a numeric vector (single query), or a numeric matrix (multiple queries).
#' @param n Number of results to return per query (default 10).
#' @return Data frame with columns \code{query}, \code{method} (\dQuote{cosine}), \code{score} (3 significant figures), and the unit-id column (e.g. \code{uid}). For multiple queries, a list of such data frames.
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

  match_id_col <- attr(embeddings, "id_col") %||% "uid"

  out <- lapply(seq_len(nrow(sim_mat)), function(i) {
    scores <- sim_mat[i, ]
    idx <- order(scores, decreasing = TRUE)[1:min(n, length(scores))]

    df <- data.frame(
      query  = rownames(query)[i] %||% paste0("q", i),
      method = "cosine",
      score  = signif(as.numeric(scores[idx]), 3),
      stringsAsFactors = FALSE
    )
    df[[match_id_col]] <- names(scores)[idx] %||% idx
    df[, c("query", "method", "score", match_id_col)]
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
