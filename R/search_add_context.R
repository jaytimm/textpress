#' Add context to search results
#'
#' @name add_context
#' @param gramx output from find_gramx()
#' @param df Annotion dataframe
#' @param form A character string
#' @param tag A character string
#' @param highlight A boolean
#' @return A data frame
#'
#' @export
#' @rdname search_add_context
#'

search_add_context <- function(gramx,
                        df,
                        inline = 'inline',
                        highlight = NULL) {

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
