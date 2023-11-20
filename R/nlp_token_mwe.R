#' Convert Tokens to Multi-Word Expressions
#'
#' This function processes a list of tokens, identifying and concatenating multi-word expressions (MWEs)
#' based on specified patterns using the 'quanteda' package.
#'
#' @param tok A list where each element contains tokens corresponding to a document or a sentence.
#' @param mwe Character vector of multi-word expressions to be identified and concatenated.
#' @param concat The string to use for concatenating the tokens in each multi-word expression.
#' @return A list of tokens with specified multi-word expressions concatenated.
#' @importFrom quanteda as.tokens tokens_compound phrase
#' @examples
#' # Example usage
#' # tok <- list(doc1 = c("the", "quick", "brown", "fox"), doc2 = c("jumps", "over", "the", "lazy", "dog"))
#' # mwe <- c("quick brown fox", "lazy dog")
#' # token2mwe(tok, mwe)
#'
#' @export
#' @rdname nlp_token_mwe
#'
#'
nlp_token_mwe <- function(tok, mwe, concat = '_'){

  # Validate input
  if (!is.list(tok)) {
    stop("The argument 'tok' must be a list.")
  }
  if (!is.character(mwe)) {
    stop("The 'mwe' parameter must be a character vector.")
  }
  if (!is.character(concat) || length(concat) != 1) {
    stop("The 'concat' parameter must be a single character string.")
  }


  x1 <- quanteda::as.tokens(tok)
  x2 <- quanteda::tokens_compound(x1,
                                  pattern = quanteda::phrase(mwe),
                                  concatenator = concat)

  return(as.list(x2))
}
