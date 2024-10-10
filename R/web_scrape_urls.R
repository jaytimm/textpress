#' Scrape News Data from Various Sources
#'
#' Function scrapes content of provided list of URLs.
#'
#' @param x A character vector of URLs.
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
                            cores = 3) {

  mm1 <- data.frame(url = x)
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

  data.table::rbindlist(results)

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
    clean_site[, list(text = paste(text, collapse = "\n\n")), by = list(url, h1_title, date)]
  })

  # Combine the list of data.tables into a single data.table and return it
  data.table::rbindlist(articles)
}


#' Get Site Content and Extract HTML Elements
#'
#' This function attempts to retrieve the HTML content of a URL, extract specific
#' HTML elements (e.g., paragraphs, headings), and extract publication date information
#' using the \code{extract_date} function.
#'
#' @param x A URL to extract content and publication date from.
#' @return A data frame with columns for the URL, HTML element types, text content, extracted date, and date source.
#' @importFrom httr GET timeout
#' @importFrom xml2 read_html
#' @importFrom rvest html_nodes html_text html_name
#' @export
.get_site <- function(x) {
  # Attempt to read the HTML content from the URL
  site <- tryCatch(
    xml2::read_html(httr::GET(x, httr::timeout(60))),
    error = function(e) "Error"
  )

  # Initialize default values for type, text, and date
  w1 <- w2 <- NA
  date_info <- data.frame(date = NA_character_, source = NA_character_)

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

    # Extract publication date
    date_info <- extract_date(site)
  }

  # Create and return the data frame with type, text, and publication date
  return(data.frame(
    url = x,
    type = w1,
    text = w2,
    date = date_info$date,
    date_source = date_info$source
  ))
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




#' Standardize Date Format
#'
#' This function attempts to parse a date string using multiple formats and
#' standardizes it to "YYYY-MM-DD". It first tries ISO 8601 formats,
#' and then common formats like ymd, dmy, and mdy.
#'
#' @param date_str A character string representing a date.
#' @return A character string representing the standardized date in "YYYY-MM-DD" format, or NA if the date cannot be parsed.
#' @importFrom lubridate ymd_hms ymd dmy mdy
#' @export
standardize_date <- function(date_str) {
  # Try parsing as ISO 8601
  parsed_date <- suppressWarnings(tryCatch(lubridate::ymd_hms(date_str, tz = "UTC"), error = function(e) NA))

  # Try other common formats if the first attempt fails
  if (all(is.na(parsed_date))) {
    parsed_date <- suppressWarnings(tryCatch(lubridate::ymd(date_str), error = function(e) NA))
  }

  if (all(is.na(parsed_date))) {
    parsed_date <- suppressWarnings(tryCatch(lubridate::dmy(date_str), error = function(e) NA))
  }

  if (all(is.na(parsed_date))) {
    parsed_date <- suppressWarnings(tryCatch(lubridate::mdy(date_str), error = function(e) NA))
  }

  # Return the first non-NA parsed date or NA if all attempts fail
  first_valid_date <- parsed_date[!is.na(parsed_date)][1]

  # Format as "YYYY-MM-DD" if a valid date exists, else return NA
  if (!is.na(first_valid_date)) {
    return(format(first_valid_date, "%Y-%m-%d"))
  } else {
    return(NA)
  }
}




#' Extract Date from HTML Content
#'
#' This function attempts to extract a publication date from the HTML content
#' of a web page using various methods such as JSON-LD, OpenGraph meta tags,
#' standard meta tags, and common HTML elements.
#'
#' @param site An HTML document (as parsed by xml2 or rvest) from which to extract the date.
#' @return A data.frame with two columns: `date` and `source`, indicating the extracted
#' date and the source from which it was extracted (e.g., JSON-LD, OpenGraph, etc.).
#' If no date is found, returns NA for both fields.
#' @importFrom rvest html_nodes html_text html_attr
#' @importFrom jsonlite fromJSON
#' @importFrom xml2 read_html
#' @export
extract_date <- function(site) {
  # 1. Attempt to extract from JSON-LD
  json_ld_scripts <- rvest::html_nodes(site, xpath = "//script[@type='application/ld+json']")
  json_ld_content <- lapply(json_ld_scripts, function(script) {
    json_text <- rvest::html_text(script)
    tryCatch(
      jsonlite::fromJSON(json_text, flatten = TRUE),
      error = function(e) NULL  # Return NULL if JSON is malformed
    )
  })

  for (json_data in json_ld_content) {
    if (!is.null(json_data)) {
      possible_dates <- json_data[grepl("date", names(json_data), ignore.case = TRUE)]
      if (length(possible_dates) > 0) {
        standardized_date <- standardize_date(possible_dates[[1]])
        return(data.frame(date = standardized_date, source = "JSON-LD", stringsAsFactors = FALSE))
      }
    }
  }

  # 2. Attempt to extract from OpenGraph meta tags
  og_tags <- rvest::html_nodes(site, xpath = "//meta[@property]")
  og_dates <- rvest::html_attr(og_tags, "content")
  og_props <- rvest::html_attr(og_tags, "property")
  date_og <- og_dates[grepl("article:published_time|article:modified_time", og_props, ignore.case = TRUE)]
  if (length(date_og) > 0) {
    standardized_date <- standardize_date(date_og[1])
    return(data.frame(date = standardized_date, source = "OpenGraph meta tag", stringsAsFactors = FALSE))
  }

  # 3. Attempt to extract from standard meta tags
  meta_tags <- rvest::html_nodes(site, "meta")
  meta_dates <- rvest::html_attr(meta_tags, "content")
  meta_names <- rvest::html_attr(meta_tags, "name")
  date_meta <- meta_dates[grepl("date", meta_names, ignore.case = TRUE)]
  if (length(date_meta) > 0) {
    standardized_date <- standardize_date(date_meta[1])
    return(data.frame(date = standardized_date, source = "Standard meta tag", stringsAsFactors = FALSE))
  }

  # 4. Attempt to extract from URL (common patterns like /YYYY/MM/DD/)
  url_date <- regmatches(site$url, regexpr("\\d{4}/\\d{2}/\\d{2}", site$url))
  if (length(url_date) > 0) {
    standardized_date <- standardize_date(gsub("/", "-", url_date))
    return(data.frame(date = standardized_date, source = "URL", stringsAsFactors = FALSE))
  }

  # 5. Attempt to extract from specific HTML elements (e.g., <time>, <span>, <div>)
  date_nodes <- rvest::html_nodes(site, xpath = "//time | //span | //div")
  date_text <- rvest::html_text(date_nodes)
  date_text_matches <- regmatches(date_text, gregexpr("\\d{4}-\\d{2}-\\d{2}", date_text))

  if (length(date_text_matches) > 0 && length(date_text_matches[[1]]) > 0) {
    standardized_date <- standardize_date(date_text_matches[[1]][1])
    return(data.frame(date = standardized_date, source = "HTML element", stringsAsFactors = FALSE))
  }

  # Return NA if no date was found
  return(data.frame(date = NA_character_, source = NA_character_, stringsAsFactors = FALSE))
}





