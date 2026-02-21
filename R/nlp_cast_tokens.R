#' Convert Token List to Data Frame
#'
#' This function converts a list of tokens into a data frame, extracting and separating document and sentence identifiers if needed.
#'
#' @param tok A list where each element contains tokens corresponding to a document or a sentence.
#' @return A data frame with columns for token name and token.
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

