#' Tokenize Text Data (mostly) Non-Destructively
#'
#' This function tokenizes text data from a data frame using the 'tokenizers' package, preserving the original text structure like capitalization and punctuation.
#' @param tif A data frame containing the text to be tokenized and a document identifier in 'doc_id'.
#' @return A named list of tokens, where each list item corresponds to a document.
#' @importFrom tokenizers tokenize_words
#' @examples
#' # Assuming tif is a data frame with columns 'doc_id' and 'text'
#' # tif <- data.frame(doc_id = 1:2, text = c("Sample text 1", "Sample text 2"))
#' # tokens <- nlp_tif_token(tif)
#' @export
#' @rdname nlp_tif_token
#'
nlp_tif_token <- function(tif,
                          by = 'text_id') {

  # Check if 'tif' is a data frame
  if (!is.data.frame(tif)) {
    stop("Input 'df' must be a data frame.")
  }

  # Check if 'tif' contains the necessary columns
  required_columns <- c(by, "text")
  missing_columns <- setdiff(required_columns, names(tif))
  if (length(missing_columns) > 0) {
    stop("Input data frame is missing required columns: ", paste(missing_columns, collapse = ", "))
  }

  # Tokenizing
  tokens <- lapply(tif$text, function(text) {
    unlist(tokenizers::tokenize_words(text,
                                      strip_punct = FALSE,
                                      simplify = FALSE,
                                      lowercase = F))
  })

  # Naming the list
  names(tokens) <-  tif[[by]]

  return(tokens)
}
