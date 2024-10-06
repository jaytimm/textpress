#' Process search results from multiple search engines
#'
#' This function allows you to query different search engines (DuckDuckGo, Bing, Yahoo News),
#' retrieve search results, and filter them based on predefined patterns.
#'
#' @param search_term The search query as a string.
#' @param search_engine The search engine to use: "DuckDuckGo", "Bing", or "Yahoo News".
#' @param num_pages The number of result pages to retrieve (default: 1).
#' @param time_filter Optional time filter ("week", "month", "year").
#' @param insite Restrict search to a specific domain (not supported for Yahoo).
#' @param intitle Search within the title (relevant for DuckDuckGo and Bing).
#' @return A `data.table` containing search engine results with columns `search_engine` and `raw_url`.
#' @importFrom data.table data.table rbindlist
#' @importFrom utils URLencode URLdecode
#' @export
web_search <- function(search_term,
                       search_engine,
                       num_pages = 1,
                       time_filter = NULL,
                       insite = NULL,
                       intitle = FALSE) {

  # Define a list of common social and redirect domains to exclude across all engines
  social_domains <- c("twitter",
                      "facebook.com",
                      "linkedin.com",
                      "instagram.com",
                      "tiktok.com",
                      "reddit.com",
                      "mastodon",
                      "youtube.com",
                      "wikipedia.org",
                      "yahoo.com",
                      'britannica.com',
                      'bing.com')

  redirect_domains <- c("go.microsoft.com",
                        "bit.ly",
                        "tinyurl.com")

  placeholder_patterns <- c("/topic/",
                            "/category/",
                            "/help",
                            "/support",
                            "/docs")

  # Combine all patterns into one single string, separated by '|'
  combined_pattern <- paste(c(social_domains,
                              redirect_domains,
                              placeholder_patterns),
                            collapse = '|')

  # Switch to handle different search engines
  if (search_engine == "DuckDuckGo") {
    results <- .process_duckduckgo(search_term,
                                   num_pages,
                                   time_filter,
                                   insite,
                                   intitle,
                                   combined_pattern = combined_pattern)

  } else if (search_engine == "Bing") {
    results <- .process_bing(search_term,
                             num_pages,
                             time_filter,
                             insite,
                             intitle,
                             combined_pattern = combined_pattern)

  } else if (search_engine == "Yahoo News") {
    results <- .process_yahoo(search_term,
                              num_pages,
                              combined_pattern = combined_pattern)

  } else {
    stop("Unsupported search engine. Choose from 'DuckDuckGo', 'Bing', or 'Yahoo News'.")
  }

  return(results)
}




#' Process DuckDuckGo search results
#'
#' This function handles the extraction of search results from DuckDuckGo.
#'
#' @param search_term The search query.
#' @param num_pages Number of result pages to retrieve.
#' @param time_filter Optional time filter ("week", "month", "year").
#' @param insite Restrict search to a specific domain.
#' @param intitle Search within the title.
#' @param combined_pattern A pattern for filtering out irrelevant URLs.
#' @return A `data.table` of search results from DuckDuckGo.
#' @importFrom data.table data.table rbindlist
#' @importFrom utils URLencode
.process_duckduckgo <- function(search_term,
                                num_pages,
                                time_filter,
                                insite,
                                intitle,
                                combined_pattern) {

  # Base URL for DuckDuckGo search
  base_url <- "https://duckduckgo.com/html/?q="

  # Modify the search term based on the provided parameters
  if (!is.null(insite)) {
    search_term <- paste0(search_term, " site:", insite)
  }

  if (intitle) {
    search_term <- paste0("intitle:", search_term)
  }

  # Apply time filter
  time_param <- switch(time_filter,
                       week = "&df=w",
                       month = "&df=m",
                       year = "&df=y",
                       "")

  results <- data.table::data.table(search_engine = character(), raw_url = character())

  # Process DuckDuckGo
  for (page_num in 1:num_pages) {
    search_url <- paste0(base_url, utils::URLencode(search_term, reserved = TRUE),
                         "&s=", (page_num - 1) * 10, time_param)

    raw_links <- .extract_links(search_url)

    if (length(raw_links) > 0) {
      raw_links <- .decode_duckduckgo_urls(raw_links)
      raw_links <- raw_links[grepl('^https', raw_links)]  # Filter HTTPS
      raw_links <- raw_links[!stringr::str_detect(raw_links, combined_pattern)]  # Filter irrelevant URLs

      if (length(raw_links) > 0) {
        engine_results <- data.table::data.table(
          search_engine = rep("DuckDuckGo", length(raw_links)),
          raw_url = raw_links
        )
        results <- data.table::rbindlist(list(results, engine_results), use.names = TRUE, fill = TRUE)
      }
    }

    Sys.sleep(1.2)
  }

  # Remove duplicate URLs based on the 'raw_url' column
  results <- unique(results, by = "raw_url")

  return(results)
}



