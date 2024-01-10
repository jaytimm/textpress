#' Extract Embeddings from OpenAI
#'
#' This function sends a text to the OpenAI API and retrieves its embeddings.
#'
#' @param x A character string representing the text to be embedded.
#' @return A numeric vector representing the embeddings of the input text.
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
#' @export
#' @rdname rag_fetch_openai_embs
#'

rag_fetch_openai_embs <- function(tif,
                                  batch_id = 'batch_id',
                                  text = 'text',
                                  text_id = 'text_id',
                                  query = NULL,
                                  wait = 30){

  if(!is.null(query)){
    embeddings <- .openai_embs(x = query)
    m99 <- matrix(unlist(embeddings), ncol = 1536, nrow = 1)
    rownames(m99) <- stringr::str_trunc(query, 100)
    m99
  } else{

    z <- split(tif, tif[[batch_id]])
    eb_list <- list()

    for(i in 1:length(z)){

      txt <- z[[i]][[text]]

      embeddings <- openai_embs(x = txt)
      m99 <- matrix(unlist(embeddings), ncol = 1536, byrow = TRUE)

      rownames(m99) <- z[[i]][[text_id]]
      eb_list[[i]] <- m99

      print(paste0('Batch ', i, ' of ', length(z)))
      Sys.sleep(wait)
    }

    do.call(rbind, eb_list)
  }
}



#' Fetches embeddings from OpenAI API, internal function.
#'
#' @param x Text input for embedding generation.
#' @return A list of embeddings for the given input.
#' @keywords internal
#' @noRd
.openai_embs <- function(x) {
  # Add authorization header with OpenAI API key
  auth <- httr::add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY")))

  # Define request body with model and input
  body <- list(model = "text-embedding-ada-002", input = x)

  # Send POST request to OpenAI API
  resp <- httr::POST("https://api.openai.com/v1/embeddings",
                     auth,
                     body = body,
                     encode = "json")

  # Extract and return embeddings from the response
  httr::content(resp, as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON(flatten = TRUE) |>
    purrr::pluck("data", "embedding")
}
