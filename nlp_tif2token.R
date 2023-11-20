#' Convert TIF to tokens list -- via corpus package
#'
#' @name tif2token
#' @param tif A TIF
#' @return A list
#'
#'
#' @export
#' @rdname tif2token
#'
#'
tif2token <- function(tif){

  x1 <- corpus::text_tokens(tif$text,

                            filter = corpus::text_filter(
                              map_case = FALSE,
                              combine = c(corpus::abbreviations_en, 'Gov.', 'Sen.'),
                              connector = '_' ) )

  names(x1) <- tif$doc_id
  return(x1)
}
