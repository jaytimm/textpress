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
.build_rss <- function(x = NULL) {

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
.get_urls <- function(x){

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
.parse_rss <- function(x){

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
