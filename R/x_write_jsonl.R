#' Write DataFrame to a JSON Lines File
#'
#' This function takes a data frame and writes it to a file in the JSON Lines format,
#' where each line is a JSON representation of one row of the data frame.
#'
#' @param df The data frame to be written to file.
#' @param file_name The path to the file where the data frame should be written.
#' @importFrom jsonlite toJSON
#' @export
#' @examples
#' # Example usage
#' # df <- data.frame(a = 1:3, b = letters[1:3])
#' # nlp_write_jsonl(df, "example.jsonl")

#' @export
#' @rdname x_write_jsonl
#'
x_write_jsonl <- function(df, file_name) {

  if (!is.data.frame(df)) {
    stop("The first argument must be a data frame.")
  }
  if (!is.character(file_name) || length(file_name) != 1) {
    stop("The file name must be a single string.")
  }


  # Open a connection to the file
  con <- file(file_name, "w")

  # Write each row of the dataframe as a JSON object followed by a newline
  apply(df, 1, function(row) {
    writeLines(jsonlite::toJSON(as.list(row), auto_unbox = TRUE), con)
  })

  # Close the connection
  close(con)
}

# usage
# setwd('/home/jtimm/Dropbox/UNM/nlp/newsdesk/')
# write_jsonl(arts0, "news.jsonl")
