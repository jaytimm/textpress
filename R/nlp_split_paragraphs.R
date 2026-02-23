#' Split text into paragraphs
#'
#' Break documents into structural blocks (paragraphs). Splits text from the
#' \code{text} column by a paragraph delimiter.
#'
#' @param corpus Data frame or data.table with a \code{text} column and the identifier columns specified in \code{by}.
#' @param by Character vector of identifier columns that define the text unit (e.g. \code{doc_id} or \code{c("url", "node_id")}). Default \code{c("doc_id")}.
#' @param paragraph_delim Regular expression used to split text into paragraphs (default \code{"\\\\n+"}).
#' @return Data.table with the \code{by} columns, \code{paragraph_id}, and \code{text}. One row per paragraph.
#' @export
#' @examples
#' corpus <- data.frame(doc_id = c('1', '2'),
#'                      text = c("Hello world.\n\nMind your business!",
#'                               "This is an example.n\nThis is a party!"))
#' paragraphs <- nlp_split_paragraphs(corpus)
#'
nlp_split_paragraphs <- function(corpus, by = c("doc_id"), paragraph_delim = "\\n+") {
  if (!"text" %in% names(corpus)) {
    stop("The data frame must contain a 'text' column.", call. = FALSE)
  }
  if (!all(by %in% names(corpus))) {
    stop("Missing 'by' columns.", call. = FALSE)
  }

  df <- data.table::setDT(corpus)

  # Split text into paragraphs based on the specified delimiter
  corpus[, text := stringi::stri_split_regex(text, paragraph_delim, simplify = FALSE)]
  df_long <- corpus[, .(text = unlist(text, use.names = FALSE)), by = by]

  # Filter out empty paragraphs
  df_long <- df_long[!(text == "" | text == " ")]

  # Assign paragraph_id within each group (IDs as character)
  df_long[, paragraph_id := as.character(seq_len(.N)), by = by]
  for (col in by) {
    df_long[, (col) := as.character(get(col))]
  }
  # Reorder columns for output
  data.table::setcolorder(df_long, c(by, "paragraph_id", "text"))

  return(df_long)
}
