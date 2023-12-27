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
  cores <- ifelse(cores > 3,
                  min(parallel::detectCores() - 1, 3),
                  cores)



  # Initialize an empty data frame for metadata
  mm <- data.frame(url = character())

  # Process input based on the type
  if (input == 'search') {

    # Process for search term
    mm <- .build_rss(x = x) |> .parse_rss()
    mm$url <- .get_urls(mm$link)
  } else if (input == 'rss') {

    # Process for RSS feed URL
    mm <- .parse_rss(x)

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
  parallel::clusterExport(cl = clust,
                          varlist = c(".article_extract"),
                          envir = environment())

  # Execute the task function in parallel
  results <- pbapply::pblapply(X = batches,
                               FUN = .article_extract,
                               cl = clust)

  # Stop the cluster
  parallel::stopCluster(clust)

  # Combine the results
  combined_results <- data.table::rbindlist(results)

  # If RSS metadata is available (not for simple URLs), merge it with results
  if (input != 'urls') {
    combined_results <- merge(combined_results,
                              mm,
                              by = "url",
                              all = TRUE)

    combined_results[, c('url',
                         'date',
                         'source',
                         'title',
                         'text')]
  }

  # Select and return relevant columns
  combined_results
}



#' Article Extraction Utility
#'
#' This internal function extracts articles based on given URLs.
#' It's used within the package for processing news data.
#'
#' @param x A character vector of URLs.
#' @return A data.table of combined article data.
#' @importFrom data.table setDT
#' @noRd

.article_extract <- function (x) {

  # x <- batches[[1]]
  # q <- x[1]
  articles <- lapply(x, function(q) {
    raw_site <- .get_site(q)
    annotated_site <- .annotate_site(site = raw_site)
    clean_site <- subset(annotated_site, annotated_site$discard == 'keep')
    data.table::setDT(clean_site)
    clean_site[, list(text = paste(text, collapse = " ")), by = list(url, h1_title)]
  })

  data.table::rbindlist(articles)
}



#' Get Site Content
#'
#' An internal function that fetches and parses HTML content from a URL.
#'
#' @param x A URL from which to fetch content.
#' @return A data frame with the parsed HTML content.
#' @importFrom xml2 read_html
#' @importFrom httr GET timeout
#' @noRd
#'
.get_site <- function(x) {
  # Attempt to read the HTML content from the URL
  # x <- batches[[1]][1]
  site <- tryCatch(
    xml2::read_html(httr::GET(x, httr::timeout(60))),
    error = function(e) "Error"
  )

  # Initialize default values for type and text as NA
  w1 <- w2 <- NA

  # Check if site reading was successful
  if (!any(site == 'Error')) {
    # Extract nodes of specific types
    ntype1 <- 'p,h1,h2,h3'
    w0 <- rvest::html_nodes(site, ntype1)

    # If nodes are found, update type and text
    if (length(w0) != 0) {
      w1 <- rvest::html_name(w0)
      w2 <- rvest::html_text(w0)

      # Check for valid UTF-8 encoding
      if (any(!validUTF8(w2))) {
        w1 <- w2 <- NA
      }
    }
  }

  # Create and return the data frame
  return(data.frame(url = x, type = w1, text = w2))
}



#' Annotate Site Data
#'
#' An internal function for annotating scraped site data.
#'
#' @param site A data frame of site data to annotate.
#' @return An annotated data frame.
#' @importFrom stats ave
#' @importFrom zoo na.locf
#' @noRd
#'
.annotate_site <- function(site) {

  junk1 <- paste0(.junk_phrases, collapse = '|')
  site$text <- trimws(site$text)

  ## -- title may be empty --
  title <- subset(site, site$type == 'h1')$text
  title <- title[length(title)]
  if(length(title) == 0) {title <- NA}
  site$h1_title <- title

  site$place <- stats::ave(seq_len(nrow(site)),
                           site$url,
                           FUN = seq_along)

  site$not_pnode <- ifelse(site$type == 'p', 0, 1)
  site$has_ellipses <- ifelse(grepl('\\.\\.\\.(.)?$',
                                    site$text), 1, 0)

  ## falsely ids quotations as no stops --
  site$no_stop <-  ifelse(grepl('(\\.|\\!|\\?)(.)?$',
                                gsub("\"|'", '', site$text)),
                          0, 1)

  site$has_latest <- ifelse(grepl('^latest( .*)? news$|^more( .*)? stories$|^related news$',
                                  site$text,
                                  ignore.case = T),
                            1, NA)
  site$has_latest[site$place == 1] <- 0
  site$has_latest <- zoo::na.locf(site$has_latest)

  site$less_10 <- ifelse(nchar(site$text) > 10, 0, 1)
  site$has_junk <- ifelse(grepl(junk1,
                                site$text,
                                ignore.case = T),
                          1, 0)

  site$discard <- rowSums(site[, c("not_pnode",
                                   "has_latest",
                                   "has_ellipses",
                                   "no_stop",
                                   "less_10",
                                   "has_junk")])

  site$discard <- ifelse(site$discard > 0, 'junk', 'keep')

  return(site)
}



