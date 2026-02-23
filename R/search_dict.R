#' Exact n-gram matcher (vector of terms)
#'
#' Find a long list of multi-word expressions (MWEs) or terms without regex
#' overhead or partial-match risks. Tokenize corpus, build n-grams, then exact
#' join against \code{terms}. Word boundaries are respected by design. For
#' categories (e.g. term = "R Project", category = "Software"), left_join your
#' metadata onto the result using \code{ngram} or \code{term} as key.
#'
#' @param corpus The text data (data frame or data.table with \code{text} and \code{by} columns).
#' @param by Identifier columns (e.g. \code{c("doc_id", "sentence_id")}).
#' @param terms A character vector of terms/variants to find (e.g. \code{c("United States", "R Project")}).
#' @param n_min Integer. Minimum n-gram size (default 1).
#' @param n_max Integer. Maximum n-gram size (default 5).
#' @return A data.table with \code{id}, \code{start}, \code{end}, \code{n}, \code{ngram}, \code{term} (the matched term from \code{terms}).
#' @export
#' @examples
#' corpus <- data.frame(doc_id = "1", text = "Gen Z and Millennials use social media.")
#' search_dict(corpus, by = "doc_id", terms = c("Gen Z", "Millennials", "social media"))
search_dict <- function(corpus,
                       by = c("doc_id"),
                       terms,
                       n_min = 1,
                       n_max = 5) {

  dict_dt <- data.table::data.table(variant_lc = tolower(terms))

  toks_df_ss <- corpus |>
    textpress::nlp_tokenize_text(by = by, include_spans = TRUE) |>
    textpress::nlp_cast_tokens()

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
