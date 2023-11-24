#' Search in Document-Term Matrix
#'
#' This function searches within a Document-Term Matrix (DTM) using specified
#' inclusion and exclusion criteria and returns a subset of the DTM based on the search.
#'
#' @param dtm A Document-Term Matrix (DTM) or data frame to be searched.
#' @param search_col The name of the column in the DTM to search through.
#' @param id_col The name of the column in the DTM representing document IDs.
#' @param include A vector of terms to include in the search.
#' @param logic A character string specifying the logic to use: 'or' or 'and'.
#' @param exclude An optional vector of terms to exclude from the search.
#'
#' @return A subset of the DTM based on the search criteria.
#' @export
#'
#' @examples
#' dtm <- data.frame(doc_id = 1:3, text = c("apple banana", "banana cherry", "cherry apple"))
#' search_dtm(dtm, "text", "doc_id", include = c("apple", "banana"), logic = "or")
#' search_dtm(dtm, "text", "doc_id", include = c("apple", "banana"), logic = "and", exclude = "cherry")
search_dtm <- function(dtm,
                       search_col,
                       id_col,
                       include,
                       logic = 'or',
                       exclude = NULL) {

  data.table::setDT(dtm)

  include <- tolower(include)
  exclude <- tolower(exclude)

  if (logic == 'or') {
    dtm <- dtm[dtm[[search_col]] %in% include, .SD, by = .(dtm[[id_col]])]
  } else {  # 'and' logic
    ids <- dtm[dtm[[search_col]] %in% include, unique(dtm[[id_col]])]
    for (term in include) {
      ids <- intersect(ids, dtm[dtm[[search_col]] == term, unique(dtm[[id_col]])])
    }
    dtm <- dtm[dtm[[id_col]] %in% ids]
  }

  if (!is.null(exclude)) {
    ids_to_exclude <- dtm[dtm[[search_col]] %in% exclude, unique(dtm[[id_col]])]
    dtm <- dtm[!dtm[[id_col]] %in% ids_to_exclude]
  }

  return(dtm)
}
