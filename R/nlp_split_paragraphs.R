#' Split Text into Paragraphs
#'
#' Splits text from the 'text' column of a data frame into individual paragraphs,
#' based on a specified paragraph delimiter.
#'
#' @param corpus A data frame or data.table containing a \code{text} column and identifier column(s) (e.g. \code{doc_id}).
#' @param paragraph_delim A regular expression pattern used to split text into paragraphs.
#' @return A data.table with columns: `doc_id`, `paragraph_id`, and `text`.
#'         Each row represents a paragraph, along with its associated document and paragraph identifiers.
#' @export
#' @examples
#' corpus <- data.frame(doc_id = c('1', '2'),
#'                      text = c("Hello world.\n\nMind your business!",
#'                               "This is an example.n\nThis is a party!"))
#' paragraphs <- nlp_split_paragraphs(corpus)
#'
#'
nlp_split_paragraphs <- function(corpus, paragraph_delim = "\\n+") {
  if (!"text" %in% names(corpus)) {
    stop("The data frame must contain a 'text' column.", call. = FALSE)
  }

  df <- data.table::setDT(corpus)

  # Split text into paragraphs based on the specified delimiter
  corpus[, text := stringi::stri_split_regex(text, paragraph_delim, simplify = FALSE)]
  df_long <- corpus[, .(text = unlist(text, use.names = FALSE)), by = .(doc_id)]

  # Filter out empty paragraphs
  df_long <- df_long[!(text == "" | text == " ")]

  # Assign paragraph_id within each document
  df_long[, paragraph_id := seq_len(.N), by = .(doc_id)]
  df_long[, (names(df_long)) := lapply(.SD, as.character), .SDcols = names(df_long)]
  # Reorder columns for output
  data.table::setcolorder(df_long, c("doc_id", "paragraph_id", "text"))

  return(df_long)
}
