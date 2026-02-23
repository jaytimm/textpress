#' Fetch embeddings (Hugging Face utility)
#'
#' @param corpus A data frame or data.table with a \code{text} column.
#' @param by Character vector of column names that identify each text unit.
#' @param api_token Your Hugging Face API token.
#' @param api_url The inference endpoint URL.
#' @return A numeric matrix with row names derived from \code{by}.
#' @export
util_fetch_embeddings <- function(corpus,
                                  by,
                                  api_token,
                                  api_url = "https://router.huggingface.co/hf-inference/models/BAAI/bge-small-en-v1.5") {

  # 1. Validation
  if (!"text" %in% names(corpus)) {
    stop("corpus must contain a 'text' column.", call. = FALSE)
  }
  if (!all(by %in% names(corpus))) {
    stop("All 'by' columns must be present in corpus.", call. = FALSE)
  }

  # 2. Robust column selection (handling data.table and data.frame)
  if (data.table::is.data.table(corpus)) {
    id_data <- corpus[, ..by]
  } else {
    id_data <- corpus[, by, drop = FALSE]
  }

  # Create unique identifiers for row names
  ids <- apply(id_data, 1L, paste, collapse = "_")

  # 3. Use httr::POST to send the request
  resp <- httr::POST(
    url = api_url,
    httr::add_headers(Authorization = paste("Bearer", api_token)),
    body = list(
      inputs = as.list(corpus$text),
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

  # 6. Convert to numeric matrix
  m <- as.matrix(res)
  if (!is.numeric(m)) {
    stop("API did not return a numeric matrix. Check the model output format.", call. = FALSE)
  }

  rownames(m) <- ids
  return(m)
}
