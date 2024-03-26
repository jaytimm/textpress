#' Process Google News Feed
#'
#' This function takes a search term, builds an RSS feed from Google News, parses it,
#' and retrieves URLs, returning a dataframe with the relevant article metadata.
#'
#' @param x A character string representing the search term for the Google News feed.
#' @return A dataframe with columns corresponding to the parsed RSS feed,
#'         including URL, title, date, and other relevant metadata.
#' @export
#' @examples
#' \dontrun{
#' meta <- web_process_gnewsfeed("Bidenomics")
#' }
#'
web_process_gnewsfeed <- function(x) {
  # Build an RSS feed URL using the provided search query and parse the RSS feed
  mm <- .build_rss(x)
  mm1 <- .parse_rss(mm)
  # Use the parsed RSS feed to extract URLs from the links and add them to 'mm'
  mm1$url <- .get_urls(mm1$link)

  # Return the modified data frame 'mm' with the added URL information
  return(mm1)
}
