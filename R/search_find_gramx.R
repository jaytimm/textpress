#' Find Patterns in Text Data
#'
#' This function searches for specific patterns in a text data frame and extracts relevant information.
#'
#' @param search A character string representing the search pattern.
#' @param tif A data frame containing text data in a column named 'text' and document IDs in 'doc_id'.
#' @return A data table with extracted pattern information.
#' @importFrom data.table rbindlist
#' @examples
#' # Example usage
#' # tif <- data.frame(doc_id = 1:2, text = c("Sample text 1", "Sample text 2"))
#' # find_gramx("SEARCH_PATTERN", tif)
#' @export
#' @rdname search_find_gramx
#'
search_find_gramx <- function(search, tif) {

  # Validate input
  if (!is.character(search) || length(search) != 1) {
    stop("The 'search' parameter must be a single character string.")
  }
  if (!("text" %in% names(tif) && "doc_id" %in% names(tif))) {
    stop("The data frame 'tif' must contain 'text' and 'doc_id' columns.")
  }

  query <- translate_query(x = search)

  found <- lapply(1:nrow(tif), function(z) {

    txt <- tif$text[z]
    locations <- gregexpr(pattern = query,
                          text = txt, #,
                          ignore.case = TRUE)

    if (-1 %in% locations){} else {
      data.frame(inline = unlist(regmatches(txt, locations)))}
  })

  names(found) <- tif$doc_id
  found <- Filter(length, found)
  dt <- data.table::rbindlist(found, idcol='doc_id', use.names = F)

  if(nrow(dt) == 0){NA}else{

    dt[, inline := gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", inline)]

    dt[, gramx := gsub("(\\S+)/\\S+/\\S+","\\1", inline) |> trimws()]
    dt[, ngram := nchar(inline)- nchar(gsub(" ", "", inline))]
    dt[, pos := gsub("\\S+/(\\S+)/\\S+","\\1", inline)]

    dt[, nums := gsub("\\S+/\\S+/(\\S+)", "\\1", inline)]
    dt[, start := gsub(' .*$', '', nums) |> as.numeric()]
    dt[, end := gsub('^.* ', '', nums |> trimws()) |> as.numeric()]
    dt[, c('nums') := NULL]
    dt
  }
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
