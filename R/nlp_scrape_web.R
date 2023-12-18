#' Scrape News Data from Various Sources
#'
#' Function accepts three types of input:
#' a Google News search query, a direct list of news URLs, or an RSS feed URL. Depending on the input type,
#' it either performs a Google News search and processes the resulting RSS feeds, directly scrapes the
#' provided URLs, or processes an RSS feed to extract URLs for scraping.
#'
#' @param x A character string for the search query or RSS feed URL, or a character vector of URLs.
#' @param input A character string specifying the input type: 'search', 'rss', or 'urls'.
#' @param cores The number of cores to use for parallel processing.
#'
#' @return A data frame containing scraped news data.
#' @export
#' @examples

nlp_scrape_web <- function(x,
                           input = 'search',
                           cores = 3) {
  # Determine the number of cores to use
  cores <- ifelse(cores > 3, min(parallel::detectCores() - 1, 3), cores)

  # Initialize an empty data frame for metadata
  mm <- data.frame(url = character(), stringsAsFactors = FALSE)

  # Process input based on the type
  if (input == 'search') {
    # Process for search term
    mm <- util.build_rss(x = x) |> util.parse_rss()
    mm$url <- util.get_urls(mm$link)  # Assuming 'link' is the column with URLs
  } else if (input == 'rss') {
    # Process for RSS feed URL
    mm <- util.parse_rss(x)  # Assuming this returns a data frame with a URL column
  } else if (input == 'urls') {
    # Directly process list of URLs with no metadata
    mm$url <- x
  } else {
    stop("Invalid input type. Please choose from 'search', 'rss', or 'urls'.")
  }

  # Split urls into batches
  batches <- split(mm$url, ceiling(seq_along(mm$url) / 20))

  # Set up a parallel cluster
  clust <- parallel::makeCluster(cores)
  parallel::clusterExport(cl = clust, varlist = c("util.article_extract"), envir = environment())

  # Execute the task function in parallel
  results <- pbapply::pblapply(X = batches, FUN = util.article_extract, cl = clust)

  # Stop the cluster
  parallel::stopCluster(clust)

  # Combine the results
  combined_results <- data.table::rbindlist(results)

  # If RSS metadata is available (not for simple URLs), merge it with results
  if (input != 'urls') {
    combined_results <- merge(combined_results, mm, by = "url", all = TRUE)
    combined_results[, c('url', 'date', 'source', 'title', 'text')]
  }

  # Select and return relevant columns
  combined_results
}

