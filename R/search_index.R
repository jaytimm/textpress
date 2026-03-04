#' Search the BM25 index
#'
#' BM25 ranked retrieval. Search the index produced by \code{\link{nlp_index_tokens}}
#' with a keyword query. The unit-id column in results is taken from \code{attr(index, "id_col")} when present, else \code{"uid"}.
#'
#' @param index Object created by \code{\link{nlp_index_tokens}}.
#' @param query Character string (keywords).
#' @param n Number of results to return (default 10).
#' @param stem Logical; must match the setting used during indexing (default \code{FALSE}).
#' @return Data.table with columns \code{query}, \code{method} (\dQuote{bm25}), \code{score} (3 significant figures), and the unit-id column (e.g. \code{uid}), ranked by score.
#' @export
search_index <- function(index, query, n = 10, stem = FALSE) {

  id_col <- attr(index, "id_col")
  if (is.null(id_col)) id_col <- "uid"

  if (!data.table::is.data.table(index) ||
      !all(c(id_col, "token", "score") %in% names(index))) {
    stop("'index' must be a data.table with columns ", id_col, ", token, score.", call. = FALSE)
  }

  terms <- tolower(unlist(strsplit(as.character(query), "\\s+")))
  terms <- terms[grepl("[[:alnum:]]", terms)]
  terms <- terms[!terms %in% stopwords_en]

  if (isTRUE(stem)) {
    if (!requireNamespace("SnowballC", quietly = TRUE)) {
      stop("package 'SnowballC' is required for stemming.", call. = FALSE)
    }
    terms <- SnowballC::wordStem(terms)
  }

  if (length(terms) == 0) return(NULL)

  query_str <- as.character(query)
  out <- index[token %in% terms, .(score = sum(score)), by = c(id_col)]
  out <- out[order(-score)]
  n_final <- min(n, nrow(out))
  out <- out[seq_len(n_final)]
  out[, `:=`(query = query_str, method = "bm25")]
  out[, score := signif(score, 3)]
  data.table::setcolorder(out, c("query", "method", "score", id_col))
  return(out)
}
