#' Extract external citation URLs from a Wikipedia article page
#'
#' Used by \code{\link{fetch_wiki_refs}}. Retrieves external URLs from the
#' References section of a Wikipedia article.
#'
#' @param url Full Wikipedia article URL.
#' @return A data.table with \code{ref_id} and \code{citation} (URL).
#' @noRd
.extract_wiki_references <- function(url) {
  page <- xml2::read_html(url)

  refs <- rvest::html_nodes(page, "li[id^='cite_note']")
  if (!length(refs)) {
    return(data.table::data.table(ref_id = character(), citation = character()))
  }

  out <- lapply(refs, function(ref) {
    ref_id <- xml2::xml_attr(ref, "id")

    urls <- rvest::html_attr(
      rvest::html_nodes(ref, xpath = ".//a[starts-with(@href, 'http')]"),
      "href"
    )
    urls <- unique(urls[urls != ""])

    if (!length(urls)) return(NULL)

    arc <- urls[grepl("web\\.archive\\.org", urls)]
    chosen <- if (length(arc)) arc[1] else urls[1]

    list(ref_id = ref_id, citation = chosen)
  })

  data.table::rbindlist(Filter(Negate(is.null), out), fill = TRUE)
}


#' Fetch external citation URLs from Wikipedia
#'
#' Searches Wikipedia for a topic, then returns external citation URLs from
#' the first matching page's references section. Use \code{\link{read_urls}}
#' to scrape content from those URLs.
#'
#' @param query Search phrase (e.g. "January 6 Capitol attack").
#' @param n Number of citation URLs to return (default 10).
#' @return A character vector of external citation URLs (prefers archived when present).
#' @export
#' @examples
#' \dontrun{
#' ref_urls <- fetch_wiki_refs("January 6 Capitol attack", n = 10)
#' articles <- read_urls(ref_urls)
#' }
fetch_wiki_refs <- function(query, n = 10) {
  pages <- fetch_wiki_urls(query, limit = 10)

  if (length(pages) == 0) {
    warning("No Wikipedia pages found for query: ", query)
    return(character())
  }

  refs <- .extract_wiki_references(pages[1])

  if (nrow(refs) == 0) {
    warning("No external citations found in Wikipedia page: ", pages[1])
    return(character())
  }

  urls <- refs$citation
  head(urls, n)
}


#' Fetch Wikipedia page URLs by search query
#'
#' Uses the MediaWiki API to get Wikipedia article URLs matching a keyword.
#' Does not search your local corpus; it retrieves links from Wikipedia.
#' Use \code{\link{read_urls}} to get article content from these URLs.
#'
#' @param query Search phrase (e.g. "117th Congress").
#' @param limit Number of page URLs to return (default 10).
#' @return A character vector of full Wikipedia article URLs.
#' @export
#' @examples
#' \dontrun{
#' wiki_urls <- fetch_wiki_urls("January 6 Capitol attack")
#' corpus <- read_urls(wiki_urls[1])
#' }
fetch_wiki_urls <- function(query, limit = 10) {
  base_url <- "https://en.wikipedia.org/w/api.php"

  res <- httr::GET(url = base_url, query = list(
    action   = "query",
    list     = "search",
    srsearch = query,
    srlimit  = limit,
    format   = "json",
    utf8     = 1
  ))

  if (httr::status_code(res) != 200L) {
    warning("Wikipedia API request failed.")
    return(character())
  }

  json <- httr::content(res, as = "parsed", encoding = "UTF-8")
  titles <- vapply(json$query$search, function(x) x$title, character(1L))
  paste0("https://en.wikipedia.org/wiki/", gsub(" ", "_", titles))
}
