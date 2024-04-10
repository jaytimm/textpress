#' Pretty Print Text for NLP
#'
#' Formats and prints text to make it more readable, especially useful in NLP tasks.
#' It allows the option to truncate text to a specific character length and to wrap
#' text to a specified width.
#'
#' @param x A character vector; the text to be formatted.
#' @param width An integer; the width to wrap the text at. Defaults to 50.
#' @param char_length An optional integer; the maximum character length of the text.
#' If specified, text longer than this will be truncated.
#'
#' @return The function prints formatted text and does not return a value.
#'
#' @examples
#' nlp_pretty_text("This is an example of a longer string that will be wrapped for better readability", width = 40)
#' # With character length limit
#' nlp_pretty_text("This is an example of a longer string", width = 40, char_length = 20)
#'
#' @export
nlp_pretty_text <- function(x, width = 50L, char_length = NULL) {
  # Validate inputs
  if (!is.character(x)) {
    stop("'x' must be a character vector.")
  }
  if (!is.null(width) && (!is.numeric(width) || width <= 0)) {
    stop("'width' must be a positive integer.")
  }
  if (!is.null(char_length) && (!is.numeric(char_length) || char_length <= 0)) {
    stop("'char_length' must be a positive integer or NULL.")
  }

  # Truncate the text to the character limit if specified
  if (!is.null(char_length) && nchar(x) > char_length) {
    x <- substr(x, 1, char_length)
  }

  # Wrap the text and write lines
  wrapped_text <- strwrap(x, width = width)
  writeLines(wrapped_text)
}
