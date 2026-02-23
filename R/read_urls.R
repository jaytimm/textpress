#' Read content from URLs
#'
#' Input: character vector of URLs. Output: structured data frame (one row per
#' node: headings, paragraphs, lists). Like \code{read_csv} or \code{read_html}:
#' bring an external resource into R. Follows \code{\link{fetch_urls}} or
#' \code{\link{fetch_wiki_urls}} in the pipeline—fetch gets locations, read gets
#' text. Wikipedia uses high-fidelity selectors; use \code{parent_heading} to see
#' which section each node belongs to. External links and empty text rows are
#' omitted; optionally exclude References/See also/Bibliography/Sources sections for
#' wiki URLs.
#'
#' @param x Character vector of URLs.
#' @param cores Number of cores for parallel requests (default 1).
#' @param detect_boilerplate Logical. Detect boilerplate (e.g. sign-up, related links).
#' @param remove_boilerplate Logical. If \code{detect_boilerplate} is \code{TRUE}, remove boilerplate rows; if \code{FALSE}, keep them and add \code{is_boilerplate}.
#' @param exclude_wiki_refs Logical. For Wikipedia URLs only, drop nodes whose \code{parent_heading} is References, See also, Bibliography, or Sources. Default \code{TRUE}.
#'
#' @return Data frame with \code{url}, \code{h1_title}, \code{date}, \code{type}, \code{node_id}, \code{parent_heading}, \code{text}, and optionally \code{is_boilerplate}.
#' @export
#' @examples
#' \dontrun{
#' urls <- fetch_urls("R programming", n_pages = 1)$url
#' nodes <- read_urls(urls[1:3], cores = 1)
#' }
read_urls <- function(x,
                     cores = 1,
                     detect_boilerplate = TRUE,
                     remove_boilerplate = TRUE,
                     exclude_wiki_refs = TRUE) {
  mm1 <- data.frame(url = x)
  batches <- split(mm1$url, ceiling(seq_along(mm1$url) / 20))

  if (cores == 1) {
    results <- lapply(
      X = batches,
      FUN = function(batch) .article_extract(batch, detect_boilerplate = detect_boilerplate, remove_boilerplate = remove_boilerplate, exclude_wiki_refs = exclude_wiki_refs)
    )
  } else {
    clust <- parallel::makeCluster(cores)
    parallel::clusterExport(
      cl = clust,
      varlist = c(".article_extract", ".detect_boilerplate", ".get_site", ".extract_date", ".standardize_date", ".junk_phrases", ".cta_words"),
      envir = environment()
    )
    results <- pbapply::pblapply(
      X = batches,
      FUN = function(batch) .article_extract(batch, detect_boilerplate = detect_boilerplate, remove_boilerplate = remove_boilerplate, exclude_wiki_refs = exclude_wiki_refs),
      cl = clust
    )
    parallel::stopCluster(clust)
  }

  data.table::rbindlist(results)
}


