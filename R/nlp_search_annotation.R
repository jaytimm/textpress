#' Search in Document-Term Matrix
#'
#' This function searches within a Document-Term Matrix (df) using specified
#' inclusion and exclusion criteria and returns a subset of the df based on the search.
#'
#' @param df A Document-Term Matrix (df) or data frame to be searched.
#' @param search_col The name of the column in the df to search through.
#' @param id_col The name of the column in the df representing document IDs.
#' @param include A vector of terms to include in the search.
#' @param logic A character string specifying the logic to use: 'or' or 'and'.
#' @param exclude An optional vector of terms to exclude from the search.
#'
#' @return A subset of the df based on the search criteria.
#' @export
#' @rdname nlp_search_annotation
#' @examples
#' df <- data.frame(doc_id = 1:3, text = c("apple banana", "banana cherry", "cherry apple"))
#' search_df(df, "text", "doc_id", include = c("apple", "banana"), logic = "or")
#' search_df(df, "text", "doc_id", include = c("apple", "banana"), logic = "and", exclude = "cherry")
nlp_search_annotation <- function(df,
                                  search_col,
                                  id_col,
                                  include,
                                  logic = 'or',
                                  exclude = NULL) {

  data.table::setDT(df)

  include <- tolower(include)
  exclude <- tolower(exclude)

  if (logic == 'or') {
    df <- df[df[[search_col]] %in% include, .SD, by = .(df[[id_col]])]
  } else {  # 'and' logic
    ids <- df[df[[search_col]] %in% include, unique(df[[id_col]])]
    for (term in include) {
      ids <- intersect(ids, df[df[[search_col]] == term, unique(df[[id_col]])])
    }
    df <- df[df[[id_col]] %in% ids]
  }

  if (!is.null(exclude)) {
    ids_to_exclude <- df[df[[search_col]] %in% exclude, unique(df[[id_col]])]
    df <- df[!df[[id_col]] %in% ids_to_exclude]
  }

  return(df)
}
