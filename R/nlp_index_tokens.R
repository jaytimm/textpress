#' Build a BM25 index for ranked keyword search
#'
#' Build a weighted BM25 index for ranked keyword search. Creates a searchable
#' index from a named list of token vectors.
#'
#' @param tokens Named list of character vectors (e.g. from \code{\link{nlp_tokenize_text}}).
#' @param k1 BM25 saturation parameter (default 1.2).
#' @param b BM25 length normalization (default 0.75).
#' @param stem Logical. If \code{TRUE}, stem tokens (default \code{FALSE}).
#' @return Object (e.g. data.table) suitable for \code{\link{search_index}}.
#' @export
nlp_index_tokens <- function(tokens, k1 = 1.2, b = 0.75, stem = FALSE) {

  if (!is.list(tokens) || is.null(names(tokens))) {
    stop("'tokens' must be a named list of character vectors.", call. = FALSE)
  }

  # 1. Unnest list to data.table (Fastest method)
  dt <- data.table::data.table(id = names(tokens), token = tokens)
  dt <- dt[, .(token = unlist(token)), by = id]

  # 2. Cleanup
  stops <- stopwords_en
  dt <- dt[!token %in% stops & grepl("[[:alnum:]]", token)]
  dt[, token := tolower(token)]

  if (isTRUE(stem)) {
    dt[, token := SnowballC::wordStem(token)]
  }

  # 3. BM25 Calculation
  dtm <- dt[, .(tf = .N), by = .(id, token)]
  N <- dtm[, data.table::uniqueN(id)]
  dl_dt <- dtm[, .(dl = sum(tf)), by = id]
  avg_dl <- mean(dl_dt$dl)

  idf_dt <- dtm[, .(n = .N), by = token]
  idf_dt[, idf := log((N - n + 0.5) / (n + 0.5) + 1)]

  dtm <- dtm[idf_dt, on = "token"][dl_dt, on = "id"]
  dtm[, score := idf * (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * (dl / avg_dl)))]

  # 4. FINAL STEP: Return as a table with attributes
  # We use 'setattr' so we don't copy the whole table in memory
  data.table::setattr(dtm, "k1", k1)
  data.table::setattr(dtm, "b", b)
  data.table::setattr(dtm, "avg_dl", avg_dl)

  return(dtm)
}