#' Article Extraction Utility
#'
#' Extracts articles from URLs. Used internally by \code{\link{read_urls}}.
#'
#' @param x Character vector of URLs.
#' @param detect_boilerplate,remove_boilerplate Logical. See \code{\link{read_urls}}.
#' @param exclude_wiki_refs Logical. See \code{\link{read_urls}}.
#' @return A data.table with article content (one row per node; \code{parent_heading} for section).
#' @importFrom stats na.omit
#' @noRd
.article_extract <- function(x,
                             detect_boilerplate = TRUE,
                             remove_boilerplate = TRUE,
                             exclude_wiki_refs = TRUE) {
  wiki_ref_headings <- c("References", "See also", "Bibliography", "Sources")
  articles <- lapply(x, function(q) {
    raw_site <- .get_site(q)
    is_wiki <- grepl("wikipedia\\.org", q, ignore.case = TRUE)
    annotated_site <- .detect_boilerplate(site = raw_site,
                                          detect_boilerplate = detect_boilerplate && !is_wiki)

    if (remove_boilerplate || !detect_boilerplate) {
      clean_site <- annotated_site[discard == "keep"]
      if (detect_boilerplate && !is_wiki) clean_site[, is_boilerplate := FALSE]
    } else {
      clean_site <- annotated_site[not_pnode == 0L]
      clean_site[, is_boilerplate := (discard != "keep")]
    }

    if (is_wiki) {
      clean_site <- clean_site[!(parent_heading == "External links" | (type %in% c("h2", "h3", "h4") & text == "External links"))]
      if (exclude_wiki_refs) {
        clean_site <- clean_site[is.na(parent_heading) | !(parent_heading %in% wiki_ref_headings)]
      }
    }
    clean_site <- clean_site[nzchar(stringr::str_trim(text))]
    clean_site[, node_id := seq_len(.N), by = .(url)]

    keep_boilerplate_col <- detect_boilerplate && !is_wiki
    if (keep_boilerplate_col && is_wiki) clean_site[, is_boilerplate := NA]
    base_cols <- if (is_wiki) c("url", "h1_title", "node_id", "parent_heading", "text") else c("url", "h1_title", "date", "type", "node_id", "parent_heading", "text")
    cols <- if (keep_boilerplate_col) c(base_cols, "is_boilerplate") else base_cols

    clean_site[, ..cols]
  })
  data.table::rbindlist(articles)
}


#' Get Site Content and Extract HTML Elements
#' Wikipedia: uses div.mw-parser-output, h2/h3/h4/p/ul, and cleans [edit].
#' @noRd
#' @importFrom httr GET timeout
#' @importFrom xml2 read_html
#' @importFrom rvest html_nodes html_node html_text html_name
.get_site <- function(x) {
  site <- tryCatch(
    xml2::read_html(httr::GET(x, httr::timeout(60))),
    error = function(e) "Error"
  )

  w1 <- w2 <- NA
  date_info <- data.frame(date = NA_character_, source = NA_character_)

  if (!any(site == "Error")) {
    is_wiki <- grepl("wikipedia\\.org", x, ignore.case = TRUE)

    if (is_wiki) {
      main_content <- rvest::html_node(site, "div.mw-parser-output")
      if (length(main_content) != 0L && !is.na(main_content)) {
        nodes <- rvest::html_nodes(main_content, "h2, h3, h4, p, ul")
        if (length(nodes) != 0L) {
          w1 <- rvest::html_name(nodes)
          w2 <- rvest::html_text(nodes, trim = TRUE)
          w2 <- gsub("\\[edit\\]$", "", w2)
          if (any(!validUTF8(w2))) { w1 <- w2 <- NA } else {
            title <- rvest::html_text(rvest::html_node(site, "h1, #firstHeading"), trim = TRUE)
            if (length(title) == 0L || !nzchar(title)) title <- NA_character_
            w1 <- c("h1", w1)
            w2 <- c(title, w2)
          }
        }
      }
      if (identical(w1, NA)) {
        is_wiki <- FALSE
      }
    }

    if (!is_wiki) {
      ntype1 <- "p,h1,h2,h3"
      w0 <- rvest::html_nodes(site, ntype1)
      if (length(w0) != 0) {
        w1 <- rvest::html_name(w0)
        w2 <- rvest::html_text(w0, trim = TRUE)
        if (any(!validUTF8(w2))) w1 <- w2 <- NA
      }
    }

    date_info <- .extract_date(site, url = x)
  }

  return(data.frame(
    url = x,
    type = w1,
    text = w2,
    date = date_info$date,
    date_source = date_info$source
  ))
}


