#' Extract Embeddings from OpenAI
#'
#' This function sends a text to the OpenAI API and retrieves its embeddings.
#'
#' @param x A character string representing the text to be embedded.
#' @return A numeric vector representing the embeddings of the input text.
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
#' @examples
#' # Example usage
#' # Sys.setenv(OPENAI_API_KEY = "your_api_key_here")
#' # wd_extract_openai_embs("Example text")

#' @export
#' @rdname llm_get_openai_embs
#'

llm_get_openai_embs <- function(tif,
                                 batch.id,
                                 text.segment,
                                 text.segment.id,
                                 query = NULL,
                                 wait = 30){

  if(!is.null(query)){
    embeddings <- openai_embs(x = query)
    m99 <- matrix(unlist(embeddings), ncol = 1536, nrow = 1)
    rownames(m99) <- stringr::str_trunc(query, 100)
    m99
  } else{

    z <- split(tif, tif[[batch.id]])
    eb_list <- list()

    for(i in 1:length(z)){

      txt <- z[[i]][[text.segment]]

      embeddings <-openai_embs(x = txt)
      m99 <- matrix(unlist(embeddings), ncol = 1536, byrow = TRUE)

      rownames(m99) <- z[[i]][[text.segment.id]]
      eb_list[[i]] <- m99

      print(paste0('Batch ', i, ' of ', length(z)))
      Sys.sleep(wait)
    }

    do.call(rbind, eb_list)
  }
}


openai_embs <- function(x){

  # # Input validation
  # for (arg in c(batch.id, text.segment, text.segment.id)) {
  #   if (!arg %in% names(tif)) {
  #     stop(sprintf("Column '%s' not found in the data frame.", arg))
  #   }
  # }
  #
  # if (!is.null(query) && !is.character(query)) {
  #   stop("The 'query' must be a character string.")
  # }
  #
  # if (!is.numeric(wait) || length(wait) != 1) {
  #   stop("The 'wait' must be a single numeric value.")
  # }

  auth <- httr::add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY")))
  body <- list(model = "text-embedding-ada-002", input = x)

  resp <- httr::POST("https://api.openai.com/v1/embeddings",
                     auth,
                     body = body,
                     encode = "json")

  httr::content(resp, as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON(flatten = TRUE) |>
    purrr::pluck("data", "embedding")
}
