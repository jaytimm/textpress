#' Fetch recent articles from RSS and Atom feeds
#'
#' Fetches RSS or Atom feeds and returns one row per article entry. The result
#' includes feed and article metadata and can be passed directly to
#' \code{\link{read_urls}} through its \code{url} column.
#'
#' @param feed_url Character vector of RSS or Atom feed URLs.
#' @param cores Number of cores for parallel feed requests (default 1).
#' @return A data.table with common discovery columns \code{doc_id},
#'   \code{url}, \code{title}, \code{published_at}, \code{source},
#'   \code{language}, and \code{country}, followed by RSS-specific feed and
#'   article metadata.
#' @export
#' @examples
#' \dontrun{
#' feeds <- subset(rss_politics, category == "polling")
#' items <- fetch_rss(feeds$url, cores = 4)
#' corpus <- read_urls(items)
#' }
fetch_rss <- function(feed_url, cores = 1) {
  rss_finalize_items(rss_items(feed_url, cores = cores))
}

# A dead feed should not stall a batch. This is deliberately transport
# plumbing rather than part of the public fetch_rss() interface.
.rss_timeout_seconds <- 15

#' @noRd
rss_finalize_items <- function(items) {
  items <- data.table::copy(items)
  if (!"source" %in% names(items)) {
    items[, source := sub("^https?://([^/]+).*", "\\1", url)]
  }
  if (!"language" %in% names(items)) {
    items[, language := NA_character_]
  }
  if (!"country" %in% names(items)) {
    items[, country := NA_character_]
  }
  items[, doc_id := seq_len(.N)]
  data.table::setcolorder(
    items,
    c(
      "doc_id", "url", "title", "published_at", "source", "language",
      "country", setdiff(
        names(items),
        c("doc_id", "url", "title", "published_at", "source", "language", "country")
      )
    )
  )
  items[]
}

#' @noRd
rss_items <- function(feed_url, cores = 1) {
  if (!is.character(feed_url)) {
    stop("`feed_url` must be a character vector.", call. = FALSE)
  }

  feed_url <- unique(trimws(feed_url[!is.na(feed_url)]))
  feed_url <- feed_url[nzchar(feed_url)]
  if (!length(feed_url)) {
    return(rss_empty_items())
  }

  fetch_one <- function(url) {
    tryCatch({
      response <- httr::GET(
        url,
        httr::timeout(.rss_timeout_seconds),
        httr::user_agent(.tp_user_agent)
      )
      httr::stop_for_status(response)

      payload <- httr::content(response, as = "raw")
      document <- rss_document(payload)
      entries <- xml2::xml_find_all(
        document,
        "//*[local-name()='item' or local-name()='entry']"
      )
      if (!length(entries)) {
        warning(
          sprintf("RSS feed <%s> contains no item or entry elements.", url),
          call. = FALSE
        )
        return(rss_empty_items())
      }

      feed_title <- xml2::xml_text(xml2::xml_find_first(
        document,
        "/*[local-name()='rss']/*[local-name()='channel']/*[local-name()='title'][1] | /*[local-name()='feed']/*[local-name()='title'][1] | /*[local-name()='RDF']/*[local-name()='channel']/*[local-name()='title'][1]"
      ))
      if (!length(feed_title) || is.na(feed_title) ||
          !nzchar(trimws(feed_title))) {
        feed_title <- NA_character_
      }

      items <- lapply(entries, function(entry) {
        author <- rss_first_text(entry, c("creator", "author"))
        author_name <- xml2::xml_text(xml2::xml_find_first(
          entry,
          "./*[local-name()='author']/*[local-name()='name'][1]"
        ))
        if (!is.na(author_name) && nzchar(trimws(author_name))) {
          author <- trimws(author_name)
        }

        published_raw <- rss_first_text(
          entry,
          c("pubDate", "published", "date", "issued", "created")
        )
        updated_raw <- rss_first_text(entry, c("updated", "modified"))

        data.table::data.table(
          feed_url = url,
          feed_title = feed_title,
          title = rss_first_text(entry, "title"),
          url = rss_link(entry, response$url),
          published_at = rss_date(published_raw),
          updated_at = rss_date(updated_raw),
          author = author,
          description = rss_first_text(entry, c("description", "summary")),
          item_id = rss_first_text(entry, c("guid", "id"))
        )
      })

      items <- data.table::rbindlist(items, fill = TRUE)
      items <- items[
        !is.na(url) & grepl("^https?://", url, ignore.case = TRUE)
      ]
      if (!nrow(items)) {
        warning(
          sprintf("RSS feed <%s> contains no article links.", url),
          call. = FALSE
        )
        return(rss_empty_items())
      }
      unique(items, by = "url")
    }, error = function(error) {
      warning(
        sprintf(
          "Could not read RSS feed <%s>: %s",
          url,
          conditionMessage(error)
        ),
        call. = FALSE
      )
      rss_empty_items()
    })
  }

  if (cores == 1) {
    results <- lapply(feed_url, fetch_one)
  } else {
    clust <- parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(clust), add = TRUE)
    parallel::clusterExport(
      cl = clust,
      varlist = c(
        "fetch_one", "rss_document", "rss_first_text", "rss_date",
        "rss_link", "rss_empty_items", ".tp_user_agent",
        ".rss_timeout_seconds"
      ),
      envir = environment()
    )
    results <- pbapply::pblapply(feed_url, fetch_one, cl = clust)
    parallel::stopCluster(clust)
    on.exit(NULL, add = FALSE)
  }

  data.table::rbindlist(results, fill = TRUE)
}