#' Detect Boilerplate in Scraped Site Data
#' @noRd
#' @importFrom data.table setDT fifelse last
#' @importFrom stringr str_trim
.detect_boilerplate <- function(site, detect_boilerplate = TRUE) {

  data.table::setDT(site)
  site[, text := stringr::str_trim(text)]

  site[, h1_title := ifelse(type == "h1", text, NA)]
  site[, h1_title := data.table::last(na.omit(h1_title)), by = .(url)]

  site[, heading_text := data.table::fifelse(type %in% c("h1", "h2", "h3", "h4"), text, NA_character_)]
  site[, parent_heading := {
    ht <- .SD$heading_text
    last <- NA_character_
    out <- rep(NA_character_, length(ht))
    for (i in seq_along(ht)) {
      if (!is.na(ht[i])) last <- ht[i]
      out[i] <- if (!is.na(ht[i])) NA_character_ else last
    }
    out
  }, by = .(url), .SDcols = "heading_text"]
  site[, heading_text := NULL]

  site[, not_pnode := data.table::fifelse(type %in% c("p", "h1", "h2", "h3", "h4", "ul"), 0L, 1L)]

  if (!detect_boilerplate) {
    site[, discard := data.table::fifelse(not_pnode == 1L, "junk", "keep")]
    return(site)
  }

  junk_pattern <- paste0(.junk_phrases, collapse = "|")
  cta_pattern <- paste0("\\b(", paste0(.cta_words, collapse = "|"), ")\\b")
  you_pattern <- "\\b(you(['']\\w+)?|your)\\b"
  quote_pattern <- "[\"\u201c\u201d]"

  site[, has_junk := data.table::fifelse(grepl(junk_pattern, text, ignore.case = TRUE), 1L, 0L)]
  site[, has_ellipses := data.table::fifelse(grepl("\\.\\.\\.(.)?$", text), 1L, 0L)]
  site[, no_stop := data.table::fifelse(grepl("(\\.|\\!|\\?)(.)?$", gsub("\"|'", "", text)), 0L, 1L)]
  site[, less_10 := data.table::fifelse(nchar(text) > 10, 0L, 1L)]
  site[, has_you := data.table::fifelse(grepl(you_pattern, text, ignore.case = TRUE), 1L, 0L)]
  site[, has_quote := data.table::fifelse(grepl(quote_pattern, text), 1L, 0L)]
  site[, has_qmark := data.table::fifelse(grepl("\\?", text), 1L, 0L)]
  site[, has_exclam := data.table::fifelse(grepl("!", text), 1L, 0L)]
  site[, has_cta := data.table::fifelse(grepl(cta_pattern, text, ignore.case = TRUE), 1L, 0L)]

  site[, drop_you_cta := data.table::fifelse(
    has_you == 1L & has_quote == 0L & has_qmark == 0L & has_cta == 1L,
    1L, 0L
  )]

  site[, drop_node_bang := data.table::fifelse(
    has_exclam == 1L & has_quote == 0L,
    1L, 0L
  )]

  site[, discard := rowSums(.SD[, .(not_pnode, has_ellipses, no_stop, less_10, has_junk, drop_you_cta, drop_node_bang)])]
  site[, discard := data.table::fifelse(discard > 0L, "junk", "keep")]

  return(site)
}


.junk_auth <- c(
  "^sign up\\b", "^sign in\\b", "^create an account\\b", "^please login\\b",
  "^login\\b", "^log in\\b", "^logged in\\b", "^already a subscriber\\b",
  "^forget password\\b", "^reset your password\\b"
)
.junk_subscription <- c(
  "^subscribe\\b", "^subscribe to\\b", "free subsc\\b", "share this!\\b", "^please purchase\\b"
)
.junk_forms <- c(
  "^enter your\\b", "your (email )?inbox\\b", "^your comment\\b", "^need help\\b"
)
.junk_navigation <- c(
  "^related (articles|stories)\\b", "^related news$", "^recommended for you\\b",
  "^most read\\b", "^popular (articles|stories)\\b", "^latest( .*)? news$",
  "^more( .*)? stories$", "^posts from\\b", "^check out\\b"
)
.junk_legal <- c(
  "^all rights reserved\\b", "\u00a9", "^privacy policy\\b", "^terms of (service|use)\\b",
  "^cookie (policy|preferences|settings)\\b"
)
.junk_commercial <- c(
  "^advertisement$", "^sponsored($|\\b)", "^paid content($|\\b)"
)
.cta_words <- c(
  "sign", "login", "log in", "subscribe", "register", "agree", "accept",
  "use", "click", "enter", "purchase", "support", "contact", "provide",
  "submit", "allow"
)
.junk_phrases <- c(.junk_auth, .junk_subscription, .junk_forms, .junk_navigation, .junk_legal, .junk_commercial)


