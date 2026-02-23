#' Convert token list to data frame
#'
#' Convert the token list returned by \code{\link{nlp_tokenize_text}} into a data
#' frame (long format), with identifiers and optional spans.
#'
#' @param tok List with at least a \code{tokens} element (and optionally \code{spans}), e.g. output of \code{nlp_tokenize_text(..., include_spans = TRUE)}.
#' @return Data frame with columns for unit id, token, and optionally start/end spans.
#' @export
#' @examples
#' tok <- list(
#'   tokens = list(
#'     "1.1" = c("Hello", "world", "."),
#'     "1.2" = c("This", "is", "an", "example", "."),
#'     "2.1" = c("This", "is", "a", "party", "!")
#'   )
#' )
#' dtm <- nlp_cast_tokens(tok)
#'
nlp_cast_tokens <- function(tok) {
  # Verify that toks has the required components
  if (!is.list(tok) || !"tokens" %in% names(tok)) {
    stop("Input 'tok' must be a list with at least a 'tokens' element.")
  }

  tokens <- tok$tokens
  spans  <- tok[["spans"]]  # Will be NULL if not present

  # Ensure tokens have names; if not, assign sequential names.
  if (is.null(names(tokens))) {
    names(tokens) <- seq_along(tokens)
  }

  # If spans exist, process normally
  if (!is.null(spans)) {
    if (is.null(names(spans))) {
      names(spans) <- seq_along(spans)
    }

    df_list <- mapply(function(id, token_vec, span_mat) {
      if (length(token_vec) != nrow(span_mat)) {
        stop("Mismatch in token and span lengths for id ", id)
      }
      data.table::data.table(
        id    = id,
        token = token_vec,
        start = span_mat[, "start"],
        end  = span_mat[, "end"]
      )
    }, names(tokens), tokens, spans, SIMPLIFY = FALSE)
  } else {
    # No spans - return tokens only
    df_list <- lapply(names(tokens), function(id) {
      data.table::data.table(
        id    = id,
        token = tokens[[id]]
      )
    })
  }

  # Combine into a single data.table
  dt <- data.table::rbindlist(df_list, fill = TRUE)
  return(dt)
}

