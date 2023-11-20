#' Find and Highlight Query Terms in Text
#'
#' This function searches for specific query terms in a text data frame.
#' It highlights these terms and provides context from the surrounding text.
#'
#' @param query The search term or pattern.
#' @param text Vector of text strings to be searched.
#' @param doc_id Vector of document identifiers corresponding to the text.
#' @param window Numeric value specifying the number of characters to include for context.
#' @param highlight Vector of characters to use for highlighting the found terms.
#' @return A data frame with document IDs, found patterns, and their context.
#' @importFrom stringi stri_locate_all stri_sub stri_extract
#' @importFrom data.table data.table rbindlist
#' @examples
#' # Example usage
#' # query <- "search_term"
#' # text <- c("Sample text containing search_term", "Another text without")
#' # doc_id <- 1:2
#' # find_lex(query, text, doc_id)
#' @export
#' @rdname search_find_lex
#'
search_find_lex <- function(query,
                     text,
                     doc_id,
                     window = 20L,
                     highlight = c('<', '>')) {

  # Validate input
  if (!is.character(query) || length(query) != 1) {
    stop("The 'query' must be a single character string.")
  }
  if (!is.character(text)) {
    stop("The 'text' must be a character vector.")
  }
  if (!is.character(doc_id)) {
    stop("The 'doc_id' must be a character vector.")
  }
  if (!is.numeric(window) || length(window) != 1) {
    stop("The 'window' must be a single numeric value.")
  }
  if (!is.character(highlight) || length(highlight) > 2) {
    stop("The 'highlight' must be a character vector of length 1 or 2.")
  }



  term1 <- paste0('(?i)', query)
  term2 <- paste0(term1, collapse = '|')
  og <- data.table::data.table(doc_id = as.character(doc_id), t1 = text)

  found <- stringi::stri_locate_all(text, regex = term2)

  names(found) <- doc_id
  found1 <- lapply(found, data.frame)
  df <- data.table::rbindlist(found1, idcol='doc_id', use.names = F)
  df[, doc_id := as.character(doc_id)]
  df <- subset(df, !is.na(start))
  df <- og[df, on = 'doc_id']

  df[, start_w := start - (window*10)]
  df[, end_w := end + (window*10)]

  df[, lhs := stringi::stri_sub(t1, start_w, start-1L)]
  df[, rhs := stringi::stri_sub(t1, end+1L, end_w)]
  df[, pattern := stringi::stri_sub(t1, start, end)]
  #
  wd <- sprintf("^\\S+( \\S+){0,%d}", window)
  df[, rhs := stringi::stri_extract(trimws(rhs),
                                    regex = wd)]

  df[, lhs := stringi::stri_extract(stringi::stri_reverse(trimws(lhs)),
                                    regex = wd)]
  df[, lhs := stringi::stri_reverse(lhs)]
  df[is.na(df)] <- ''

  ## by group --
  df[, id := .I]

  # highlight procedure
  if(!is.null(highlight)) {

    if(length(highlight) == 2){
      p1 <- paste0(' ', highlight[1])
      p2 <- paste0(highlight[2], ' ')} else{
        p1 <- paste0(' <span style="background-color:', highlight, '">')
        p2 <- '</span> '
      }

    df[, context := trimws(paste0(lhs, p1, pattern, p2, rhs))]} else{

      df[, context := trimws(paste(lhs, pattern, rhs, sep = ' '))] }

  df[, c('doc_id', 'id', 'pattern', 'context')]
  #}

}



# ps <- 'part[a-z]*\\b'
# mus <- 'political \\w+'
# term <- c('populism', 'political ideology', 'Many real-world')
#
# jj <- find_lex(query = mus,
#                text = corpus$text,
#                doc_id = corpus$doc_id,
#                window = 99)
