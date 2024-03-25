#' Call Hugging Face API for Embeddings
#'
#' Retrieves embeddings for text data using Hugging Face's API. It can process a batch of texts or a single query.  Mostly for demo purposes.
#'
#' @param tif A data frame containing text data.
#' @param text_hierarchy A character vector indicating the columns used to create row names.
#' @param api_token Token for accessing the Hugging Face API.
#' @param api_url The URL of the Hugging Face API endpoint (default is set to a specific model endpoint).
#' @param query An optional single text query for which embeddings are required.
#' @param dims The dimension of the output embeddings.
#' @param batch_size Number of rows in each batch sent to the API.
#' @param sleep_duration Duration in seconds to pause between processing batches.
#'
#' @return A matrix containing embeddings, with each row corresponding to a text input.
#'
#' @export
api_huggingface_embeddings <- function(tif,
                                 text_hierarchy,
                                 api_token,
                                 api_url = "https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2",
                                 query = NULL,
                                 dims = 384,
                                 batch_size = 250,
                                 sleep_duration = 1) {

  # Handling a single query
  if (!is.null(query)) {
    embeddings <- .huggingface_embs(x = query, api_token, api_url)
    m99 <- matrix(unlist(embeddings), ncol = dims, nrow = 1)
    rownames(m99) <- stringr::str_trunc(query, 100)
    return(m99)
  } else {

    # Create batch indices for processing in batches
    batch_indices <- ceiling(seq_len(nrow(tif)) / batch_size)
    batches <- split(tif, batch_indices)
    eb_list <- list()

    # Loop through each batch
    # Initialize progress bar
    pb <- txtProgressBar(min = 0, max = length(batches), style = 3)

    for (i in seq_along(batches)) {

      setTxtProgressBar(pb, i)
      # Generate row names based on 'by' columns
      rns <- do.call(paste, c(batches[[i]][, text_hierarchy, with = FALSE], sep = '.'))
      # Fetch embeddings for the batch
      embeddings <- .huggingface_embs(batches[[i]][['text']], api_token, api_url)
      m99 <- matrix(unlist(embeddings), ncol = dims, byrow = TRUE)

      rownames(m99) <- rns
      eb_list[[i]] <- m99

      # Pause between processing batches
      Sys.sleep(sleep_duration)
    }

    # Close progress bar
    close(pb)

    # Combine results from all batches into one matrix
    return(do.call(rbind, eb_list))
  }
}

#' Internal: Get Embeddings from Hugging Face API
#'
#' @noRd
.huggingface_embs <- function(x, api_token, api_url) {
  headers <- c(`Authorization` = paste("Bearer", api_token))

  attempt <- 1
  max_attempts <- 5

  # Retry mechanism for API requests
  repeat {
    response <- tryCatch({
      # POST request to Hugging Face API
      httr::POST(url = api_url,
                 httr::add_headers(.headers = headers),
                 body = list(inputs = x),
                 encode = "json")
    }, error = function(e) e)

    # Break loop if response is successful
    if (!inherits(response, "error")) {
      break
    }

    # Stop if maximum attempts reached
    if (attempt >= max_attempts) {
      stop("Failed to get response after ", max_attempts, " attempts: ", response$message)
    }

    # Exponential back-off strategy for retrying
    Sys.sleep(2 ^ attempt)
    attempt <- attempt + 1
  }

  # Return parsed content from response
  httr::content(response, "parsed")
}