#' Decode DuckDuckGo Redirect URLs
#'
#' This function decodes the DuckDuckGo search result URLs that are redirected.
#'
#' @param redirected_urls A vector of DuckDuckGo search result URLs.
#' @return A vector of decoded URLs.
#' @importFrom utils URLdecode
#' @export
.decode_duckduckgo_urls <- function(redirected_urls) {
  final_urls <- vector("character", length(redirected_urls))
  for (i in seq_along(redirected_urls)) {
    encoded_url <- sub(".*uddg=([^&]*).*", "\\1", redirected_urls[i])
    final_urls[i] <- utils::URLdecode(encoded_url)
  }
  return(final_urls)
}




#' Process Bing search results
#'
#' This function retrieves and processes search results from Bing.
#'
#' @param search_term The search query.
#' @param num_pages Number of result pages to retrieve.
#' @param time_filter Optional time filter ("week", "month", "year").
#' @param insite Restrict search to a specific domain.
#' @param intitle Search within the title.
#' @param combined_pattern A pattern for filtering out irrelevant URLs.
#' @return A `data.table` of search results from Bing.
#' @importFrom data.table data.table rbindlist
#' @importFrom utils URLencode
#' @importFrom stringr str_detect
#' @export
.process_bing <- function(search_term,
                          num_pages,
                          time_filter,
                          insite,
                          intitle,
                          combined_pattern) {

  base_url <- "https://www.bing.com/search?q="

  # Modify search term
  if (!is.null(insite)) search_term <- paste0(search_term, " site:", insite)
  if (intitle) search_term <- paste0("intitle:", search_term)

  # Time filter
  time_param <- switch(time_filter,
                       week = "&filters=ex1%3a%22ez1%22",
                       month = "&filters=ex1%3a%22ez2%22",
                       year = "&filters=ex1%3a%22ez3%22",
                       "")

  results <- data.table::data.table(search_engine = character(), raw_url = character())

  for (page_num in 1:num_pages) {
    search_url <- paste0(base_url, utils::URLencode(search_term, reserved = TRUE), "&first=", (page_num - 1) * 10 + 1, time_param)
    raw_links <- .extract_links(search_url)

    if (length(raw_links) > 0) {
      raw_links <- raw_links[grepl('^https', raw_links)]  # Filter HTTPS
      raw_links <- raw_links[!stringr::str_detect(raw_links, combined_pattern)]  # Filter irrelevant URLs

      if (length(raw_links) > 0) {
        engine_results <- data.table::data.table(search_engine = rep("Bing", length(raw_links)), raw_url = raw_links)
        results <- data.table::rbindlist(list(results, engine_results), use.names = TRUE, fill = TRUE)
      }
    }

    Sys.sleep(1.35)
  }
  return(unique(results, by = "raw_url"))
}






#' Process Yahoo News search results
#'
#' This function retrieves and processes search results from Yahoo News,
#' automatically sorting by the most recent articles.
#'
#' @param search_term The search query.
#' @param num_pages Number of result pages to retrieve.
#' @param combined_pattern A pattern for filtering out irrelevant URLs.
#' @return A `data.table` of search results from Yahoo News.
#' @importFrom data.table data.table rbindlist
#' @importFrom utils URLencode
#' @importFrom stringr str_detect
#' @export
.process_yahoo <- function(search_term,
                           num_pages,
                           combined_pattern = combined_pattern) {

  # Base URL for Yahoo News search, ensuring results are sorted by the most recent
  base_url <- "https://news.search.yahoo.com/search"

  results <- data.table::data.table(search_engine = character(), raw_url = character())

  for (page_num in 1:num_pages) {
    # Construct search URL with the correct parameters, including sort by time
    search_url <- paste0(base_url, "?p=", utils::URLencode(search_term, reserved = TRUE),
                         "&b=", (page_num - 1) * 10 + 1, "&sort=time")

    raw_links <- .extract_links(search_url)

    if (length(raw_links) > 0) {
      raw_links <- raw_links[grepl('^https', raw_links)]  # Filter HTTPS
      raw_links <- raw_links[!stringr::str_detect(raw_links, combined_pattern)]  # Filter irrelevant URLs

      if (length(raw_links) > 0) {
        engine_results <- data.table::data.table(search_engine = rep("Yahoo News", length(raw_links)), raw_url = raw_links)
        results <- data.table::rbindlist(list(results, engine_results), use.names = TRUE, fill = TRUE)
      }
    }

    Sys.sleep(1.25)
  }

  return(unique(results, by = "raw_url"))
}



#' Extract links from a search engine result page
#'
#' This function extracts all the links (href attributes) from a search engine result page.
#'
#' @param search_url The URL of the search engine result page.
#' @return A character vector of URLs.
#' @importFrom xml2 read_html
#' @importFrom rvest html_nodes html_attr
#' @export
.extract_links <- function(search_url) {
  webpage <- try(xml2::read_html(search_url), silent = TRUE)
  if (inherits(webpage, "try-error")) {
    warning("Failed to open URL: ", search_url)
    return(character(0))
  }
  links <- rvest::html_nodes(webpage, "a")
  hrefs <- rvest::html_attr(links, "href")
  return(hrefs)
}
