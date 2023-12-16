#' Search and Highlight Patterns in a Corpus
#'
#' This function searches for patterns in a text corpus and optionally highlights them.
#'
#' @param tif A data frame representing the text corpus.
#' @param search Character vector of search terms or patterns.
#' @param n Numeric value specifying the number of sentences to include for context.
#' @param is_inline Logical; if TRUE, search uses inline annotations for terms.
#' @param highlight Character vector of length 2 indicating the start and end highlight tags.
#'
#' @return A data frame with the original text and the found patterns highlighted.
#' @import data.table
#' @export
#' @rdname nlp_search_corpus
#'
#' @examples
#' # Assuming 'tif' is a data frame with 'doc_id', 'sentence_id', and 'text' columns
#' search_corpus(tif, search = "example", n = 1)
nlp_search_corpus <- function(tif,
                              search,
                              n = 0,
                              is_inline = FALSE,
                              highlight = c('<', '>')) {

  LL <- gsub("([][{}()+*^$.|\\\\?])", "\\\\\\1", highlight[1])
  RR <- gsub("([][{}()+*^$.|\\\\?])", "\\\\\\1", highlight[2])

  # Initialize data.table
  data.table::setDT(tif)

  # Translation for inline queries
  if (is_inline) {
    term2 <- translate_query(search)
  } else {
    term1 <- paste0('(?i)', search)
    term2 <- paste0(term1, collapse = '|')
  }

  tif[, text_id := paste0(doc_id, '.', sentence_id)]
  tif[, sentence_id := as.integer(sentence_id)]

  found <- stringi::stri_locate_all(tif$text, regex = term2)

  names(found) <- tif$text_id
  found1 <- lapply(found, data.frame)
  df1 <- data.table::rbindlist(found1, idcol='text_id', use.names = F)
  df1 <- subset(df1, !is.na(start))
  df1[, c("doc_id", "sentence_id") := data.table::tstrsplit(text_id, "\\.")]


  df1[, neighbors := lapply(as.integer(sentence_id),
                            function(x) list(c((x - n):(x + n))))]
  df3 <- df1[, .(sentence_id = unlist(neighbors)),
             by = list(text_id, doc_id, start, end)]
  df3[, is_target := ifelse(text_id == paste0(doc_id, '.', sentence_id), 1, 0)]

  ##
  df4 <- tif[df3, on = c('doc_id', 'sentence_id'), nomatch=0]

  df4[, pattern := ifelse(is_target == 1, stringi::stri_sub(text, start, end), '')]
  df4[, text := ifelse(is_target == 1, insert_highlight(text, start, end, highlight = highlight), text)]

  df5 <- df4[, list(text = paste(text, collapse = " ")),
             by = list(i.text_id, start, end)]

  df5[, c("doc_id", "sentence_id") := data.table::tstrsplit(i.text_id, "\\.")]
  patsy <- paste0(".*", LL, "(.*)", RR, ".*")

  df5[, pattern := gsub(patsy, "\\1", text)]

  if(is_inline){
    df5[, pos := gsub("\\S+/(\\S+)/\\S+","\\1", pattern) |> trimws()]
    df5[, pattern2 := gsub("(\\S+)/\\S+/\\S+","\\1", pattern) |> trimws()]} else{

      df5[, pos := NA]
      df5[, pattern2 := NA]
    }

  df5[, c('doc_id',
          'sentence_id',
          'text',
          'start',
          'end',
          'pattern',
          'pattern2', 'pos'), with=FALSE]
}


translate_query <- function(x){

  q <- unlist(strsplit(x, " "))
  y0 <- lapply(q, function(x) {

    if(x == toupper(x)){
      gsub('([A-Z_]+)', '\\\\S+/\\1/[0-9]+ ', x)
    } else{

      paste0(x, '/\\S+/[0-9]+ ')
    } })

  y0 <- gsub('(^.*/[A-Z]*/)(\\S+/)(.*$)', '\\1\\3', y0)

  paste0(y0, collapse = '')
}


insert_highlight <- function(text, start, end, highlight) {
  before_term <- substr(text, 1, start - 1)
  term <- substr(text, start, end)
  after_term <- substr(text, end + 1, nchar(text))

  ## make generic --
  paste0(before_term, highlight[1], term, highlight[2], after_term)
}
