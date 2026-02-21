# English stopwords (no tm dependency); same set as tm::stopwords("en")
# @noRd
.stopwords_en <- c(
  "i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you", "your",
  "yours", "yourself", "yourselves", "he", "him", "his", "himself", "she", "her",
  "hers", "herself", "it", "its", "itself", "they", "them", "their", "theirs",
  "themselves", "what", "which", "who", "whom", "this", "that", "these", "those",
  "am", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had",
  "having", "do", "does", "did", "doing", "would", "should", "could", "ought",
  "i'm", "you're", "he's", "she's", "it's", "we're", "they're", "i've", "you've",
  "we've", "they've", "i'd", "you'd", "he'd", "she'd", "we'd", "they'd", "i'll",
  "you'll", "he'll", "she'll", "we'll", "they'll", "isn't", "aren't", "wasn't",
  "weren't", "hasn't", "haven't", "hadn't", "doesn't", "don't", "didn't", "won't",
  "wouldn't", "shan't", "shouldn't", "can't", "cannot", "couldn't", "mustn't",
  "let's", "that's", "who's", "what's", "here's", "there's", "when's", "where's",
  "why's", "how's", "a", "an", "the", "and", "but", "if", "or", "because", "as",
  "until", "while", "of", "at", "by", "for", "with", "about", "against", "between",
  "into", "through", "during", "before", "after", "above", "below", "to", "from",
  "up", "down", "in", "out", "on", "off", "over", "under", "again", "further",
  "then", "once", "here", "there", "when", "where", "why", "how", "all", "any",
  "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor",
  "not", "only", "own", "same", "so", "than", "too", "very"
)

#' Build a BM25 token index from tokenized documents
#'
#' Converts a named list of token vectors into a data.table with BM25 weights
#' per (id, token). English stopwords are removed and only alphabetic tokens
#' are kept. Used with \code{\link{search_index}} for ranked retrieval.
#'
#' @param tokens A named list of character vectors. Each element is one document
#'   (or text unit); names are document IDs. Typically the output of tokenizing
#'   then splitting by document (e.g. from \code{\link{nlp_tokenize_text}} and
#'   \code{\link{nlp_cast_tokens}}).
#' @param k1 Numeric. BM25 term frequency saturation parameter (default 1.2).
#' @param b Numeric. BM25 length normalization parameter (default 0.75).
#' @param stem Logical. If \code{TRUE}, apply Porter stemming to tokens before
#'   indexing. Requires the suggested package \pkg{SnowballC}.
#' @return A \code{data.table} with columns \code{id}, \code{token}, \code{bm25},
#'   ordered by \code{id}.
#' @export
#' @examples
#' tokens <- list(
#'   doc1 = c("the", "quick", "brown", "fox", "jumps"),
#'   doc2 = c("a", "quick", "dog", "runs", "fast")
#' )
#' idx <- nlp_index_tokens(tokens)
#' search_index(idx, query = "quick fox", n = 2)
nlp_index_tokens <- function(tokens,
                             k1 = 1.2,
                             b = 0.75,
                             stem = FALSE) {

  if (!is.list(tokens) || is.null(names(tokens))) {
    stop("'tokens' must be a named list of character vectors.", call. = FALSE)
  }

  stops <- .stopwords_en

  dt <- data.table::rbindlist(
    lapply(names(tokens), function(id) {
      data.table::data.table(id = id, token = as.character(tokens[[id]]))
    })
  )

  dt <- dt[!token %in% stops & grepl("^[a-zA-Z]+$", token)]
  dt[, token := tolower(token)]

  if (isTRUE(stem)) {
    if (!requireNamespace("SnowballC", quietly = TRUE)) {
      stop("package 'SnowballC' is required when stem=TRUE. Install with install.packages(\"SnowballC\").", call. = FALSE)
    }
    dt[, token := SnowballC::wordStem(token)]
  }

  dtm    <- dt[, .(tf = .N), by = .(id, token)]
  N      <- dtm[, data.table::uniqueN(id)]
  dl     <- dtm[, .(dl = sum(tf)), by = id]
  avg_dl <- dl[, mean(dl)]
  idf    <- dtm[, .(df = data.table::uniqueN(id)), by = token]
  idf[,  idf := log((N - df + 0.5) / (df + 0.5) + 1)]

  dtm <- merge(dtm, dl,  by = "id")
  dtm <- merge(dtm, idf, by = "token")
  dtm[, bm25 := idf * (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * (dl / avg_dl)))]
  data.table::setorder(dtm[, .(id, token, bm25)], id)
}
