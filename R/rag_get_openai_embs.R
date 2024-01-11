#' Fetch OpenAI Embeddings
#'
#' Retrieves embeddings from OpenAI for a given text or a batch of texts.
#' It can process a single query or batches of text data from a dataframe.
#'
#' @param tif A dataframe containing text data.
#' @param batch_id The name of the column in `tif` identifying each batch. Default is 'batch_id'.
#' @param text The name of the column in `tif` containing the text data. Default is 'text'.
#' @param text_id The name of the column in `tif` for text identifiers. Default is 'text_id'.
#' @param query An optional single text query for fetching embeddings.
#' @param wait Time in seconds to wait between processing batches. Default is 30 seconds.
#' @return A matrix of embeddings for either a single query or a combined matrix for all batches.
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
#' @importFrom stringr str_trunc
#' @export

#'
#'
rag_fetch_openai_embs <- function(tif,
                                  batch_id = "batch_id",
                                  text = "text",
                                  text_id = "text_id",
                                  query = NULL,
                                  wait = 30) {
  # Check if query is provided and process it
  if (!is.null(query)) {
    embeddings <- .openai_embs(x = query)
    m99 <- matrix(unlist(embeddings), ncol = 1536, nrow = 1)
    rownames(m99) <- stringr::str_trunc(query, 100)
    return(m99)
  } else {
    # Validate input dataframe
    if (!("data.frame" %in% class(tif))) {
      stop("tif must be a dataframe")
    }

    # Splitting the dataframe into batches based on batch_id
    z <- split(tif, tif[[batch_id]])
    eb_list <- list()

    # Process each batch
    for (i in seq_along(z)) {
      txt <- z[[i]][[text]]

      embeddings <- .openai_embs(x = txt)
      m99 <- matrix(unlist(embeddings), ncol = 1536, byrow = TRUE)
      rownames(m99) <- z[[i]][[text_id]]
      eb_list[[i]] <- m99

      # Print progress
      print(paste0("Batch ", i, " of ", length(z)))
      Sys.sleep(wait)
    }

    # Return combined matrix of all batches
    return(do.call(rbind, eb_list))
  }
}

#' Internal function for fetching embeddings
#' @param x A character string or vector of texts to fetch embeddings for.
#' @keywords internal
#'
#'
.openai_embs <- function(x) {
  # Add authorization header with OpenAI API key
  auth <- httr::add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY")))

  # Define request body with model and input
  body <- list(model = "text-embedding-ada-002", input = x)

  # Send POST request to OpenAI API
  resp <- httr::POST("https://api.openai.com/v1/embeddings",
    auth,
    body = body,
    encode = "json"
  )

  # Extract and return embeddings from the response
  httr::content(resp, as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON(flatten = TRUE) |>
    purrr::pluck("data", "embedding")
}
