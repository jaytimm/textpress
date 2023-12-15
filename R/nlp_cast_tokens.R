#' Convert Token List to Data Frame
#'
#' This function converts a list of tokens into a data frame, extracting and separating document and sentence identifiers if needed.
#'
#' @param tok A list where each element contains tokens corresponding to a document or a sentence.
#' @param by A character string specifying grouping column.
#' @return A data frame with columns for document ID, sentence ID (if applicable), tokens, and their respective identifiers.
#' @examples
#' # Example usage
#' # tok <- list("doc1" = c("token1", "token2"), "doc2" = c("token3", "token4"))
#' # nlp_token_df(tok)
#' @export
#' @rdname nlp_cast_tokens
#'
#'
nlp_cast_tokens <- function(tok,
                            by = "text_id",
                            token = "token") {

  if (!all(sapply(tok, is.atomic))) {
    stop("`x` must be a list of atomic `vector`s")
  }

  if (is.null(names(tok))) {
    names(tok) <- seq_along(tok)
  }

  df <- data.frame(rep(names(tok), sapply(tok, length)),
                   unlist(tok, use.names = FALSE),
                   check.names = FALSE,
                   row.names = NULL)

  colnames(df) <- c(by, token)
  return(data.table::data.table(df))
}
