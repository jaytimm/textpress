#' Convert Token List to Data Frame
#'
#' This function converts a list of tokens into a data frame, extracting and separating document and sentence identifiers if needed.
#'
#' @param tok A list where each element contains tokens corresponding to a document or a sentence.
#' @return A data frame with columns for document ID, sentence ID (if applicable), tokens, and their respective identifiers.
#' @importFrom textshape tidy_list
#' @importFrom data.table rowid
#' @examples
#' # Example usage
#' # tok <- list("doc1" = c("token1", "token2"), "doc2" = c("token3", "token4"))
#' # nlp_token_df(tok)
#' @export
#' @rdname nlp_token_df
#'
#'
nlp_token_df <- function(tok){

  # Validate input
  if (!is.list(tok)) {
    stop("The argument 'tok' must be a list.")
  }

  df <- textshape::tidy_list(tok,
                             id.name = 'doc_id',
                             content.name = 'token')

  if(grepl('\\.', df$doc_id[1])) {
    df[, sentence_id := gsub('^.*\\.', '', doc_id)]
    df[, doc_id := gsub('\\..*$', '', doc_id)]
    df[, term_id := data.table::rowid(doc_id, sentence_id)]
  }

  df[, token_id := data.table::rowid(doc_id)]
  return(df)
}

