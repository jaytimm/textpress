test_that("abbreviations affect sentence boundaries, not punctuation tokens", {
  corpus <- data.frame(
    doc_id = "d1",
    text = "Dr. Smith studies public health. Another sentence follows."
  )

  sentences <- nlp_split_sentences(corpus, by = "doc_id")
  expect_equal(nrow(sentences), 2L)
  expect_equal(trimws(sentences$text[[1L]]), "Dr. Smith studies public health.")

  tokens <- nlp_tokenize_text(
    sentences[1L, ], by = c("doc_id", "sentence_id"), method = "biber"
  )
  expect_equal(tokens$tokens[[1L]][1:3], c("Dr", ".", "Smith"))
})

test_that("biber spans address the original text", {
  text <- "Dr. Smith's well-known work. They've re-tested it."
  corpus <- data.frame(doc_id = "d1", sentence_id = "s1", text = text)

  tokens <- nlp_tokenize_text(
    corpus, by = c("doc_id", "sentence_id"),
    method = "biber", include_spans = TRUE
  )
  flat <- nlp_cast_tokens(tokens)

  expect_equal(
    flat$token,
    c(
      "Dr", ".", "Smith", "'s", "well-known", "work", ".",
      "They", "'ve", "re-tested", "it", "."
    )
  )
  expect_equal(substring(text, flat$start, flat$end), flat$token)
})

test_that("curly contraction suffixes retain source spans", {
  text <- "They\u2019ve re-tested it."
  corpus <- data.frame(doc_id = "d1", sentence_id = "s1", text = text)
  tokens <- nlp_tokenize_text(
    corpus, by = c("doc_id", "sentence_id"), method = "biber"
  )
  flat <- nlp_cast_tokens(tokens)

  expect_equal(flat$token, c("They", "'ve", "re-tested", "it", "."))
  source_tokens <- substring(text, flat$start, flat$end)
  source_tokens <- sub("^\u2019", "'", source_tokens)
  expect_equal(source_tokens, flat$token)
})

test_that("biber tokens are unchanged when spans are omitted", {
  corpus <- data.frame(doc_id = "d1", text = "Smith's well-known work.")
  with_spans <- nlp_tokenize_text(
    corpus, by = "doc_id", method = "biber", include_spans = TRUE
  )
  without_spans <- nlp_tokenize_text(
    corpus, by = "doc_id", method = "biber", include_spans = FALSE
  )

  expect_equal(unname(without_spans), unname(with_spans$tokens))
})

test_that("biber handles empty text", {
  corpus <- data.frame(doc_id = "d1", text = "")
  tokens <- nlp_tokenize_text(corpus, by = "doc_id", method = "biber")

  expect_length(tokens$tokens[[1L]], 0L)
  expect_equal(dim(tokens$spans[[1L]]), c(0L, 2L))
})
