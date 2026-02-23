#' Search the BM25 Index
#'
#' @param index A data.table created by nlp_index_tokens.
#' @param query A character string.
#' @param n Number of results to return.
#' @param stem Logical; must match the setting used during indexing.
#' @return A data.table of results ranked by score.
#' @export
search_index <- function(index, query, n = 10, stem = FALSE) {

  # 1. Validation
  # Changed 'bm25' to 'score' to match the indexer output
  if (!data.table::is.data.table(index) ||
      !all(c("id", "token", "score") %in% names(index))) {
    stop("'index' must be a data.table with columns id, token, score.", call. = FALSE)
  }

  # 2. Tokenize Query
  terms <- tolower(unlist(strsplit(as.character(query), "\\s+")))
  # Keep alphanumeric (to match our indexer's [[:alnum:]] logic)
  terms <- terms[grepl("[[:alnum:]]", terms)]

  # Remove stopwords (using the same global list as the indexer)
  terms <- terms[!terms %in% stopwords_en]

  # 3. Optional Stemming
  if (isTRUE(stem)) {
    if (!requireNamespace("SnowballC", quietly = TRUE)) {
      stop("package 'SnowballC' is required for stemming.", call. = FALSE)
    }
    terms <- SnowballC::wordStem(terms)
  }

  if (length(terms) == 0) return(NULL)

  # 4. Filter and Aggregate
  # We sum the pre-calculated BM25 scores for any token that matches the query
  out <- index[token %in% terms,
               .(score = sum(score),
                 matched = paste(unique(token), collapse = ", ")),
               by = id]

  # 5. Rank and Cap
  out <- out[order(-score)]

  # Ensure we don't try to return more results than exist
  n_final <- min(n, nrow(out))

  return(out[seq_len(n_final)])
}
