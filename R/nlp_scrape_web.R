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


#' Annotate Website Data
#'
#' This function processes a data.table containing website data and annotates
#' each line, identifying relevant text and removing boilerplate content.
#'
#' @param site A data.table representing the scraped website data.
#' @return A data.table with annotations.
#' @importFrom data.table setDT fifelse nafill last
#' @keywords internal

.annotate_site <- function(site) {

  # Convert to data.table
  data.table::setDT(site)

  # Compile a regular expression pattern for junk phrases
  junk1 <- paste0(textpress:::.junk_phrases, collapse = '|')

  # Trim whitespace from the text column
  site[, text := trimws(text)]

  # Extract the last title from the site, if any
  site[, h1_title := ifelse(type == 'h1', text, NA)]
  site[, h1_title := data.table::last(na.omit(h1_title)), by = .(url)]

  # Assign a sequential number to each row within each URL group
  site[, place := seq_len(.N), by = .(url)]

  # Mark paragraphs and non-paragraph nodes
  site[, not_pnode := data.table::fifelse(type == 'p', 0, 1)]

  # Check for ellipses at the end of text
  site[, has_ellipses := data.table::fifelse(grepl('\\.\\.\\.(.)?$', text), 1, 0)]

  # Identify text without standard sentence-ending punctuation, ignoring quotes
  site[, no_stop := data.table::fifelse(grepl('(\\.|\\!|\\?)(.)?$', gsub("\"|'", '', text)), 0, 1)]

  # Identify specific patterns that indicate non-relevant text
  site[, has_latest := ifelse(grepl('^latest( .*)? news$|^more( .*)? stories$|^related news$', text, ignore.case = TRUE), 1, NA)]

  site[, has_latest := ifelse(place == 1, 0L, has_latest)]
  site[, has_latest := data.table::nafill(has_latest, type = "locf")]

  # Flag text with fewer than 10 characters as potential junk
  site[, less_10 := data.table::fifelse(nchar(text) > 10, 0, 1)]

  # Identify text matching junk phrases
  site[, has_junk := data.table::fifelse(grepl(junk1, text, ignore.case = TRUE), 1, 0)]

  # Combine flags to determine if the row should be discarded
  site[, discard := rowSums(.SD[, .(not_pnode, has_latest, has_ellipses, no_stop, less_10, has_junk)])]
  site[, discard := data.table::fifelse(discard > 0, 'junk', 'keep')]

  return(site)
}


# x <- 'https://time.com/6343967/bidenomics-is-real-economics/'
# site <- x |> .get_site()
# annotated_site <- site |> .annotate_site()
# clean_site <- annotated_site |> .article_extract()
