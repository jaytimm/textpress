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

  # Define the suffix and base URL for constructing the RSS feed URL
  clang_suffix <- 'hl=en-US&gl=US&ceid=US:en&q='
  base <- "https://news.google.com/news/rss/search?"
  tops <- "https://news.google.com/news/rss/?ned=us&hl=en&gl=us"

  # If 'x' is NULL, use the default top stories RSS feed
  if(is.null(x)) {
    rss <- tops
  } else {
    # If 'x' is not NULL, process the search query

    # Split the search query 'x' on ' AND ' and extract the first element
    x <- strsplit(x, ' AND ')[[1]]

    # Replace spaces in each search term with '%20' for URL encoding
    y <- unlist(lapply(x, function(q) gsub(' ', '%20', q)))

    # Enclose each term in quotes and URL encode it
    y1 <- lapply(y, function(q) gsub('(^.*$)', '%22\\1%22', q))

    # Join the encoded search terms with '%20AND%20'
    search1 <- paste(y1, collapse = "%20AND%20")

    # Construct the final RSS feed URL
    rss <- paste0(base, clang_suffix, search1)
  }

  # Return the constructed RSS feed URL
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

  # Use 'lapply' to apply a function to each element in 'x'
  lapply(x, function(q){

    # Try to read the HTML content of the URL 'q' with a 60-second timeout
    site <- tryCatch(
      xml2::read_html(httr::GET(q, httr::timeout(60))),
      error = function(e) 'no')

    # Check if the site was successfully read
    if(length(site) == 1) {
      # If not, return NA
      NA
    } else {
      # If the site was read successfully, find all elements with the tag 'c-wiz'
      linkto <- site |> xml2::xml_find_all("c-wiz") |> xml2::xml_text()

      # Remove the prefix 'Opening ' from the text of these elements
      gsub('Opening ', '', linkto)
      # Return the modified text (URLs), but without names
      #linkto |> unname()
    }
  }) |> unlist() # Unlist to convert the list to a vector
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

  # Attempt to read the XML content from the input 'x'
  doc <- tryCatch(
    xml2::read_xml(x),
    error = function(e) paste("Error")
  )

  # Check if an error occurred during XML reading
  if(any(doc == 'Error')) {
    # If there's an error, return NA
    return(NA)
  } else {
    # If the XML was successfully read, extract various elements

    # Extract the titles from the XML and remove any trailing content after ' - '
    title1 <- xml2::xml_text(xml2::xml_find_all(doc,"//item/title"))
    title <- gsub(' - .*$', '', title1)

    # Extract the links from the XML
    link <- xml2::xml_text(xml2::xml_find_all(doc,"//item/link"))

    # Extract the publication dates from the XML
    pubDate <- xml2::xml_text(xml2::xml_find_all(doc,"//item/pubDate"))

    # Extract the source of the news from the title or the channel title
    source1 <- sub('^.* - ', '', title1)
    source2 <- xml2::xml_text(xml2::xml_find_all(doc,"//channel/title"))
    if(grepl('Google News', source2)) {
      source <- source1
    } else {
      source <- source2
    }

    # Format the publication date
    date <- gsub("^.+, ","",pubDate)
    date <- gsub(" [0-9]*:.+$","", date)
    date <- as.Date(date, "%d %b %Y")

    # Combine the extracted data into a data frame
    data.frame(date, source, title, link)
  }
}
