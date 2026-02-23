#' Tokenize text into a clean token stream
#'
#' Normalize text into a clean token stream. Tokenizes corpus text, preserving
#' structure (capitalization, punctuation). The last column in \code{by} determines
#' the tokenization unit.
#'
#' @param corpus Data frame or data.table with a \code{text} column and the identifier columns specified in \code{by}.
#' @param by Character vector of identifier columns that define the text unit (e.g. \code{doc_id} or \code{c("url", "node_id")}). Default \code{c("doc_id", "paragraph_id", "sentence_id")}. The last column is the finest granularity.
#' @param include_spans Logical. Include start/end character spans for each token (default \code{TRUE}).
#' @param method Character. \code{"word"} or \code{"biber"}.
#' @return Named list of tokens; or list of \code{tokens} and \code{spans} if \code{include_spans = TRUE}.
#' @export
#' @examples
#' corpus <- data.frame(doc_id = c('1', '1', '2'),
#'                     sentence_id = c('1', '2', '1'),
#'                     text = c("Hello world.",
#'                              "This is an example.",
#'                              "This is a party!"))
#' tokens <- nlp_tokenize_text(corpus, by = c('doc_id', 'sentence_id'))
nlp_tokenize_text <- function(corpus,
                              by = c("doc_id", "paragraph_id", "sentence_id"),
                              include_spans = TRUE,
                              method = "word") {
  if (!is.data.frame(corpus)) {
    stop("Input 'corpus' must be a data frame.", call. = FALSE)
  }

  data.table::setDT(corpus)

  missing_columns <- setdiff(by, names(corpus))
  if (length(missing_columns) > 0) {
    stop("Input data frame is missing required columns: ",
         paste(missing_columns, collapse = ", "), call. = FALSE)
  }

  corpus[, id := do.call(paste, c(.SD, sep = ".")), .SDcols = by]

  tokenized <- switch(method,
                      word  = lapply(corpus$text, function(text) .token_split_with_spans(text, include_spans)),
                      biber = lapply(corpus$text, function(text) .token_split_biber_with_spans(text, include_spans)),
                      stop("Unknown method. Use 'word' or 'biber'.", call. = FALSE)
  )

  tokens <- lapply(tokenized, function(x) x$tokens)
  names(tokens) <- corpus$id

  if (include_spans) {
    spans <- lapply(tokenized, function(x) x$spans)
    names(spans) <- corpus$id
    return(list(tokens = tokens, spans = spans))
  } else {
    return(tokens)
  }
}



#' Splits text into tokens and optionally provides start/stop spans.
#'
#' This internal function uses stringi to split text on word boundaries,
#' removes tokens that are purely whitespace, and returns either just tokens
#' or both tokens and their positions.
#'
#' @param x A character string to tokenize.
#' @param include_spans Logical; if TRUE, includes start/stop spans. If FALSE, only tokens are returned.
#' @return A list containing:
#' \describe{
#'   \item{tokens}{A character vector of tokens.}
#'   \item{spans}{A matrix with columns 'start' and 'end', or NULL if spans are not included.}
#' }
#' @keywords internal
#' @noRd
.token_split_with_spans <- function(x, include_spans) {
  # Split text into tokens based on word boundaries
  token_list <- stringi::stri_split_boundaries(x, type = "word")[[1]]

  # Remove tokens that are purely whitespace
  keep <- !stringi::stri_detect_regex(token_list, "^\\s*$")
  tokens <- token_list[keep]

  if (include_spans) {
    # Get token spans using boundaries
    spans_mat <- stringi::stri_locate_all_boundaries(x, type = "word")[[1]]
    spans <- spans_mat[keep, , drop = FALSE]
  } else {
    spans <- NULL
  }

  return(list(tokens = tokens, spans = spans))
}



#' @keywords internal
#' @noRd
.token_split_biber_with_spans <- function(x, include_spans) {
  # Replace hyphens within words with placeholders
  x_mod <- gsub("(?<=\\w)-(?=\\w)", "__", x, perl = TRUE)

  contraction_suffixes <- c("s", "ll", "ve", "d", "m", "re")
  pattern_contraction <- paste0("(?<=\\w)['\u2019](", paste(contraction_suffixes, collapse = "|"), ")\\b")
  x_mod <- gsub(pattern_contraction, " '\\1", x_mod, perl = TRUE)

  # Match tokens with boundaries
  pattern_tokens <- "'s|'ll|'ve|'d|'m|'re|\\w+['\u2019]\\w+|\\w+|[[:punct:]]"
  matches <- stringi::stri_match_all_regex(x_mod, pattern_tokens, omit_no_match = TRUE)[[1]]
  spans <- stringi::stri_locate_all_regex(x_mod, pattern_tokens)[[1]]

  tokens <- matches[, 1]
  keep <- tokens != ""

  tokens <- tokens[keep]
  spans <- spans[keep, , drop = FALSE]

  # Restore original hyphens
  tokens <- gsub("__", "-", tokens)

  if (!include_spans) {
    spans <- NULL
  }

  return(list(tokens = tokens, spans = spans))
}



#' @keywords internal
#' @noRd
.rebuild_from_tokens <- function(toks) {
  rebuilt_texts <- mapply(function(tokens, spans_mat) {
    if (length(tokens) == 0 || is.null(spans_mat) || nrow(spans_mat) == 0) {
      return("")
    }
    rebuilt <- tokens[1]
    prev_end <- spans_mat[1, "end"]
    if (nrow(spans_mat) > 1) {
      for (i in 2:length(tokens)) {
        gap <- spans_mat[i, "start"] - (prev_end + 1)
        if (gap > 0) {
          rebuilt <- paste0(rebuilt, " ", tokens[i])
        } else {
          rebuilt <- paste0(rebuilt, tokens[i])
        }
        prev_end <- spans_mat[i, "end"]
      }
    }
    rebuilt
  }, toks$tokens, toks$spans, SIMPLIFY = TRUE)

  # Create a table with document IDs and rebuilt text
  ids <- names(toks$tokens)
  out <- data.table::data.table(id = ids, text = rebuilt_texts)
  return(out)
}
