#' Group Numeric Vector into Batches Based on Cumulative Sum
#'
#' This function takes a numeric vector and groups its elements into batches.
#' Each batch's cumulative sum does not exceed a specified threshold.
#'
#' @param x A numeric vector to be batched.
#' @param threshold A numeric threshold for the cumulative sum of each batch.
#' @return A numeric vector indicating the batch number for each element of `x`.
#' @export
#' @rdname nlp_batch_cumsum
#'

nlp_batch_cumsum <- function(x, threshold) {

  if (!is.numeric(x)) {
    stop("The first argument 'x' must be a numeric vector.")
  }

  if (!is.numeric(threshold) || length(threshold) != 1) {
    stop("The 'threshold' must be a single numeric value.")
  }


  cumsum <- 0
  group <- 1
  result <- numeric()

  for (i in 1:length(x)) {
    cumsum <- cumsum + x[i]

    if (cumsum > threshold) {
      group <- group + 1
      cumsum <- x[i] }

    result = c(result, group)}

  return (result)
}
