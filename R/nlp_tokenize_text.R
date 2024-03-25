#' Tokenize Text Data (mostly) Non-Destructively
#'
#' This function tokenizes text data from a data frame using the 'tokenizers' package, preserving the original text structure like capitalization and punctuation.
#' @param tif A data frame containing the text to be tokenized and a document identifier in 'doc_id'.
#' @param text_hierarchy A character string specifying grouping column.
#' @return A named list of tokens, where each list item corresponds to a document.
#'
#'
#' @export
#'
nlp_tokenize_text <- function(tif,
                              text_hierarchy = c("doc_id", "paragraph_id", "sentence_id")) {
  # Check if 'tif' is a data frame
  if (!is.data.frame(tif)) {
    stop("Input 'tif' must be a data frame.")
  }

  # Convert to data.table
  tif <- data.table::setDT(tif)

  # Check if 'tif' contains the necessary columns
  missing_columns <- setdiff(text_hierarchy, names(tif))
  if (length(missing_columns) > 0) {
    stop("Input data frame is missing required columns: ", paste(missing_columns, collapse = ", "))
  }

  # Creating a unique identifier for each text entry
  tif[, unique_id := do.call(paste, c(.SD, sep = ".")), .SDcols = text_hierarchy]

  # Tokenizing
  tokens <- lapply(tif$text, function(text) {
    unlist(.token_split(text))
  })

  # Naming the list
  names(tokens) <- tif$unique_id
  return(tokens)
}


#' Splits text into tokens, removing whitespace, for internal use.
#'
#' @param x Character vector to tokenize.
#' @return List of character vectors, each containing the tokens.
#' @keywords internal
#' @noRd
.token_split <- function(x) {
  # Split text into words based on word boundaries
  out <- stringi::stri_split_boundaries(x, type = "word")

  # Remove tokens that are purely whitespace
  out <- lapply(out, stringi::stri_subset_charclass, "\\p{WHITESPACE}", negate = TRUE)

  # Return the list of tokens
  out
}
