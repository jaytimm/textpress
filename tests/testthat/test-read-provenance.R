mock_articles <- function(x, ...) {
  data.table::data.table(
    url = x,
    h1_title = paste("Scraped", seq_along(x)),
    date = "2026-08-20",
    type = "p",
    node_id = 1L,
    parent_heading = NA_character_,
    text = "Article text."
  )
}

test_that("read_urls remains compatible with character input", {
  testthat::local_mocked_bindings(
    .article_extract = mock_articles,
    .package = "textpress"
  )

  result <- read_urls(c("https://one.example/a", "https://two.example/b"))
  expect_identical(result$meta$doc_id, 1:2)
  expect_identical(result$text$doc_id, 1:2)
  expect_named(
    result$meta,
    c("doc_id", "url", "h1_title", "date", "source")
  )
})

test_that("read_urls preserves discovery metadata and document IDs", {
  testthat::local_mocked_bindings(
    .article_extract = mock_articles,
    .package = "textpress"
  )
  discovery <- data.frame(
    doc_id = c(41L, 99L),
    url = c("https://one.example/a", "https://two.example/b"),
    title = c("Fetched one", "Fetched two"),
    published_at = c("2026-08-27 12:00:00", NA),
    source = c("publisher.example", NA),
    language = c("English", "Spanish")
  )

  result <- read_urls(discovery)
  expect_identical(result$meta$doc_id, c(41L, 99L))
  expect_identical(result$text$doc_id, c(41L, 99L))
  expect_identical(result$meta$title, discovery$title)
  expect_identical(result$meta$date, c("2026-08-27", "2026-08-20"))
  expect_identical(
    result$meta$source,
    c("publisher.example", "two.example")
  )
  expect_identical(result$meta$language, discovery$language)
})

test_that("read_urls validates table input and handles empty input", {
  expect_error(read_urls(data.frame(x = "https://example.com")), "`url`")
  expect_error(
    read_urls(data.frame(url = c("https://a.example", NA_character_))),
    "non-missing"
  )
  expect_error(
    read_urls(data.frame(
      doc_id = c(1L, 1L),
      url = c("https://a.example", "https://b.example")
    )),
    "unique"
  )

  result <- read_urls(character())
  expect_equal(nrow(result$text), 0L)
  expect_equal(nrow(result$meta), 0L)
  expect_named(
    result$meta,
    c("doc_id", "url", "h1_title", "date", "source")
  )
})
