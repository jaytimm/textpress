#' Curated US politics RSS feeds
#'
#' A verified collection of non-government RSS and Atom feeds covering US
#' politics. The collection includes general political news, Congress,
#' elections, polling, public opinion, and state politics. Feed activity was
#' checked on the date recorded in \code{verified_at}; publisher availability
#' can change after that date. Access it directly as
#' \code{textpress::rss_politics}.
#'
#' @format A data frame with one row per feed and seven variables:
#' \describe{
#'   \item{source}{Publisher or organization name.}
#'   \item{feed}{Publisher-supplied or descriptive feed name.}
#'   \item{category}{Primary subject category assigned by textpress.}
#'   \item{source_type}{Type of publisher or organization.}
#'   \item{url}{RSS or Atom feed URL.}
#'   \item{verified_at}{UTC date and time when the feed was last checked.}
#'   \item{latest_item_at}{UTC publication date and time of the newest item observed during verification.}
#' }
#' @source Publisher-provided RSS and Atom endpoints.
#' @usage rss_politics
#' @examples
#' head(textpress::rss_politics)
"rss_politics"

#' Curated US local-news RSS feeds
#'
#' A pinned snapshot of the canonical Local Rags RSS output. Each row identifies
#' one unique US local-news feed with publisher, feed, verification, Census
#' division, county, and rural-urban geography. Access it directly as
#' \code{textpress::rss_local_rags}. Full discovery and 3DLNews provenance
#' remain in the source project.
#'
#' @format A data frame with one row per feed and 11 variables:
#'   \code{source}, \code{feed}, \code{url}, \code{verified_at},
#'   \code{latest_item_at}, \code{census_division}, \code{state_abbr},
#'   \code{county}, five-character \code{fips} county code,
#'   \code{rucc_2023}, and \code{metro_status}.
#' @source Local Rags RSS, \url{https://github.com/jaytimm/local-rags-rss},
#'   derived from 3DLNews, \url{https://github.com/wm-newslab/3DLNews}.
#' @usage rss_local_rags
#' @examples
#' head(textpress::rss_local_rags)
"rss_local_rags"
