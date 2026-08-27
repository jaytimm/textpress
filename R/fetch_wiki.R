#' Extract external citation URLs from a Wikipedia article page
#'
#' Used by \code{\link{fetch_wiki_refs}}. Retrieves external URLs from the
#' References section of a Wikipedia article.
#'
#' @param url Full Wikipedia article URL.
#' @return A data.table with \code{ref_id} and \code{citation} (URL).
#' @noRd
.extract_wiki_references <- function(url) {
  page <- xml2::read_html(httr::GET(url, httr::user_agent(.tp_user_agent)))

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


#' Fetch external citation URLs from Wikipedia article(s)
#'
#' Wikipedia. Extracts external citation URLs from the References section of one
#' or more Wikipedia article URLs. Use \code{\link{read_urls}} to scrape content
#' from those URLs.
#'
#' @param url Character vector of full Wikipedia article URLs (e.g. from \code{\link{fetch_wiki_urls}}).
#' @param n Maximum number of citation URLs to return per source page. Default \code{NULL} returns all; use a number (e.g. \code{10}) to limit.
#' @return A \code{data.table} with columns \code{source_url}, \code{ref_id}, and \code{ref_url}, one row per citation across all input URLs. Use \code{split(x, x$source_url)} to group by article.
#' @export
#' @examples
#' \dontrun{
#' wiki_urls <- fetch_wiki_urls("January 6 Capitol attack")
#' refs_dt <- fetch_wiki_refs(wiki_urls)
#' articles <- read_urls(refs_dt$ref_url)
#' }
fetch_wiki_refs <- function(url, n = NULL) {
  url <- unique(url)
  empty_dt <- data.table::data.table(source_url = character(), ref_id = character(), ref_url = character())
  if (!length(url)) {
    return(empty_dt)
  }

  take_all <- is.null(n) || is.infinite(n)

  out <- lapply(url, function(u) {
    refs <- .extract_wiki_references(u)
    if (nrow(refs) == 0) {
      return(NULL)
    }
    if (!take_all) refs <- refs[seq_len(min(n, nrow(refs)))]
    refs[, source_url := u]
    refs[, ref_url := citation][, citation := NULL]
    refs
  })
  out <- Filter(Negate(is.null), out)

  if (!length(out)) {
    warning("No external citations found in the given Wikipedia page(s).")
    return(empty_dt)
  }

  data.table::rbindlist(out, fill = TRUE)[, .(source_url, ref_id, ref_url)]
}


#' Fetch Wikipedia page URLs by search query
#'
#' Wikipedia. Uses the MediaWiki API to get Wikipedia article URLs matching a
#' search phrase. Does not search your local corpus. Use \code{\link{read_urls}}
#' to get article content from these URLs.
#'
#' @param query Search phrase (e.g. "117th Congress").
#' @param limit Number of page URLs to return (default 10).
#' @return Character vector of full Wikipedia article URLs.
#' @export
#' @examples
#' \dontrun{
#' wiki_urls <- fetch_wiki_urls("January 6 Capitol attack")
#' corpus <- read_urls(wiki_urls[1])
#' }
fetch_wiki_urls <- function(query, limit = 10) {
  base_url <- "https://en.wikipedia.org/w/api.php"

  res <- httr::GET(
    url = base_url,
    query = list(
      action   = "query",
      list     = "search",
      srsearch = query,
      srlimit  = limit,
      format   = "json",
      utf8     = 1
    ),
    httr::user_agent(.tp_user_agent)
  )

  if (httr::status_code(res) != 200L) {
    warning("Wikipedia API request failed.")
    return(character())
  }

  json <- httr::content(res, as = "parsed", encoding = "UTF-8")
  titles <- vapply(json$query$search, function(x) x$title, character(1L))
  paste0("https://en.wikipedia.org/wiki/", gsub(" ", "_", titles))
}
