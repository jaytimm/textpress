#' Fetch embeddings (Hugging Face utility)
#'
#' A lightweight wrapper to convert a textpress corpus into an embedding matrix
#' suitable for the \code{embeddings} argument of \code{\link{search_vector}}.
#' Uses your Hugging Face API token and endpoint; no retries or batching.
#' API stability and rate limits are the user's responsibility.
#'
#' @param corpus A data frame or data.table with a \code{text} column and the identifiers specified in \code{by}.
#' @param by Character vector of column names that identify each text unit.
#'   These are collapsed into row names of the returned matrix (e.g. \code{"doc_1_para_2"}).
#' @param api_token Your Hugging Face API token (see \url{https://huggingface.co/settings/tokens}).
#' @param api_url The inference endpoint URL (e.g. \code{"https://api-inference.huggingface.co/models/sentence-transformers/all-MiniLM-L6-v2"}).
#' @return A numeric matrix with one row per corpus row; \code{rownames} are the collapsed \code{by} identifiers.
#' @export
#' @examples
#' \dontrun{
#' corpus <- data.frame(doc_id = c("1", "2"), text = c("First document.", "Second document."))
#' url <- "https://api-inference.huggingface.co/models/sentence-transformers/all-MiniLM-L6-v2"
#' m <- util_fetch_embeddings(corpus, by = "doc_id", api_token = "hf_xxx", api_url = url)
#' search_vector(m, "1", n = 2)
#' }
util_fetch_embeddings <- function(corpus, by, api_token, api_url) {
  if (!"text" %in% names(corpus)) {
    stop("corpus must contain a 'text' column.", call. = FALSE)
  }
  if (!all(by %in% names(corpus))) {
    stop("All 'by' columns must be present in corpus.", call. = FALSE)
  }

  ids <- apply(corpus[, by, drop = FALSE], 1L, paste, collapse = "_")

  resp <- httr::POST(
    url = api_url,
    httr::add_headers(Authorization = paste("Bearer", api_token)),
    body = list(inputs = as.list(corpus$text)),
    encode = "json"
  )
  httr::stop_for_status(resp)

  res <- httr::content(resp, as = "parsed")
  if (!is.list(res) || length(res) == 0L) {
    stop("Unexpected API response: expected a list of embeddings.", call. = FALSE)
  }

  first <- res[[1L]]
  if (is.list(first) && "embedding" %in% names(first)) {
    mat <- do.call(rbind, lapply(res, function(x) x$embedding))
  } else {
    mat <- matrix(unlist(res), nrow = length(res), byrow = TRUE)
  }
  rownames(mat) <- ids
  mat
}
