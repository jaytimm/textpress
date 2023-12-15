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
#' @rdname nlp_search_df
#' @examples
#' df <- data.frame(doc_id = 1:3, text = c("apple banana", "banana cherry", "cherry apple"))
#' search_df(df, "text", "doc_id", include = c("apple", "banana"), logic = "or")
#' search_df(df, "text", "doc_id", include = c("apple", "banana"), logic = "and", exclude = "cherry")
nlp_search_df <- function(df,
                          search_col,
                          id_col,
                          include,
                          logic = 'and',
                          exclude = NULL) {
  # Convert the data frame to a data table
  data.table::setDT(df)

  # Validate input parameters
  if (!search_col %in% names(df)) {
    stop("search_col not found in the data frame.")
  }
  if (!id_col %in% names(df)) {
    stop("id_col not found in the data frame.")
  }

  # Convert search criteria to lowercase for case-insensitive matching
  #df[, (search_col) := tolower(get(search_col))]

  include <- tolower(include)
  exclude <- tolower(exclude)

  # Apply 'or' or 'and' logic for inclusion criteria
  if (logic == 'or') {
    df <- df[get(search_col) |> tolower() %in% include, .SD, by = .(get(id_col))]
  } else {  # 'and' logic
    ids <- df[get(search_col) |> tolower() %in% include, unique(get(id_col))]
    for (term in include) {
      ids <- intersect(ids, df[get(search_col) |> tolower() == term, unique(get(id_col))])
    }
    df <- df[get(id_col) %in% ids]
  }

  # Apply exclusion criteria if specified
  if (!is.null(exclude)) {
    ids_to_exclude <- df[get(search_col) |> tolower() %in% exclude, unique(get(id_col))]
    df <- df[!get(id_col) %in% ids_to_exclude]
  }

  return(df)
}
