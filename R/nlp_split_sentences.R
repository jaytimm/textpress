#' Split Text into Sentences
#'
#' This function splits the text from a given data frame into individual sentences.
#'
#' @param tif A data frame with at least two columns: `doc_id` and `text`.
#' @return A data frame with four columns: `doc_id`, `sentence_id`, `text`, and `words`.
#' @importFrom data.table data.table setcolorder
#' @export
#' @examples
#' # Example usage
#' df <- data.frame(doc_id = 1:2, text = c("Hello world. This is a test.", "Another sentence. And another."))
#' nlp_split_sentences(df)

#' @export
#' @rdname nlp_split_sentences
#'
nlp_split_sentences <- function(tif) {

  # Validate input
  if (!("doc_id" %in% names(tif) && "text" %in% names(tif))) {
    stop("The input data frame must contain 'doc_id' and 'text' columns.")
  }

  # Convert doc_id to character and tokenize text
  xx <- data.table::data.table(doc_id = tif$doc_id |> as.character(),
                               text = sapply(tif$text, sentence_split))

  # Unlist the text and create sentence IDs
  xx1 <- xx[,.(text = unlist(text)), by = doc_id]
  xx1[, sentence_id := seq_len(.N), by = doc_id]
  xx1[, text_id := paste0(doc_id, '.', sentence_id)]

  # Reorder columns
  data.table::setcolorder(xx1, c('doc_id', 'sentence_id', 'text_id', 'text'))
  return(xx1)
}



sentence_split <- function(x) {
    x <- stringi::stri_replace_all_charclass(x, "[[:whitespace:]]", " ")
    out <- stringi::stri_split_boundaries(x,
                                          type = "sentence",
                                          skip_word_none = FALSE)
    lapply(out, stringi::stri_trim_both)
}


