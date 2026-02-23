#' Exact phrase / MWE matcher
#'
#' Exact phrase or multi-word expression (MWE) matcher; no partial-match risk.
#' Tokenizes corpus, builds n-grams, and exact-joins against \code{terms}. Word
#' boundaries respected. N-gram range is set from the min and max word count of
#' \code{terms}. Good for deterministic entity extraction (e.g. before an LLM call).
#'
#' @param corpus Data frame or data.table with a \code{text} column and the identifier columns specified in \code{by}.
#' @param by Character vector of identifier columns that define the text unit (e.g. \code{doc_id} or \code{c("url", "node_id")}). Default \code{c("doc_id")}.
#' @param terms Character vector of terms or phrases to match exactly. N-gram range derived from word counts of \code{terms}.
#' @return Data.table with \code{id}, \code{start}, \code{end}, \code{n}, \code{ngram}, \code{term}.
#' @export
#' @examples
#' corpus <- data.frame(doc_id = "1", text = "Gen Z and Millennials use social media.")
#' search_dict(corpus, by = "doc_id", terms = c("Gen Z", "Millennials", "social media"))
search_dict <- function(corpus,
                       by = c("doc_id"),
                       terms) {

  if (!length(terms)) {
    return(data.table::data.table(id = character(), start = numeric(), end = numeric(), n = integer(), ngram = character(), term = character()))
  }
  dict_dt <- data.table::data.table(variant_lc = tolower(terms))
  word_counts <- vapply(strsplit(trimws(terms), "\\s+"), function(x) length(x[nzchar(x)]), integer(1))
  n_min <- max(1L, min(word_counts, na.rm = TRUE))
  n_max <- max(1L, max(word_counts, na.rm = TRUE))

  toks_df_ss <- textpress::nlp_cast_tokens(
    textpress::nlp_tokenize_text(corpus, by = by, include_spans = TRUE)
  )

  if (n_max > 1) {
    for (i in 2:n_max) {
      toks_df_ss[, paste0("token", i) := data.table::shift(token, type = "lead", n = i - 1), by = id]
      toks_df_ss[, paste0("end", i) := data.table::shift(end, type = "lead", n = i - 1), by = id]
    }
  }

  ngram_list <- lapply(n_min:n_max, function(n) {
    if (n == 1) {
      toks_df_ss[, .(id, ngram = token, start, end, n = 1)]
    } else {
      dt <- toks_df_ss[!is.na(get(paste0("token", n)))]
      token_cols <- c("token", paste0("token", 2:n))
      dt[, ngram := do.call(paste, c(.SD, sep = " ")), .SDcols = token_cols]
      dt[, end := .SD[[1]], .SDcols = paste0("end", n)]
      dt[, .(id, ngram, start, end, n)]
    }
  })
  all_ngrams <- data.table::rbindlist(ngram_list)
  all_ngrams[, ngram_lc := tolower(ngram)]

  matches <- all_ngrams[dict_dt, on = .(ngram_lc = variant_lc), nomatch = 0L]
  matches[, start := as.numeric(start)]
  matches[, end := as.numeric(end)]

  data.table::setorder(matches, id, start, -end)
  matches[, group := cumsum(start > data.table::shift(cummax(end), fill = -Inf)), by = id]
  matches <- matches[, .SD[1], by = .(id, group)][, group := NULL]

  matches[, term := ngram_lc]
  matches[, ngram_lc := NULL]
  matches[, .(id, start, end, n, ngram, term)]
}
