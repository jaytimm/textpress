#' Fetch embeddings from a Hugging Face inference endpoint
#'
#' Builds a numeric matrix of embeddings for each text unit. Row names come from
#' \code{by} (data frame) or from \code{names(corpus)} / \code{corpus} (character vector).
#' Use the result with \code{\link{search_vector}} for semantic search.
#'
#' @param corpus A data frame with \code{text} and \code{by} columns, or a character vector of texts. If a named character vector, names become row names; if unnamed, the strings themselves are used as row names.
#' @param by Character vector of identifier columns; required when \code{corpus} is a data frame (row names), ignored when \code{corpus} is a character vector.
#' @param api_token Hugging Face API token.
#' @param api_url Inference endpoint URL (default BAAI/bge-small-en-v1.5).
#' @return Numeric matrix with row names (unit ids).
#' @export
util_fetch_embeddings <- function(corpus,
                                  by = NULL,
                                  api_token,
                                  api_url = "https://router.huggingface.co/hf-inference/models/BAAI/bge-small-en-v1.5") {

  if (is.character(corpus)) {
    texts <- corpus
    ids <- if (!is.null(names(corpus)) && all(nzchar(names(corpus)))) names(corpus) else as.character(corpus)
  } else {
    if (is.null(by) || length(by) == 0L) {
      stop("'by' is required when corpus is a data frame.", call. = FALSE)
    }
    if (!"text" %in% names(corpus)) {
      stop("corpus must contain a 'text' column.", call. = FALSE)
    }
    if (!all(by %in% names(corpus))) {
      stop("All 'by' columns must be present in corpus.", call. = FALSE)
    }
    corpus_dt <- data.table::as.data.table(corpus)
    if (any(duplicated(corpus_dt, by = by))) {
      stop("'by' must uniquely identify rows; found duplicate key combinations.", call. = FALSE)
    }
    if (length(by) == 1L) {
      ids <- corpus_dt[[by]]
      if (!is.character(ids)) ids <- as.character(ids)
    } else {
      id_data <- corpus_dt[, ..by]
      ids <- apply(id_data, 1L, paste, collapse = "_")
    }
    texts <- corpus_dt[["text"]]
  }

  resp <- httr::POST(
    url = api_url,
    httr::add_headers(Authorization = paste("Bearer", api_token)),
    body = list(
      inputs = texts,
      options = list(wait_for_model = TRUE)
    ),
    encode = "json"
  )

  # 4. Error Handling
  if (httr::status_code(resp) != 200) {
    err_msg <- httr::content(resp, "text", encoding = "UTF-8")
    stop(sprintf("API Error (%s): %s", httr::status_code(resp), err_msg), call. = FALSE)
  }

  # 5. Robust Manual Parsing
  # We fetch as raw text and use jsonlite directly to avoid "No automatic parser" errors
  resp_raw <- httr::content(resp, as = "text", encoding = "UTF-8")

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required to parse API response.", call. = FALSE)
  }

  res <- jsonlite::fromJSON(resp_raw)

  # 6. Convert to numeric matrix (API may return vector for single input)
  m <- as.matrix(res)
  if (!is.numeric(m)) {
    stop("API did not return a numeric matrix. Check the model output format.", call. = FALSE)
  }
  if (nrow(m) != length(ids)) {
    if (is.vector(res) && length(ids) == 1L) {
      m <- t(m)
    }
  }
  rownames(m) <- ids
  id_col_out <- if (is.character(corpus)) "uid" else if (length(by) == 1L) by else "uid"
  attr(m, "id_col") <- id_col_out
  return(m)
}