#' @noRd
#' @importFrom lubridate ymd_hms ymd dmy mdy
.standardize_date <- function(date_str) {
  formats <- list(
    function(x) lubridate::ymd_hms(x, tz = "UTC"),
    function(x) lubridate::ymd(x),
    function(x) lubridate::dmy(x),
    function(x) lubridate::mdy(x)
  )

  for (fmt in formats) {
    parsed <- suppressWarnings(tryCatch(fmt(date_str), error = function(e) NA))
    if (length(parsed) > 1) {
      parsed <- parsed[!is.na(parsed)]
      if (length(parsed) == 0) next
      parsed <- parsed[1]
    }
    if (!any(is.na(parsed))) {
      return(format(parsed, "%Y-%m-%d"))
    }
  }

  return(NA)
}


#' @noRd
#' @importFrom rvest html_nodes html_text html_attr
#' @importFrom jsonlite fromJSON
.extract_date <- function(site, url = NULL) {
  json_ld_scripts <- rvest::html_nodes(site, xpath = "//script[@type='application/ld+json']")
  json_ld_content <- lapply(json_ld_scripts, function(script) {
    json_text <- rvest::html_text(script)
    tryCatch(
      jsonlite::fromJSON(json_text, flatten = TRUE),
      error = function(e) NULL
    )
  })

  for (json_data in json_ld_content) {
    if (!is.null(json_data)) {
      nms <- names(json_data)

      idx_pub <- grepl("^datePublished$", nms, ignore.case = TRUE)
      if (any(idx_pub)) {
        standardized_date <- .standardize_date(json_data[[which(idx_pub)[1]]])
        if (!is.na(standardized_date)) {
          return(data.frame(date = standardized_date, source = "JSON-LD", stringsAsFactors = FALSE))
        }
      }

      possible_dates <- json_data[grepl("date", nms, ignore.case = TRUE)]
      if (length(possible_dates) > 0) {
        standardized_date <- .standardize_date(possible_dates[[1]])
        if (!is.na(standardized_date)) {
          return(data.frame(date = standardized_date, source = "JSON-LD", stringsAsFactors = FALSE))
        }
      }
    }
  }

  og_tags <- rvest::html_nodes(site, xpath = "//meta[@property]")
  og_dates <- rvest::html_attr(og_tags, "content")
  og_props <- rvest::html_attr(og_tags, "property")

  date_og <- og_dates[
    grepl("article:published_time", og_props, ignore.case = TRUE) |
      grepl("article:modified_time", og_props, ignore.case = TRUE)
  ]

  if (length(date_og) > 0) {
    standardized_date <- .standardize_date(date_og[1])
    if (!is.na(standardized_date)) {
      return(data.frame(date = standardized_date, source = "OpenGraph meta tag", stringsAsFactors = FALSE))
    }
  }

  meta_tags <- rvest::html_nodes(site, "meta")
  meta_dates <- rvest::html_attr(meta_tags, "content")
  meta_names <- rvest::html_attr(meta_tags, "name")
  date_meta <- meta_dates[grepl("date", meta_names, ignore.case = TRUE)]
  if (length(date_meta) > 0) {
    standardized_date <- .standardize_date(date_meta[1])
    if (!is.na(standardized_date)) {
      return(data.frame(date = standardized_date, source = "Standard meta tag", stringsAsFactors = FALSE))
    }
  }

  if (!is.null(url)) {
    url_date <- regmatches(url, regexpr("\\d{4}[-/]\\d{2}[-/]\\d{2}", url))
    if (length(url_date) > 0 && nzchar(url_date)) {
      standardized_date <- .standardize_date(gsub("/", "-", url_date))
      if (!is.na(standardized_date)) {
        return(data.frame(date = standardized_date, source = "URL", stringsAsFactors = FALSE))
      }
    }
  }

  data.frame(date = NA_character_, source = NA_character_, stringsAsFactors = FALSE)
}
