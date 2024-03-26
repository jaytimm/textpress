#' Split Text into Sentences
#'
#' This function splits text from a data frame into individual sentences based on specified columns and handles abbreviations effectively.
#'
#' @param tif A data frame containing text to be split into sentences.
#' @param text_hierarchy A character vector specifying the columns to group by for sentence splitting, usually 'doc_id'.
#' @param abbreviations A character vector of abbreviations to handle during sentence splitting, defaults to textpress::abbreviations.
#'
#' @return A data.table with columns specified in 'by', 'sentence_id', and 'text'.
#'
#' @export
#' @examples
#' tif <- data.frame(doc_id = c('1'),
#'                   text = c("Hello world. This is an example. No, this is a party!"))
#' sentences <- nlp_split_paragraphs(tif)
#'
#'
nlp_split_sentences <- function(tif,
                                text_hierarchy = c("doc_id"),
                                abbreviations = textpress::abbreviations) {
  # Validate input data frame structure
  if (!all(text_hierarchy %in% names(tif))) {
    stop("The input data frame must contain specified 'by' columns.", call. = FALSE)
  }

  # Convert to data.table if not already
  if (!data.table::is.data.table(tif)) {
    data.table::setDT(tif)
  }

  # Replace abbreviations with placeholders
  tif[, text := unlist(lapply(text, function(t) {
    .replace_abbreviations(t, abbreviations, operation = "replace")
  }))]

  # Split text into sentences
  tif <- tif[, .(sentences = lapply(text, .sentence_split)), by = text_hierarchy]


  # Flatten the list into a long data.table of sentences
  sentences <- tif[, .(text = unlist(sentences, use.names = FALSE)), by = text_hierarchy]

  # Revert placeholders back to abbreviations
  sentences$text <- .replace_abbreviations(sentences$text, abbreviations, operation = "revert")

  # Assign sentence_id within each group specified by 'by'
  sentences[, sentence_id := seq_len(.N), by = text_hierarchy]


  ### This is no good --
  # Reorder columns for output
  if ("paragraph_id" %in% text_hierarchy) {
    output_columns <- c(text_hierarchy, "sentence_id", "text")
  } else {
    output_columns <- c("doc_id", "sentence_id", "text")
  }

  data.table::setcolorder(sentences, output_columns)
  sentences[, (names(sentences)) := lapply(.SD, as.character), .SDcols = names(sentences)]

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
  abbreviations <- c(abbreviations, toupper(abbreviations))
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
        text <- gsub(abbreviations[i],
                     substitutions[i],
                     text,
                     fixed = TRUE)
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
        text <- gsub(substitutions[i],
                     abbreviations[i],
                     text,
                     fixed = TRUE)
      }
    }
  } else {
    # Throw an error if an invalid operation is specified
    stop("Invalid operation specified. Choose 'replace' or 'revert'.", call. = FALSE)
  }

  # Return the modified text
  return(text)
}
