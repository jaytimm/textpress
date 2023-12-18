
#' Article Extraction Utility
#'
#' This internal function extracts articles based on given URLs.
#' It's used within the package for processing news data.
#'
#' @param x A character vector of URLs.
#' @return A data.table of combined article data.
#' @importFrom data.table setDT
#' @noRd

util.article_extract <- function (x) {

  articles <- lapply(x, function(q) {
    raw_site <- util.get_site(q)
    annotated_site <- util.annotate_site(site = raw_site)
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
util.get_site <- function(x) {
  # Attempt to read the HTML content from the URL
  site <- tryCatch(
    xml2::read_html(httr::GET(x, httr::timeout(60))),
    error = function(e) "Error"
  )

  # Initialize default values for type and text as NA
  w1 <- w2 <- NA

  # Check if site reading was successful
  if (site != 'Error') {
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
util.annotate_site <- function(site) {

  junk1 <- paste0(quicknews:::junk_phrases, collapse = '|')
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



#' Build RSS URL for Google News
#'
#' Constructs an RSS URL for Google News based on the provided search query.
#' If no query is provided, returns the URL for the top news.
#'
#' @param x Optional search query as a character string.
#' @return A character string containing the RSS URL.
#' @importFrom stringr str_split
#' @noRd
#'
util.build_rss <- function(x = NULL) {

  clang_suffix <- 'hl=en-US&gl=US&ceid=US:en&q='
  base <- "https://news.google.com/news/rss/search?"
  tops <- "https://news.google.com/news/rss/?ned=us&hl=en&gl=us"

  if(is.null(x)) rss <- tops else {

    x <- strsplit(x, ' AND ')[[1]]
    y <- unlist(lapply(x, function(q) gsub(' ', '%20', q)))
    y1 <- lapply(y, function(q) gsub('(^.*$)', '%22\\1%22', q))
    search1 <- paste(y1, collapse = "%20AND%20")
    rss <- paste0(base, clang_suffix, search1)
  }

  return(rss)
}




#' Extract URLs from Google News RSS
#'
#' Fetches and parses the HTML content of Google News RSS feed
#' to extract the news article URLs.
#'
#' @param x A character vector of RSS feed URLs.
#' @return A character vector of extracted article URLs.
#' @importFrom xml2 read_html
#' @importFrom httr GET timeout
#' @noRd
#'
util.get_urls <- function(x){

  lapply(x, function(q){

    site <- tryCatch(
      xml2::read_html(httr::GET(q, httr::timeout(60))),
      error = function(e) 'no')

    if(length(site) == 1){NA}else{

      linkto <- site |> xml2::xml_find_all("c-wiz") |> xml2::xml_text()
      gsub('Opening ', '', linkto)
      #linkto |> unname()
    }
  }) |> unlist()
}




#' Parse RSS Feed
#'
#' Parses an RSS feed and extracts relevant information such as titles,
#' links, publication dates, and sources.
#'
#' @param x A character string of the RSS feed URL.
#' @return A data frame with columns for date, source, title, and link.
#' @importFrom xml2 read_xml xml_text xml_find_all
#' @noRd
#'
util.parse_rss <- function(x){

  doc <- tryCatch(
    xml2::read_xml(x),
    error = function(e) paste("Error")
  )

  ## records <- xml2::xml_find_all(doc, "//")

  if(any(doc == 'Error')) {return(NA)} else{
    title1 <- xml2::xml_text(xml2::xml_find_all(doc,"//item/title"))
    title <- gsub(' - .*$', '', title1)
    link <- xml2::xml_text(xml2::xml_find_all(doc,"//item/link"))
    pubDate <- xml2::xml_text(xml2::xml_find_all(doc,"//item/pubDate"))

    source1 <- sub('^.* - ', '', title1)
    source2 <- xml2::xml_text(xml2::xml_find_all(doc,"//channel/title"))
    if(grepl('Google News', source2)) {source <- source1} else{
      source <- source2}

    date <- gsub("^.+, ","",pubDate)
    date <- gsub(" [0-9]*:.+$","", date)
    date <- as.Date(date, "%d %b %Y")

    data.frame(date, source, title, link)
  }
}