#' @noRd
rss_empty_items <- function() {
  data.table::data.table(
    feed_url = character(),
    feed_title = character(),
    title = character(),
    url = character(),
    published_at = character(),
    updated_at = character(),
    author = character(),
    description = character(),
    item_id = character()
  )
}

#' @noRd
rss_date <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(NA_character_)
  }

  parsed <- suppressWarnings(lubridate::parse_date_time(
    x,
    orders = c(
      "a d b Y H M S z", "a d b Y H M S",
      "Ymd HMS z", "Ymd HMS", "Ymd HM z", "Ymd HM", "Ymd"
    ),
    tz = "UTC",
    quiet = TRUE
  ))

  if (!length(parsed) || is.na(parsed[[1L]])) {
    NA_character_
  } else {
    format(parsed[[1L]], "%Y-%m-%d %H:%M:%S", tz = "UTC")
  }
}

#' @noRd
rss_first_text <- function(node, names) {
  xpath <- paste0("./*[local-name()='", names, "']", collapse = " | ")
  values <- trimws(xml2::xml_text(xml2::xml_find_all(node, xpath)))
  values <- values[nzchar(values)]
  if (length(values)) values[[1L]] else NA_character_
}

#' @noRd
rss_link <- function(entry, base_url) {
  nodes <- xml2::xml_find_all(entry, "./*[local-name()='link']")
  if (!length(nodes)) {
    return(NA_character_)
  }

  rel <- xml2::xml_attr(nodes, "rel")
  preferred <- is.na(rel) | rel == "" | rel == "alternate"
  if (any(preferred)) {
    nodes <- nodes[preferred]
  }

  href <- xml2::xml_attr(nodes, "href")
  text <- trimws(xml2::xml_text(nodes))
  candidates <- ifelse(!is.na(href) & nzchar(href), href, text)
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]

  if (!length(candidates)) {
    NA_character_
  } else {
    xml2::url_absolute(candidates[[1L]], base_url)
  }
}

#' @noRd
rss_document <- function(payload) {
  tryCatch(
    xml2::read_xml(payload),
    error = function(error) {
      text <- rawToChar(payload)
      text <- gsub(
        "&(?!(amp|lt|gt|quot|apos|#[0-9]+|#x[0-9A-Fa-f]+);)",
        "&amp;",
        text,
        perl = TRUE
      )
      xml2::read_xml(text)
    }
  )
}
