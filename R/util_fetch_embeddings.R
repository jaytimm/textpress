#' Fetch embeddings from an OpenAI-compatible endpoint
#'
#' Builds a numeric matrix of embeddings for each text unit. Row names come from
#' \code{by} (data frame) or from \code{names(corpus)} / \code{corpus} (character vector).
#' Use the result with \code{\link{search_vector}} for semantic search.
#'
#' By default this calls a local \href{https://ollama.com}{Ollama} server with
#' the small \code{all-minilm} model, so no account or API key is needed. Install
#' Ollama, then run \code{ollama pull all-minilm} once. Any service that offers
#' an OpenAI-compatible \code{/embeddings} endpoint (OpenAI, LM Studio,
#' llama.cpp, and many hosted providers) works by changing \code{base_url},
#' \code{model}, and \code{api_key}. Embeddings from any other source can be
#' passed to \code{\link{search_vector}} directly as a matrix with row names.
#'
#' @param corpus A data frame with \code{text} and \code{by} columns, or a character vector of texts. If a named character vector, names become row names; if unnamed, the strings themselves are used as row names.
#' @param by Character vector of identifier columns; required when \code{corpus} is a data frame (row names), ignored when \code{corpus} is a character vector.
#' @param model Embedding model name (default \code{"all-minilm"}).
#' @param base_url Base URL of an OpenAI-compatible API (default local Ollama, \code{"http://localhost:11434/v1"}).
#' @param api_key API key, sent as a bearer token. Not needed for local servers.
#' @param batch_size Number of texts sent per request (default 64).
#' @param max_chars Texts longer than this many characters are cut before
#'   sending (default 1000). Small models such as \code{all-minilm} read about
#'   256 tokens and Ollama rejects longer input rather than truncating it. Use
#'   \code{NULL} to send full text to models with a longer context.
#' @return Numeric matrix with row names (unit ids).
#' @examples
#' \dontrun{
#' # Requires a running Ollama server: ollama pull all-minilm
#' emb <- util_fetch_embeddings(c(a = "Gen Z voters", b = "Baby Boomers"))
#' search_vector(emb, "a", n = 2)
#'
#' # OpenAI instead
#' emb <- util_fetch_embeddings(
#'   c(a = "Gen Z voters", b = "Baby Boomers"),
#'   model = "text-embedding-3-small",
#'   base_url = "https://api.openai.com/v1",
#'   api_key = Sys.getenv("OPENAI_API_KEY")
#' )
#' }
#' @export
util_fetch_embeddings <- function(corpus,
                                  by = NULL,
                                  model = "all-minilm",
                                  base_url = "http://localhost:11434/v1",
                                  api_key = NULL,
                                  batch_size = 64L,
                                  max_chars = 1000L) {

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

  texts <- as.character(texts)
  if (!is.null(max_chars)) {
    long <- nchar(texts) > max_chars
    if (any(long)) {
      message(sum(long), " text(s) cut to ", max_chars,
              " characters for embedding; set `max_chars` to change.")
      texts[long] <- substr(texts[long], 1L, max_chars)
    }
  }
  url <- paste0(sub("/+$", "", base_url), "/embeddings")
  headers <- if (!is.null(api_key) && nzchar(api_key)) {
    httr::add_headers(Authorization = paste("Bearer", api_key))
  } else {
    NULL
  }

  batches <- split(seq_along(texts), ceiling(seq_along(texts) / batch_size))
  rows <- lapply(batches, function(i) {
    resp <- tryCatch(
      httr::POST(url, headers,
                 body = list(model = model, input = texts[i]),
                 encode = "json"),
      error = function(e) {
        stop(sprintf(paste0(
          "Could not reach %s.\n",
          "For the default local setup, install Ollama (https://ollama.com), ",
          "make sure it is running, and run `ollama pull %s`."), url, model),
          call. = FALSE)
      }
    )
    status <- httr::status_code(resp)
    body <- httr::content(resp, as = "text", encoding = "UTF-8")
    if (status != 200) {
      hint <- switch(as.character(status),
        "401" = " Check `api_key`.",
        "402" = " The provider requires paid credits.",
        "404" = sprintf(" Is model '%s' available? For Ollama: `ollama pull %s`.", model, model),
        "")
      stop(sprintf("Embedding API error (%s).%s\n%s", status, hint, body), call. = FALSE)
    }
    data <- jsonlite::fromJSON(body, simplifyVector = FALSE)$data
    idx <- vapply(data, function(d) as.integer(d$index), integer(1))
    vecs <- lapply(data, function(d) as.numeric(unlist(d$embedding)))
    do.call(rbind, vecs[order(idx)])
  })

  m <- do.call(rbind, rows)
  if (!is.numeric(m) || nrow(m) != length(ids)) {
    stop("API did not return one embedding per input text.", call. = FALSE)
  }
  rownames(m) <- ids
  id_col_out <- if (is.character(corpus)) "uid" else if (length(by) == 1L) by else "uid"
  attr(m, "id_col") <- id_col_out
  return(m)
}
