#' Group Numeric Vector into Batches Based on Cumulative Sum
#'
#' This function takes a numeric vector and groups its elements into batches.
#' Each batch's cumulative sum does not exceed a specified threshold.
#'
#' @param x A numeric vector to be batched.
#' @param threshold A numeric threshold for the cumulative sum of each batch.
#' @return A numeric vector indicating the batch number for each element of `x`.
#' @export
#' @rdname rag_batch_cumsum
#'

# Define the function 'rag_batch_cumsum' with parameters 'x' and 'threshold'
rag_batch_cumsum <- function(x, threshold) {
<<<<<<< HEAD

  # Check if 'x' is a numeric vector
=======
>>>>>>> eacaa60f063c49bc7c6c4d833c86772231b3b657
  if (!is.numeric(x)) {
    stop("The first argument 'x' must be a numeric vector.")
  }

  # Check if 'threshold' is a single numeric value
  if (!is.numeric(threshold) || length(threshold) != 1) {
    stop("The 'threshold' must be a single numeric value.")
  }

  # Initialize variables for cumulative sum and grouping
  cumsum <- 0
  group <- 1
  result <- numeric()

  # Loop through each element in 'x'
  for (i in 1:length(x)) {
    cumsum <- cumsum + x[i]  # Update the cumulative sum

    # Check if the cumulative sum exceeds the threshold
    if (cumsum > threshold) {
<<<<<<< HEAD
      group <- group + 1  # Increment the group number
      cumsum <- x[i]  # Reset the cumulative sum for the new group
    }

    # Append the current group number to the result vector
    result = c(result, group)
  }

  # Return the vector containing group numbers
  return (result)
=======
      group <- group + 1
      cumsum <- x[i]
    }

    result <- c(result, group)
  }

  return(result)
>>>>>>> eacaa60f063c49bc7c6c4d833c86772231b3b657
}
