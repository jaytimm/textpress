#' Tokenize Data Frame by Specified Column(s)
#'
#' This function tokenizes a data frame based on a specified token column and groups the data by one or more specified columns.
#'
#' @param df A data frame containing the data to be tokenized.
#' @param token The name of the column in `df` that contains the tokens.
#' @param by A character vector indicating the column(s) by which to group the data.
#' @return A list of vectors, each containing the tokens of a group defined by the `by` parameter.
#' @export
#' @rdname nlp_melt_tokens
#'
#'
nlp_melt_tokens <- function(df,
                            token,
                            by = c('doc_id')){

  # Validate input
  if (!is.data.frame(df)) {
    stop("The first argument must be a data frame.")
  }
  if (!is.character(token) || !(token %in% names(df))) {
    stop("The 'token' must be a valid column name in the data frame.")
  }
  if (!all(by %in% names(df))) {
    stop("All elements of 'by' must be valid column names in the data frame.")
  }



  nn <- lapply(1:length(by), function(x) df[[by[x]]])
  df$id99 <- do.call("paste", c(nn, sep=":"))
  split(df[[token]], df$id99)

  }
