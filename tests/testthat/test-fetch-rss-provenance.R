test_that("fetch_rss has a minimal public interface", {
  expect_identical(names(formals(fetch_rss)), c("feed_url", "cores"))
  expect_identical(textpress:::.rss_timeout_seconds, 15)
  expect_true(is.data.frame(rss_politics))
  expect_gt(nrow(rss_politics), 0L)
  expect_true(is.data.frame(rss_local_rags))
  expect_gt(nrow(rss_local_rags), 0L)
  common <- c(
    "source", "feed", "category", "source_type", "url",
    "verified_at", "latest_item_at"
  )
  expect_identical(names(rss_politics), common)
  expect_identical(
    names(rss_local_rags),
    c(
      "source", "feed", "url", "verified_at", "latest_item_at",
      "census_division", "state_abbr", "county", "fips",
      "rucc_2023", "metro_status"
    )
  )
  expect_true(all(grepl("^[0-9]{5}$", rss_local_rags$fips)))
  expect_true(all(rss_local_rags$metro_status %in% c("Metro", "Nonmetro")))
})

test_that("RSS results expose common provenance fields", {
  items <- data.table::data.table(
    feed_url = "https://feeds.example/rss",
    feed_title = "Example News",
    title = c("First", "Second"),
    url = c(
      "https://news.example/first",
      "https://news.example/second"
    ),
    published_at = c("2026-08-27 10:00:00", "2026-08-27 09:00:00"),
    updated_at = NA_character_,
    author = NA_character_,
    description = c("One", "Two"),
    item_id = c("1", "2")
  )

  result <- textpress:::rss_finalize_items(items)
  expect_identical(result$doc_id, 1:2)
  expect_identical(result$source, rep("news.example", 2L))
  expect_true(all(is.na(result$language)))
  expect_true(all(is.na(result$country)))
  expect_named(
    result,
    c(
      "doc_id", "url", "title", "published_at", "source", "language",
      "country", "feed_url", "feed_title", "updated_at", "author",
      "description", "item_id"
    )
  )
})

test_that("empty RSS results retain typed common columns", {
  result <- textpress:::rss_finalize_items(textpress:::rss_empty_items())
  expect_equal(nrow(result), 0L)
  expect_type(result$doc_id, "integer")
  expect_type(result$source, "character")
  expect_type(result$language, "character")
  expect_type(result$country, "character")
})

test_that("fetch_rss cores argument dispatches through the parallel path", {
  unreachable <- "http://127.0.0.1:1/missing"
  serial <- suppressWarnings(fetch_rss(unreachable, cores = 1))
  parallel_result <- suppressWarnings(fetch_rss(unreachable, cores = 2))
  expect_identical(names(serial), names(parallel_result))
  expect_equal(nrow(serial), 0L)
  expect_equal(nrow(parallel_result), 0L)
})
