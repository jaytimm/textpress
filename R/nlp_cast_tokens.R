#' Convert Token List to Data Frame
#'
#' This function converts a list of tokens into a data frame, extracting and separating document and sentence identifiers if needed.
#'
#' @param tok A list where each element contains tokens corresponding to a document or a sentence.
#' @param by A character string specifying grouping column.
#' @param word_form A character string specifying either token or lemma
#' @return A data frame with columns for document ID, sentence ID (if applicable), tokens, and their respective identifiers.
#' @export
#' @rdname nlp_cast_tokens
#'
#'
nlp_cast_tokens <- function(tok,
                            by = "text_id",
                            word_form = "token") {

  # Check if all elements in 'tok' are atomic vectors. Stop if not.
  if (!all(sapply(tok, is.atomic))) {
    stop("`tok` must be a list of atomic vectors")
  }

  # If 'tok' elements do not have names, assign sequential names
  if (is.null(names(tok))) {
    names(tok) <- seq_along(tok)
  }

  # Create a data frame with two columns:
  # 1. Replicated names of 'tok' elements, replicated by the length of each element
  # 2. Unlisted elements of 'tok', concatenated into a single vector
  df <- data.frame(rep(names(tok), sapply(tok, length)),
                   unlist(tok, use.names = FALSE),
                   check.names = FALSE,
                   row.names = NULL)

  # Set the column names of the data frame to 'by' and 'word_form'
  colnames(df) <- c(by, word_form)

  # Convert the data frame to a data table and return it
  return(data.table::data.table(df))
}
