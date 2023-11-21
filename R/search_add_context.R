#' Add Context to Search Results and Highlight Terms
#'
#' This function adds contextual information to search results from a data frame
#' and optionally highlights the search terms.
#'
#' @param gramx A data table containing search results including `doc_id` and other relevant columns.
#' @param df A data frame containing the original text data with `doc_id` and `sentence_id`.
#' @param inline Column name in `gramx` that contains the search terms.
#' @param highlight Optional parameter to specify the highlight style for search terms.
#' @return A data table with contextual information added to the search results.
#' @importFrom data.table setDT
#' @examples
#' # Example usage
#' # gramx <- data.table(doc_id = 1:2, inline = c("search_term1", "search_term2"))
#' # df <- data.frame(doc_id = 1:2, sentence_id = 1:2, token = c("token1", "token2"))
#' # search_add_context(gramx, df)
#'
#' @export
#' @rdname search_add_context
#'

search_add_context <- function(gramx,
                        df,
                        inline = 'inline',
                        highlight = NULL) {

  # Validate input
  if (!is.data.table(gramx)) {
    stop("The argument 'gramx' must be a data table.")
  }
  if (!is.data.frame(df)) {
    stop("The argument 'df' must be a data frame.")
  }
  if (!inline %in% names(gramx)) {
    stop("The 'inline' column does not exist in the 'gramx' data table.")
  }


  data.table::setDT(df)
  data.table::setDT(gramx)
  df0 <- subset(df, doc_id %in% unique(gramx$doc_id))
  df1 <- df[, list(text = paste(token, collapse = " ")),
           by = list(doc_id, sentence_id)]
  df2 <- gramx[df1, on = c('doc_id'), nomatch = 0]


  ### highlight piece --
  if(!is.null(highlight)) {

    if(nchar(highlight) < 3){p1 <- highlight; p2 <- highlight} else{

      p1 <- paste0('<span style="background-color:', highlight, '">')
      p2 <- '</span> '}

    # x3[, pattern := trimws(gsub('/[A-Z_]+', '', construction))]
    df3 <- df2[, text := gsub(gramx, paste0(p1, gramx, p2), text),
       by = list(doc_id, sentence_id, start, end, gramx, ngram, pos)]
    #x3[, pattern := NULL]
    }


  ## x3[, start := NULL]
  return(df3)
}
