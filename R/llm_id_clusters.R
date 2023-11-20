#' Identify Clusters in Data using DBSCAN
#'
#' This function applies DBSCAN clustering to a data frame and marks each point as belonging to a cluster.
#' It also identifies representative points in each cluster and flags non-clustered points as 'noise'.
#'
#' @param df A data frame containing the points to be clustered.
#'           The data frame should have at least two columns named 'x' and 'y'.
#' @param eps The maximum distance between two samples for them to be considered as in the same neighborhood (DBSCAN parameter).
#' @param minPts The number of samples in a neighborhood for a point to be considered as a core point (DBSCAN parameter).
#' @return A data frame with the original data plus 'cluster', and 'remove_flag' columns.
#' @importFrom data.table setDT
#' @importFrom dbscan dbscan
#' @export
#' @examples
#' # Example usage
#' # df <- data.frame(x = rnorm(10), y = rnorm(10))

#' @export
#' @rdname llm_id_clusters
#'
llm_id_clusters <- function(df, eps = 0.1, minPts = 2) {

  # Validate input
  if (!("x" %in% names(df) && "y" %in% names(df))) {
    stop("The data frame must contain 'x' and 'y' columns.")
  }

  # Convert to data.table if it's not
  data.table::setDT(df)

  # Apply DBSCAN clustering
  clustering <- dbscan::dbscan(df[, .(x, y)], eps = eps, minPts = minPts)

  # Add cluster labels to points data table
  df[, cluster := clustering$cluster]
  ## data.table::setorder(df, id)

  # Mark the first point in each cluster as not reduced (representative)
  df[, is_rep := .I == min(.I), by = cluster]

  # Flag noise points (non-clustered points) as not reduced and label them as 'noise'
  df[, remove_flag := ifelse(cluster != 0 & !is_rep, 1, 0)]

  # Return the modified dataframe with the new 'reduced' and 'cluster' columns
  return(df[, .(id, cluster, remove_flag)])
}
