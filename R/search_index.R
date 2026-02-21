#' Search a BM25 token index by query string
#'
#' Returns the top \code{n} documents ranked by summed BM25 score for query
#' terms. Query is tokenized (whitespace), lowercased, stopwords removed, and
#' optionally stemmed to match the index. Local search over a prebuilt index
#' (from \code{\link{nlp_index_tokens}}).
#'
#' @param index A \code{data.table} with columns \code{id}, \code{token},
#'   \code{bm25} (e.g. from \code{\link{nlp_index_tokens}}).
#' @param query Character. Search query; words are split on whitespace.
#' @param n Integer. Maximum number of results to return (default 10).
#' @param stem Logical. If \code{TRUE}, stem query terms to match stemmed index.
#'   Requires the suggested package \pkg{SnowballC}.
#' @return A \code{data.table} with columns \code{id}, \code{score}, \code{matched}
#'   (list of matched tokens), ordered by \code{score} descending.
#' @export
#' @examples
#' tokens <- list(
#'   doc1 = c("the", "quick", "brown", "fox", "jumps"),
#'   doc2 = c("a", "quick", "dog", "runs", "fast")
#' )
#' idx <- nlp_index_tokens(tokens)
#' search_index(idx, "quick fox", n = 2)
search_index <- function(index, query, n = 10, stem = FALSE) {

  if (!data.table::is.data.table(index) ||
      !all(c("id", "token", "bm25") %in% names(index))) {
    stop("'index' must be a data.table with columns id, token, bm25.", call. = FALSE)
  }

  terms <- tolower(unlist(strsplit(as.character(query), "\\s+")))
  terms <- terms[grepl("^[a-zA-Z]+$", terms)]
  terms <- terms[!terms %in% .stopwords_en]

  if (isTRUE(stem)) {
    if (!requireNamespace("SnowballC", quietly = TRUE)) {
      stop("package 'SnowballC' is required when stem=TRUE. Install with install.packages(\"SnowballC\").", call. = FALSE)
    }
    terms <- SnowballC::wordStem(terms)
  }

  out <- index[token %in% terms, .(score = sum(bm25), matched = list(unique(token))), by = id][order(-score)][seq_len(n)]
  out
}
