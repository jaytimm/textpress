#' Build RSS Feed URL
#'
#' This function constructs an RSS feed URL based on the given query. If no query is provided, it defaults to the top news URL.
#' @param x A string query to search in the RSS feed, defaults to NULL for top news.
#' @return A string containing the URL of the RSS feed.
#' @examples
#' .build_rss() # returns top news RSS feed
#' .build_rss("technology AND innovation") # returns RSS feed for technology and innovation news
#' @noRd
.build_rss <- function(x = NULL) {
  # Define RSS feed URL components
  clang_suffix <- 'hl=en-US&gl=US&ceid=US:en&q='
  base <- "https://news.google.com/news/rss/search?"
  tops <- "https://news.google.com/news/rss/?ned=us&hl=en&gl=us"

  # Handle case when no query is provided
  if(is.null(x)) {
    return(tops)
  } else {
    # Process the query for URL encoding
    x <- strsplit(x, ' AND ')[[1]]
    y <- unlist(lapply(x, URLencode))
    y1 <- lapply(y, function(q) gsub('(^.*$)', '%22\\1%22', q))

    # Construct the search URL
    search1 <- paste(y1, collapse = "%20AND%20")
    return(paste0(base, clang_suffix, search1))
  }
}


#' Retrieve URLs from a List of Web Pages
#'
#' This function takes a vector of URLs, attempts to retrieve HTML content from each, and extracts specific text elements.
#' @param x A character vector of URLs.
#' @return A character vector with the extracted text from each URL or NA if retrieval fails.
#' @examples
#' urls <- c("http://example.com", "http://example.org")
#' .get_urls(urls)
#' @noRd
.get_urls <- function(x){
  # Use lapply to process each URL in the vector
  result <- lapply(x, function(q) {
    # Attempt to retrieve HTML content
    site <- tryCatch(
      xml2::read_html(httr::GET(q, httr::timeout(60))),
      error = function(e) NA
    )

    # If retrieval fails, return NA
    if (is.na(site)) {
      NA
    } else {
      # Extract and process text elements
      linkto <- xml2::xml_find_all(site, "c-wiz") |>
        xml2::xml_text()
      gsub("Opening ", "", linkto)
    }
  })

  # Unlist and return the result
  unlist(result)
}



#' Parse RSS Feed
#'
#' This function takes an RSS feed XML content and extracts relevant information such as title, link, publication date, and source.
#' @param x XML content of an RSS feed.
#' @return A data frame containing columns for date, source, title, and link. Returns NA in case of an error.
#' @examples
#' rss_content <- xml2::read_xml("http://example.com/rss")
#' .parse_rss(rss_content)
#' @noRd
.parse_rss <- function(x) {
  # Try to read the XML content, return NA on error
  doc <- tryCatch(
    xml2::read_xml(x),
    error = function(e) return(NA)
  )

  if (is.na(doc)) {
    return(NA)
  } else {
    # Extracting the necessary elements from the XML
    title1 <- xml2::xml_text(xml2::xml_find_all(doc, "//item/title"))
    title <- gsub(" - .*$", "", title1)
    link <- xml2::xml_text(xml2::xml_find_all(doc, "//item/link"))
    pubDate <- xml2::xml_text(xml2::xml_find_all(doc, "//item/pubDate"))

    source1 <- sub("^.* - ", "", title1)
    source2 <- xml2::xml_text(xml2::xml_find_all(doc, "//channel/title"))

    # Determine the source based on the XML structure
    source <- if (grepl("Google News", source2)) source1 else source2

    # Formatting the publication date
    date <- gsub("^.+, ", "", pubDate)
    date <- gsub(" [0-9]*:.+$", "", date)
    date <- as.Date(date, "%d %b %Y")

    # Returning the results as a data frame
    data.frame(date, source, title, link)
  }
}
