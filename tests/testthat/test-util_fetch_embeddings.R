test_that("data frame input requires by, text and unique ids", {
  df <- data.frame(uid = c(1, 1), text = c("a", "b"))
  expect_error(util_fetch_embeddings(df), "'by' is required")
  expect_error(util_fetch_embeddings(data.frame(uid = 1), by = "uid"), "'text'")
  expect_error(util_fetch_embeddings(df, by = "uid"), "uniquely identify")
})

test_that("an unreachable server gives setup instructions", {
  expect_error(
    util_fetch_embeddings("x", base_url = "http://localhost:1/v1"),
    "ollama pull all-minilm"
  )
})

test_that("embeddings come back one row per text from a local Ollama server", {
  skip_on_cran()
  ok <- tryCatch(
    httr::status_code(httr::GET("http://localhost:11434/api/tags", httr::timeout(2))) == 200,
    error = function(e) FALSE
  )
  skip_if_not(ok, "Ollama is not running")
  tags <- httr::content(httr::GET("http://localhost:11434/api/tags"))
  skip_if_not(any(grepl("^all-minilm", vapply(tags$models, `[[`, "", "name"))),
              "all-minilm is not pulled")

  df <- data.frame(uid = 1:70, text = paste("sentence number", 1:70))
  emb <- util_fetch_embeddings(df, by = "uid", batch_size = 32)
  expect_equal(dim(emb), c(70L, 384L))
  expect_equal(rownames(emb), as.character(1:70))
  expect_equal(attr(emb, "id_col"), "uid")

  long <- strrep("Turnout rose 12.5% (n = 1,204; 95% CI 3.1-4.8). ", 60)
  expect_message(e2 <- util_fetch_embeddings(c(a = long, b = "short")), "cut to 1000")
  expect_equal(dim(e2), c(2L, 384L))
})
