# Fetch URLs from DuckDuckGo Lite (external query → links).
# Page 1 uses GET; pages 2+ use POST with offset + dc token.

#' Fetch URLs from a search engine
#'
#' Queries DuckDuckGo Lite and returns result URLs (no local text search).
#' Use \code{\link{read_urls}} to get content from these URLs.
#'
#' @param query Search query string.
#' @param n_pages Number of DDG Lite pages to fetch (default 1). ~30 results per page.
#' @param date_filter Recency filter: \code{"d"} (day), \code{"w"} (week), \code{"m"} (month), or \code{"none"} (default \code{"w"}).
#' @return A \code{data.table} with columns \code{search_engine}, \code{url}, \code{is_excluded}.
#' @importFrom httr GET POST timeout
#' @importFrom stringr str_detect
#' @export
#' @examples
#' \dontrun{
#' urls_dt <- fetch_urls("R programming nlp", n_pages = 1)
#' urls_dt$url
#' }
fetch_urls <- function(query, n_pages = 1, date_filter = "w") {
  date_filter <- match.arg(date_filter, choices = c("w", "d", "m", "none"))
  df_param    <- if (date_filter == "none") "" else date_filter

  results <- vector("list", n_pages)

  page1 <- .search_ddg_page1(query, df_param)
  results[[1]] <- page1$data

  if (n_pages > 1) {
    dc <- page1$dc
    for (i in seq(2, n_pages)) {
      Sys.sleep(runif(1, 2, 4))
      results[[i]] <- .search_ddg_page_n(query, page = i, dc = dc, df_param = df_param)
    }
  }

  data.table::rbindlist(results, fill = TRUE)
}


# ----------------------------
# SEARCH ENGINE FUNCTIONS
# ----------------------------

#' @noRd
.search_ddg_page1 <- function(query, df_param = "") {
  url <- paste0(
    "https://lite.duckduckgo.com/lite/?q=",
    utils::URLencode(query, reserved = TRUE),
    if (nzchar(df_param)) paste0("&df=", df_param) else ""
  )

  response <- httr::GET(
    url,
    httr::user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"),
    httr::add_headers(
      "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" = "en-US,en;q=0.9"
    ),
    httr::timeout(30)
  )

  status <- httr::status_code(response)
  if (status != 200) {
    warning(sprintf("DDG returned status %d (page 1)", status))
    return(list(
      data = .empty_dt(),
      dc   = ""
    ))
  }

  html <- xml2::read_html(httr::content(response, as = "text", encoding = "UTF-8"))

  dc <- tryCatch({
    node <- rvest::html_node(html, "input[name='dc']")
    rvest::html_attr(node, "value")
  }, error = function(e) "")
  if (is.na(dc) || is.null(dc)) dc <- ""

  list(
    data = .parse_ddg_html(html, page = 1),
    dc   = dc
  )
}


#' @noRd
.search_ddg_page_n <- function(query, page, dc, df_param = "") {
  offset <- (page - 1) * 30

  body <- list(
    q  = query,
    s  = as.character(offset),
    dc = dc,
    o  = "json",
    api= "d.js"
  )
  if (nzchar(df_param)) body$df <- df_param

  response <- httr::POST(
    "https://lite.duckduckgo.com/lite/",
    httr::user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"),
    httr::add_headers(
      "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" = "en-US,en;q=0.9",
      "Content-Type"    = "application/x-www-form-urlencoded",
      "Referer"         = "https://lite.duckduckgo.com/"
    ),
    body   = body,
    encode = "form",
    httr::timeout(30)
  )

  status <- httr::status_code(response)
  if (status != 200) {
    warning(sprintf("DDG returned status %d (page %d)", status, page))
    return(.empty_dt())
  }

  html <- xml2::read_html(httr::content(response, as = "text", encoding = "UTF-8"))
  .parse_ddg_html(html, page = page)
}


#' @noRd
.parse_ddg_html <- function(html, page) {
  hrefs <- rvest::html_attr(rvest::html_nodes(html, "a[href]"), "href")
  hrefs <- hrefs[!is.na(hrefs) & nzchar(hrefs)]

  links <- .decode_duckduckgo_urls(hrefs)
  links <- links[grepl("^https?://", links, ignore.case = TRUE)]

  filter_pattern <- .get_global_exclude_pattern()
  links <- links[!stringr::str_detect(links, filter_pattern)]
  links <- unique(links)

  if (length(links) == 0) {
    return(.empty_dt())
  }

  data.table::data.table(
    search_engine = paste0("duckduckgo_page", page),
    url           = links,
    is_excluded   = FALSE
  )
}


#' @noRd
.decode_duckduckgo_urls <- function(redirected_urls) {
  if (length(redirected_urls) == 0) return(character(0))

  final_urls <- vapply(redirected_urls, function(u) {
    encoded <- sub(".*uddg=([^&]*).*", "\\1", u)
    utils::URLdecode(encoded)
  }, character(1))

  final_urls[nzchar(final_urls)]
}


#' @noRd
.empty_dt <- function() {
  data.table::data.table(
    search_engine = character(),
    url           = character(),
    is_excluded   = logical()
  )
}


#' Get the search URL(s) used by fetch_urls (for debugging or browser use)
#'
#' Page 2+ require POST; only page 1 is a direct browser URL.
#'
#' @param query Search query string.
#' @param n_pages Number of pages (informational for page 2+).
#' @param date_filter Recency filter: \code{"d"}, \code{"w"}, \code{"m"}, or \code{"none"} (default \code{"w"}).
#' @return Named character vector of URLs.
#' @export
get_search_urls <- function(query, n_pages = 1, date_filter = "w") {
  date_filter <- match.arg(date_filter, choices = c("w", "d", "m", "none"))
  df_param    <- if (date_filter == "none") "" else date_filter

  base <- paste0(
    "https://lite.duckduckgo.com/lite/?q=",
    utils::URLencode(query, reserved = TRUE),
    if (nzchar(df_param)) paste0("&df=", df_param) else ""
  )

  setNames(
    c(base, rep("POST https://lite.duckduckgo.com/lite/ (s=30, s=60, ...)", max(0, n_pages - 1))),
    c("duckduckgo_page1", paste0("duckduckgo_page", seq_len(max(0, n_pages - 1)) + 1))
  )
}


#' @noRd
.get_global_exclude_pattern <- function() {
  social_domains <- c(
    "twitter", "facebook\\.com", "linkedin\\.com", "instagram\\.com",
    "tiktok\\.com", "reddit\\.com", "mastodon", "youtube\\.com",
    "wikipedia\\.org", "yahoo\\.com", "britannica\\.com", "bing\\.com"
  )
  redirect_domains <- c("go\\.microsoft\\.com", "bit\\.ly", "tinyurl\\.com")
  placeholders     <- c("/topic/", "/category/", "/help", "/support", "/docs")
  feedback_forums  <- c("yahoo\\.uservoice\\.com/forums/")

  paste(c(social_domains, redirect_domains, placeholders, feedback_forums), collapse = "|")
}
