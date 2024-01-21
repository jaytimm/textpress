#' Split Text into Sentences and Paragraphs
#'
#' This function splits text from a given data frame into individual sentences and paragraphs,
#' based on a specified paragraph delimiter. It handles abbreviations by temporarily
#' replacing them with placeholders to prevent incorrect sentence boundaries.
#'
#' @param tif A data frame with at least two columns: `doc_id` and `text`.
#' @param paragraph_delim A regular expression pattern used to split text into paragraphs.
#' @param abbreviations A character vector of abbreviations to be handled during sentence splitting.
#'        Defaults to textpress::abbreviations.
#' @return A data.table with columns: `doc_id`, `paragraph_id`, `sentence_id`,
#'         `text_id`, and `text`. Each row represents a sentence, along with its associated
#'         document, paragraph, and sentence identifiers.
#' @importFrom data.table data.table
#' @importFrom stringi stri_split_regex stri_replace_all_charclass stri_trim_both
#' @examples
#' df <- data.frame(doc_id = 1:2, text = c("Hello world.\nThis is a test.", "Another sentence.\nAnd another."))
#' nlp_split_sentences(df)
#' nlp_split_sentences(df, paragraph_delim = "\n+")
#' nlp_split_sentences(df, abbreviations = c("Mr\\.", "Dr\\.", "etc\\."))
#' @export

nlp_split_sentences <- function(tif,
                                paragraph_delim = "\n+",
                                abbreviations = textpress::abbreviations) {
  # Validate input data frame structure
  if (!("doc_id" %in% names(tif) && "text" %in% names(tif))) {
    stop("The input data frame must contain 'doc_id' and 'text' columns.", call. = FALSE)
  }

  # Convert to data.table if not already
  if (!data.table::is.data.table(tif)) {
    tif <- data.table::setDT(tif)
  }

  # Replace abbreviations with placeholders
  tif[, text := unlist(lapply(text, function(t) .replace_abbreviations(t,
                                                                       abbreviations,
                                                                       operation = "replace")))]


  # Split text into paragraphs based on the specified delimiter
  tif[, paragraphs := stringi::stri_split_regex(text, paragraph_delim)]

  # Create a long data.table of paragraphs
  paragraphs <- tif[, .(paragraph = unlist(paragraphs, use.names = FALSE)), by = .(doc_id)]

  # Filter out empty paragraphs
  paragraphs <- paragraphs[paragraph != ""]

  # Filter rows where text does not end with standard sentence-ending punctuation
  paragraphs <- paragraphs[grepl("(\\.|\\!|\\?)([^\\.!\\?\"])?$|^$", gsub("\"|'", "", paragraph)),]

  # Assign paragraph_id within each document
  paragraphs[, paragraph_id := seq_len(.N), by = .(doc_id)]

  # Split paragraphs into sentences and create a nested list
  paragraphs[, sentences := lapply(paragraph, .sentence_split), by = .(doc_id, paragraph_id)]

  # Flatten the nested list into a long data.table of sentences
  sentences <- paragraphs[, .(text = unlist(sentences, use.names = FALSE)), by = .(doc_id, paragraph_id)]

  # Revert placeholders back to abbreviations
  sentences$text <- .replace_abbreviations(sentences$text, abbreviations, operation = "revert")

  # Assign sentence_id within each paragraph
  sentences[, sentence_id := seq_len(.N), by = .(doc_id, paragraph_id)]

  # Create a combined text identifier
  sentences[, text_id := paste0(doc_id, ".", paragraph_id, ".", sentence_id)]

  # Reorder columns for output
  data.table::setcolorder(sentences, c("doc_id", "paragraph_id", "sentence_id", "text_id", "text"))

  return(sentences)
}


#' Splits text into sentences, normalizes whitespace, trims spaces.
#'
#' @param x Character vector to split.
#' @return List of character vectors with sentences.
#' @keywords internal
#' @noRd
.sentence_split <- function(x) {
  # Replace various types of whitespace with a single space for consistency
  x <- stringi::stri_replace_all_charclass(x, "[[:whitespace:]]", " ")

  # Split text into sentences based on sentence boundaries
  out <- stringi::stri_split_boundaries(x, type = "sentence", skip_word_none = FALSE)

  # Trim leading and trailing spaces from each sentence
  lapply(out, stringi::stri_trim_both)
}




#' Replace or Revert Abbreviations in Text
#'
#' Internal function to temporarily replace abbreviations with placeholders
#' and then revert them back to prevent incorrect sentence splitting.
#'
#' @param text A character vector containing the text.
#' @param abbreviations A character vector of abbreviations to be replaced or reverted.
#'        Defaults to textpress::abbreviations.
#' @param operation A character string, either "replace" or "revert".
#' @return Character vector with abbreviations replaced or reverted.
#' @noRd
.replace_abbreviations <- function(text, abbreviations, operation = "replace") {
  # Create substitutions for the abbreviations by replacing the period with an underscore
  substitutions <- gsub("\\.", "_", abbreviations)

  if (operation == "replace") {
    # Loop through each abbreviation
    for (i in seq_along(abbreviations)) {
      # Special handling for the pattern of single uppercase letters followed by a period
      if (abbreviations[i] == "\\b[A-Z]\\.") {
        # Replace single uppercase letter followed by a period (e.g., "W.") with the letter followed by an underscore
        text <- gsub("(\\b[A-Z])\\.", "\\1_", text)
      } else {
        # For fixed abbreviations, replace them with their corresponding substitutions
        text <- gsub(abbreviations[i], substitutions[i], text, fixed = TRUE)
      }
    }
  } else if (operation == "revert") {
    # Loop through each substitution for reverting back to the original abbreviations
    for (i in seq_along(substitutions)) {
      # Special handling for the pattern of single uppercase letters followed by an underscore
      if (abbreviations[i] == "\\b[A-Z]\\.") {
        # Revert single uppercase letter followed by an underscore back to the letter followed by a period
        text <- gsub("(\\b[A-Z])_", "\\1.", text)
      } else {
        # For fixed abbreviations, revert them back to their original form
        text <- gsub(substitutions[i], abbreviations[i], text, fixed = TRUE)
      }
    }
  } else {
    # Throw an error if an invalid operation is specified
    stop("Invalid operation specified. Choose 'replace' or 'revert'.", call. = FALSE)
  }

  # Return the modified text
  return(text)
}
