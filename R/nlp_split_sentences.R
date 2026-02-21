#' Split Text into Sentences
#'
#' This function splits text from a data frame into individual sentences based on specified columns and handles abbreviations effectively.
#'
#' @param corpus A data frame containing text to be split into sentences.
#' @param by Character vector of columns that identify each text row (e.g. \code{"doc_id"}).
#' @param abbreviations A character vector of abbreviations to handle during sentence splitting, defaults to textpress::abbreviations.
#'
#' @return A data.table with columns from \code{by}, plus \code{sentence_id}, \code{text}, \code{start}, \code{end}.
#'
#' @export
#' @examples
#' corpus <- data.frame(doc_id = c('1'),
#'                     text = c("Hello world. This is an example. No, this is a party!"))
#' sentences <- nlp_split_sentences(corpus)
#'
#'
nlp_split_sentences <- function(corpus,
                                by = c("doc_id"),
                                abbreviations = textpress::abbreviations) {
  if (!all(by %in% names(corpus))) {
    stop("The input data frame must contain the specified 'by' columns.", call. = FALSE)
  }

  if (!data.table::is.data.table(corpus)) {
    data.table::setDT(corpus)
  }

  corpus[, text := unlist(lapply(text, function(t) {
    .replace_abbreviations(t, abbreviations, operation = "replace")
  }))]

  if ("paragraph_id" %in% names(corpus)) {
    corpus[, paragraph_offset := cumsum(c(0, nchar(text[-.N]) + 1)), by = "doc_id"]
  } else {
    corpus[, paragraph_offset := 0]
  }

  corpus <- corpus[, .(sentences = lapply(text, .sentence_split)), by = c(by, "paragraph_offset")]

  sentences <- corpus[, .(
    text = unlist(lapply(sentences, `[[`, "text"), use.names = FALSE),
    start = unlist(lapply(sentences, `[[`, "start"), use.names = FALSE) + paragraph_offset,
    end = unlist(lapply(sentences, `[[`, "end"), use.names = FALSE) + paragraph_offset
  ), by = by]

  sentences[, text := .replace_abbreviations(text, abbreviations, operation = "revert")]

  sentences[, sentence_id := seq_len(.N), by = "doc_id"]

  output_columns <- c(by, "sentence_id", "text", "start", "end")
  data.table::setcolorder(sentences, output_columns)

  return(sentences)
}

#' Splits text into sentences while preserving whitespace and spans.
#'
#' @param x Character vector to split.
#' @return List containing sentences with start and end positions.
#' @keywords internal
#' @noRd
.sentence_split <- function(x) {
  # Identify sentence boundaries
  sentence_bounds <- stringi::stri_locate_all_boundaries(x, type = "sentence")[[1]]

  # Extract sentences using precise character positions
  sentences <- stringi::stri_sub(x, sentence_bounds[, 1], sentence_bounds[, 2])
  start_positions <- sentence_bounds[, 1]
  end_positions <- sentence_bounds[, 2]

  return(list(text = sentences, start = start_positions, end = end_positions))
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
