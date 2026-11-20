#' Find abbreviation definitions in text
#'
#' Detects in-text abbreviation definitions and pairs each short form with its
#' long form. Two kinds are found:
#' \itemize{
#'   \item \strong{Parenthetical} definitions, using the Schwartz & Hearst (2003)
#'     algorithm: "tumor necrosis factor (TNF)" and the reverse
#'     "TNF (tumor necrosis factor)".
#'   \item \strong{Taxonomic} abbreviations: "E. coli" paired with
#'     "Escherichia coli" when the full name also appears in the same unit.
#' }
#'
#' Rows that share the same \code{by} values are pooled into one unit before
#' searching, so a definition in one paragraph pairs with a full name in
#' another. With \code{by = "doc_id"}, node- or sentence-level rows from
#' \code{\link{read_urls}} or \code{\link{nlp_split_sentences}} are searched
#' as whole documents.
#'
#' @param corpus Data frame or data.table with a \code{text} column and the identifier columns specified in \code{by}.
#' @param by Character vector of identifier columns that define the text unit (e.g. \code{doc_id} or \code{c("doc_id", "node_id")}). Default \code{c("doc_id")}.
#' @param methods Which detectors to run: \code{"parenthetical"},
#'   \code{"taxonomic"}, or both (default).
#' @return Data.table with \code{by} columns, \code{short_form},
#'   \code{long_form}, and \code{method}; one row per unique pair per unit.
#' @references Schwartz, A. S., & Hearst, M. A. (2003). A simple algorithm for
#'   identifying abbreviation definitions in biomedical text.
#'   \emph{Pacific Symposium on Biocomputing}, 451-462.
#' @examples
#' corpus <- data.frame(
#'   doc_id = 1:2,
#'   text = c("Levels of tumor necrosis factor (TNF) and interleukin-6 (IL-6) rose.",
#'            "Escherichia coli was cultured. Growth of E. coli was slow.")
#' )
#' nlp_find_abbreviations(corpus, by = "doc_id")
#' @export
nlp_find_abbreviations <- function(corpus,
                                   by = c("doc_id"),
                                   methods = c("parenthetical", "taxonomic")) {
  methods <- match.arg(methods, several.ok = TRUE)
  missing <- setdiff(c(by, "text"), names(corpus))
  if (length(missing)) {
    stop("Missing columns in `corpus`: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }

  dt <- data.table::as.data.table(corpus)[, c(by, "text"), with = FALSE]
  dt[, text := as.character(text)]
  dt <- dt[!is.na(text) & nzchar(text)]

  # One unit per unique combination of `by` values
  units <- dt[, list(text = paste(text, collapse = "\n\n")), by = by]
  uid <- seq_len(nrow(units))

  out <- list()
  if ("parenthetical" %in% methods) out$p <- .abbr_parenthetical(uid, units$text)
  if ("taxonomic" %in% methods)     out$t <- .abbr_taxonomic(uid, units$text)

  res <- data.table::rbindlist(out, use.names = TRUE)
  if (nrow(res) == 0L) {
    return(cbind(units[0L, by, with = FALSE],
                 data.table::data.table(short_form = character(0),
                                        long_form = character(0),
                                        method = character(0))))
  }
  res <- unique(res, by = c("doc_id", "short_form", "long_form"))
  cbind(units[res$doc_id, by, with = FALSE],
        res[, c("short_form", "long_form", "method"), with = FALSE])
}


# Parenthetical definitions (Schwartz & Hearst) --------------------------------

.abbr_parenthetical <- function(doc_id, text) {
  # Innermost parentheticals: "(...)" with no nested parens
  loc <- stringi::stri_locate_all_regex(text, "\\([^()]{1,100}\\)", omit_no_match = TRUE)
  n <- vapply(loc, nrow, integer(1))
  if (sum(n) == 0L) return(NULL)

  idx <- rep(seq_along(text), n)
  m <- do.call(rbind, loc)
  txt <- text[idx]

  inner <- stringi::stri_sub(txt, m[, 1] + 1L, m[, 2] - 1L)
  # S&H: only the part before a comma/semicolon is the candidate ("TNF; ref 3")
  inner <- trimws(sub("[;,].*$", "", inner))
  pre <- stringi::stri_sub(txt, 1L, m[, 1] - 1L)
  # Restrict to the current sentence / clause
  # (?s): text pooled across paragraphs or table cells contains newlines.
  # A period after a single letter ("E. coli", "e.g.", "U.S.") is not a break.
  pre <- sub("(?s)^.*(?:(?:(?<!\\b[A-Za-z])[.]|[!?;:])\\s|[()\\[\\]\n])", "", pre,
             perl = TRUE)
  pre <- trimws(pre)

  pre_words <- strsplit(pre, "\\s+")
  inner_nw <- lengths(strsplit(inner, "\\s+"))

  short <- long <- rep(NA_character_, length(inner))

  # Case 1: long form (short form) -- the usual direction
  c1 <- inner_nw <= 2L & .valid_short_form(inner)
  for (i in which(c1)) {
    w <- pre_words[[i]]
    k <- min(nchar(inner[i]) + 5L, 2L * nchar(inner[i]))
    cand <- paste(utils::tail(w, k), collapse = " ")
    lf <- .best_long_form(inner[i], cand)
    if (!is.na(lf)) { short[i] <- inner[i]; long[i] <- lf }
  }

  # Case 2: short form (long form) -- e.g. "TNF (tumor necrosis factor)"
  last_word <- vapply(pre_words, function(w) if (length(w)) w[length(w)] else "", "")
  last_word <- gsub("^[[:punct:]]+|[[:punct:]]+$", "", last_word)
  # Reverse direction needs an abbreviation-like word (two or more capitals),
  # so ordinary capitalized words ("Green", "County") are not taken
  c2 <- is.na(long) & inner_nw > 1L & .valid_short_form(last_word) &
    stringi::stri_count_regex(last_word, "[A-Z]") >= 2L
  for (i in which(c2)) {
    lf <- .best_long_form(last_word[i], inner[i])
    if (!is.na(lf)) { short[i] <- last_word[i]; long[i] <- lf }
  }

  keep <- !is.na(long)
  if (!any(keep)) return(NULL)
  data.table::data.table(doc_id = doc_id[idx][keep], short_form = short[keep],
                         long_form = long[keep], method = "parenthetical")
}

# S&H short-form criteria (vectorized), plus an uppercase requirement
.valid_short_form <- function(x) {
  nchar(x) >= 2L & nchar(x) <= 10L &
    grepl("^[[:alnum:]]", x) &
    grepl("[[:alpha:]]", x) &
    grepl("[[:upper:]]", x)
}

# Schwartz & Hearst alignment: match short-form characters right-to-left in the
# candidate long form; the first short-form character must begin a word.
.best_long_form <- function(sf, lf) {
  s <- strsplit(tolower(sf), "")[[1]]
  l <- strsplit(tolower(lf), "")[[1]]
  si <- length(s)
  li <- length(l)
  while (si >= 1L) {
    ch <- s[si]
    if (!grepl("[[:alnum:]]", ch)) { si <- si - 1L; next }
    while (li >= 1L &&
           (l[li] != ch ||
            (si == 1L && li > 1L && grepl("[[:alnum:]]", l[li - 1L])))) {
      li <- li - 1L
    }
    if (li < 1L) return(NA_character_)
    li <- li - 1L
    si <- si - 1L
  }
  # Back up to the start of the word containing the first match
  spaces <- which(l[seq_len(li)] == " ")
  start <- if (length(spaces)) max(spaces) + 1L else 1L
  out <- trimws(substr(lf, start, nchar(lf)))

  # Sanity checks: longer than short form, does not contain it, few words
  n_words <- lengths(strsplit(out, "\\s+"))
  if (nchar(out) <= nchar(sf) ||
      grepl(sf, out, fixed = TRUE) ||
      grepl("[()]", out) ||
      n_words > min(nchar(sf) + 5L, 2L * nchar(sf))) {
    return(NA_character_)
  }
  out
}


# Taxonomic abbreviations ("E. coli" -> "Escherichia coli") --------------------

.abbr_taxonomic <- function(doc_id, text) {
  hits <- stringi::stri_match_all_regex(text, "\\b([A-Z])\\.\\s+([a-z]{3,})\\b",
                                        omit_no_match = TRUE)
  n <- vapply(hits, nrow, integer(1))
  if (sum(n) == 0L) return(NULL)

  idx <- rep(seq_along(text), n)
  h <- do.call(rbind, hits)
  dt <- unique(data.table::data.table(i = idx, short_form = h[, 1],
                                      init = h[, 2], epithet = h[, 3]))
  # An initial before a function word ("Jones S. and Silva") is not a binomial
  dt <- dt[!epithet %in% stopwords_en]
  if (nrow(dt) == 0L) return(NULL)

  # Full binomial in the same document: same initial, genus of 3+ letters
  pat <- paste0("\\b", dt$init, "[a-z]{2,}\\s+", dt$epithet, "\\b")
  dt[, long_form := stringi::stri_extract_first_regex(text[i], pat)]
  dt <- dt[!is.na(long_form)]
  if (nrow(dt) == 0L) return(NULL)

  dt[, short_form := gsub("\\s+", " ", short_form)]
  data.table::data.table(doc_id = doc_id[dt$i], short_form = dt$short_form,
                         long_form = dt$long_form, method = "taxonomic")
}
