#' Split Text into Paragraphs
#'
#' Splits text from the 'text' column of a data frame into individual paragraphs,
#' based on a specified paragraph delimiter.
#'
#' @param tif A data frame with at least two columns: `doc_id` and `text`.
#' @param paragraph_delim A regular expression pattern used to split text into paragraphs.
#' @return A data.table with columns: `doc_id`, `paragraph_id`, and `text`.
#'         Each row represents a paragraph, along with its associated document and paragraph identifiers.
#' @importFrom data.table data.table
#' @importFrom stringi stri_split_regex
#' @export
#'
nlp_split_paragraphs <- function(tif, paragraph_delim = "\\n+") {
  if (!"text" %in% names(tif)) {
    stop("The data frame must contain a 'text' column.", call. = FALSE)
  }

  df <- data.table::setDT(tif)

  # Split text into paragraphs based on the specified delimiter
  tif[, text := stringi::stri_split_regex(text, paragraph_delim, simplify = FALSE)]
  df_long <- tif[, .(text = unlist(text, use.names = FALSE)), by = .(doc_id)]

  # Filter out empty paragraphs
  df_long <- df_long[!(text == "" | text == " ")]

  # Assign paragraph_id within each document
  df_long[, paragraph_id := seq_len(.N), by = .(doc_id)]
  df_long[, (names(df_long)) := lapply(.SD, as.character), .SDcols = names(df_long)]
  # Reorder columns for output
  data.table::setcolorder(df_long, c("doc_id", "paragraph_id", "text"))

  return(df_long)
}
