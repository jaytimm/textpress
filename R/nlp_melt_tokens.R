#' Tokenize Data Frame by Specified Column(s)
#'
#' This function tokenizes a data frame based on a specified token column and groups the data by one or more specified columns.
#'
#' @param df A data frame containing the data to be tokenized.
#' @param melt_col The name of the column in `df` that contains the tokens.
#' @param parent_cols A character vector indicating the column(s) by which to group the data.
#' @return A list of vectors, each containing the tokens of a group defined by the `by` parameter.
#' @export
#' @examples
#' dtm <- data.frame(doc_id = as.character(c(1, 1, 1, 1, 1, 1, 1, 1)),
#'                   sentence_id = as.character(c(1, 1, 1, 2, 2, 2, 2, 2)),
#'                   token = c("Hello", "world", ".", "This", "is", "an", "example", "."))
#'
#' tokens <- nlp_melt_tokens(dtm, melt_col = 'token', parent_cols = c('doc_id', 'sentence_id'))
#'
#'
nlp_melt_tokens <- function(df,
                            melt_col = "token",
                            parent_cols = c("doc_id", "sentence_id")) {
  # Check if the first argument 'df' is a data frame

  # Extract columns specified in 'by' and create a list of these columns
  nn <- lapply(1:length(parent_cols), function(x) df[[parent_cols[x]]])

  # Create a new column 'id99' in 'df' by concatenating the columns in '.' with a separator ':'
  df$id99 <- do.call("paste", c(nn, sep = "."))

  # Split the data frame 'df' into a list of vectors based on 'melt_col', grouped by 'id99'
  split(df[[melt_col]], df$id99)
}
