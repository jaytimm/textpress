#' Search text using a dictionary (exact n-gram match)
#'
#' Dictionary-based search: build n-grams from tokenized text and match against
#' a target list (dictionary). Completes the \code{search_*} family: \code{search_corpus}
#' (regex), \code{search_index} (BM25), \code{search_vector} (embeddings), \code{search_dict} (dictionary/exact match).
#'
#' @param corpus A data frame with \code{text} and id columns given in \code{by}.
#' @param by Character vector of columns that identify each text unit (e.g. \code{"doc_id"}).
#' @param n_min Integer. Minimum n-gram size (default 1).
#' @param n_max Integer. Maximum n-gram size (default 5).
#' @param dictionary A data frame with columns \code{variant}, \code{TermName}, and optionally \code{doc_id}.
#'   Global entries use \code{NA} in \code{doc_id}; document-specific entries set \code{doc_id}.
#'   Defaults to \code{\link{dict_generations}}.
#'
#' @return A data.table with \code{id}, \code{start}, \code{end}, \code{n}, \code{ngram} (matched text),
#'   \code{TermName} (category/label from dictionary), \code{match_type} (\code{"global"} or \code{"local"}).
#' @export
#' @examples
#' \dontrun{
#' corpus <- data.frame(doc_id = "1", text = "Gen Z and Millennials use social media.")
#' search_dict(corpus, by = "doc_id", dictionary = dict_generations)
#' }
search_dict <- function(corpus,
                       by = c("doc_id"),
                       n_min = 1,
                       n_max = 5,
                       dictionary = dict_generations) {

  dictionary <- data.table::as.data.table(dictionary)
  if (!"doc_id" %in% names(dictionary)) dictionary[, doc_id := NA_character_]
  dictionary[, variant_lc := tolower(variant)]
  global_dict <- dictionary[is.na(doc_id), .(variant_lc, TermName)]
  local_dict  <- dictionary[!is.na(doc_id), .(doc_id, variant_lc, TermName)]

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

  global_hits <- all_ngrams[ngram_lc %in% global_dict$variant_lc]
  global_hits <- global_hits[global_dict,
                             on = .(ngram_lc = variant_lc),
                             nomatch = 0L]
  global_hits[, match_type := "global"]

  local_hits <- all_ngrams[ngram_lc %in% local_dict$variant_lc]
  local_hits <- local_hits[local_dict,
                           on = .(id = doc_id, ngram_lc = variant_lc),
                           nomatch = 0L]
  local_hits[, match_type := "local"]

  matches <- data.table::rbindlist(list(global_hits, local_hits), use.names = TRUE, fill = TRUE)

  matches[, start := as.numeric(start)]
  matches[, end := as.numeric(end)]

  data.table::setorder(matches, id, start, -end)
  matches[, group := cumsum(start > data.table::shift(cummax(end), fill = -Inf)), by = id]
  matches <- matches[, .SD[1], by = .(id, group)][, group := NULL]

  matches[, .(id, start, end, n, ngram, TermName, match_type)]
}
