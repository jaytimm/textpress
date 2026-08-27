common_columns <- c(
  "source", "feed", "category", "source_type", "url",
  "verified_at", "latest_item_at"
)

rss_politics <- utils::read.csv(
  "data-raw/rss_politics.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(
  nrow(rss_politics) > 0L,
  identical(names(rss_politics), common_columns),
  !anyDuplicated(rss_politics$url)
)

rss_local_rags <- utils::read.csv(
  "data-raw/rss_local_rags.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  colClasses = "character",
  na.strings = c("", "NA")
)

# CRAN checks packaged data for non-ASCII strings. Keep the distributed
# snapshot portable while leaving feed URLs and geographic identifiers intact.
character_columns <- vapply(rss_local_rags, is.character, logical(1L))
rss_local_rags[character_columns] <- lapply(
  rss_local_rags[character_columns],
  iconv,
  from = "UTF-8",
  to = "ASCII//TRANSLIT"
)

local_columns <- c(
  common_columns,
  "census_region", "state_abbr", "county", "fips"
)
stopifnot(
  nrow(rss_local_rags) > 0L,
  identical(names(rss_local_rags), local_columns),
  all(is.na(rss_local_rags$fips) |
    grepl("^[0-9]{5}$", rss_local_rags$fips)),
  !anyDuplicated(rss_local_rags$url),
  !any(grepl("[^ -~]", unlist(rss_local_rags), useBytes = TRUE))
)

save(
  rss_politics,
  file = "data/rss_politics.rda",
  version = 2,
  compress = "xz"
)
save(
  rss_local_rags,
  file = "data/rss_local_rags.rda",
  version = 2,
  compress = "xz"
)
