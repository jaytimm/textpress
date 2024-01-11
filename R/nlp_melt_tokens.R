#' Tokenize Data Frame by Specified Column(s)
#'
#' This function tokenizes a data frame based on a specified token column and groups the data by one or more specified columns.
#'
#' @param df A data frame containing the data to be tokenized.
#' @param word_form The name of the column in `df` that contains the tokens.
#' @param by A character vector indicating the column(s) by which to group the data.
#' @return A list of vectors, each containing the tokens of a group defined by the `by` parameter.
#' @export
#' @rdname nlp_melt_tokens
#'
#'
# Define the function 'nlp_melt_tokens' with parameters 'df', 'word_form', and an optional 'by'
nlp_melt_tokens <- function(df,
                            word_form,
                            by = c("doc_id")) {
  # Check if the first argument 'df' is a data frame

  if (!is.data.frame(df)) {
    stop("The first argument must be a data frame.")
  }

  # Check if 'word_form' is a character string and a valid column name in 'df'
  if (!is.character(word_form) || !(word_form %in% names(df))) {
    stop("The 'word_form' must be a valid column name in the data frame.")
  }

  # Check if all elements of 'by' are valid column names in 'df'
  if (!all(by %in% names(df))) {
    stop("All elements of 'by' must be valid column names in the data frame.")
  }

  # Extract columns specified in 'by' and create a list of these columns
  nn <- lapply(1:length(by), function(x) df[[by[x]]])

  # Create a new column 'id99' in 'df' by concatenating the columns in 'nn' with a separator ':'
  df$id99 <- do.call("paste", c(nn, sep = ":"))

  # Split the data frame 'df' into a list of vectors based on 'word_form', grouped by 'id99'
  split(df[[word_form]], df$id99)

  df$id99 <- do.call("paste", c(nn, sep = ":"))
  split(df[[token]], df$id99)
}
