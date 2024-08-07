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
#' \dontrun{
#' url <- 'https://www.nytimes.com/2024/03/25/nyregion/trump-bond-reduced.html'
#' article_tif <- web_scrape_urls(x = url, input = 'urls', cores = 1)
#'}
#'
#'
web_scrape_urls <- function(x,
                            input = "search",
                            cores = 3) {
  # Process input based on the type
  if (input == "search") {
    mm <- .build_rss(x)
    mm1 <- .parse_rss(mm)
    mm1$url <- .get_urls(mm1$link)

  } else if (input == "rss") {
    mm1 <- .parse_rss(x)
  } else if (input == "urls") {
    mm1 <- data.frame(url = x)
  } else {
    stop("Invalid input type. Please choose from 'search', 'rss', or 'urls'.")
  }

  # Split urls into batches
  batches <- split(mm1$url, ceiling(seq_along(mm1$url) / 20))

  if (cores == 1) {
    # Sequential processing
    results <- lapply(
      X = batches,
      FUN = .article_extract
    )
  } else {
    # Set up a parallel cluster
    clust <- parallel::makeCluster(cores)
    parallel::clusterExport(
      cl = clust,
      varlist = c(".article_extract"),
      envir = environment()
    )

    # Execute the task function in parallel
    results <- pbapply::pblapply(
      X = batches,
      FUN = .article_extract,
      cl = clust
    )

    # Stop the cluster
    parallel::stopCluster(clust)
  }

  # Combine the results
  combined_results <- data.table::rbindlist(results)

  # If RSS metadata is available (not for simple URLs), merge it with results
  if (input != "urls") {
    combined_results <- merge(combined_results,
      mm1,
      by = "url",
      all = TRUE
    )

    combined_results[, c(
      "url",
      "date",
      "source",
      "title",
      "text"
    )]
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
#' @importFrom stats na.omit
#' @noRd

.article_extract <- function(x) {
  # Apply a function to each URL in the list 'x'
  articles <- lapply(x, function(q) {
    # Retrieve the content of the website for the given URL
    raw_site <- .get_site(q)

    # Annotate the retrieved website content
    annotated_site <- .annotate_site(site = raw_site)

    # Filter the annotated content to keep relevant parts
    clean_site <- subset(annotated_site, annotated_site$discard == "keep")

    # Aggregate the text by 'url' and 'h1_title', collapsing it into a single string
    clean_site[, list(text = paste(text, collapse = "\n\n")), by = list(url, h1_title)]
  })

  # Combine the list of data.tables into a single data.table and return it
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
  if (!any(site == "Error")) {
    # Extract nodes of specific types
    ntype1 <- "p,h1,h2,h3"
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
#' @importFrom stringr str_trim
#' @noRd

.annotate_site <- function(site) {
  # Convert to data.table
  data.table::setDT(site)

  # Compile a regular expression pattern for junk phrases
  junk1 <- paste0(.junk_phrases, collapse = "|")

  # Trim whitespace from the text column
  site[, text := stringr::str_trim(text)]

  # Extract the last title from the site, if any
  site[, h1_title := ifelse(type == "h1", text, NA)]
  site[, h1_title := data.table::last(na.omit(h1_title)), by = .(url)]

  # Assign a sequential number to each row within each URL group
  site[, place := seq_len(.N), by = .(url)]

  # Mark paragraphs and non-paragraph nodes
  site[, not_pnode := data.table::fifelse(type == "p", 0, 1)]

  # Check for ellipses at the end of text
  site[, has_ellipses := data.table::fifelse(grepl("\\.\\.\\.(.)?$", text), 1, 0)]

  # Identify text without standard sentence-ending punctuation, ignoring quotes
  site[, no_stop := data.table::fifelse(grepl("(\\.|\\!|\\?)(.)?$", gsub("\"|'", "", text)), 0, 1)]

  # Identify specific patterns that indicate non-relevant text
  site[, has_latest := ifelse(grepl("^latest( .*)? news$|^more( .*)? stories$|^related news$", text, ignore.case = TRUE), 1, NA)]

  site[, has_latest := ifelse(place == 1, 0L, has_latest)]
  site[, has_latest := data.table::nafill(has_latest, type = "locf")]

  # Flag text with fewer than 10 characters as potential junk
  site[, less_10 := data.table::fifelse(nchar(text) > 10, 0, 1)]

  # Identify text matching junk phrases
  site[, has_junk := data.table::fifelse(grepl(junk1, text, ignore.case = TRUE), 1, 0)]

  # Combine flags to determine if the row should be discarded
  site[, discard := rowSums(.SD[, .(not_pnode, has_latest, has_ellipses, no_stop, less_10, has_junk)])]
  site[, discard := data.table::fifelse(discard > 0, "junk", "keep")]

  return(site)
}



#' Internal Junk Phrases for Text Filtering
#'
#' A vector of regular expressions used internally for identifying and
#' filtering common unwanted phrases in text data. This is particularly
#' useful for processing web-scraped content or emails within package functions.
#'
#' @details
#' `junk_phrases` contains regular expressions matching various common
#' phrases often found in promotional, instructional, or administrative
#' web content. These expressions are used in internal functions to
#' filter out such content during text processing.
#'
#' @noRd
#'
.junk_phrases <- c(
  "your (email )?inbox",
  "all rights reserved",
  "free subsc",
  "^please",
  "^sign up",
  "Check out",
  "^Get",
  "^got",
  "^you must",
  "^you can",
  "^Thanks",
  "^We ",
  "^We've",
  "login",
  "log in",
  "logged in",
  "Data is a real-time snapshot",
  "^do you",
  "^subscribe to",
  "your comment"
)
