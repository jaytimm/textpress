#' LLM API Completions
#'
#' This function generates text using the OpenAI API.
#'
#' @param id A unique identifier for the request.
#' @param user_message The message provided by the user.
#' @param annotators The number of annotators (default is 1).
#' @param model_name The name of the OpenAI model to use (default is 'gpt-3.5-turbo').
#' @param temperature The temperature for the model's output (default is 1).
#' @param top_p The top-p sampling value (default is 1).
#' @param max_tokens The maximum number of tokens to generate (default is NULL).
#' @param is_json_output A logical indicating whether the output should be JSON (default is TRUE).
#' @param max_attempts The maximum number of attempts to make for generating valid output (default is 10).
#' @param openai_api_key The API key for the OpenAI API (default is retrieved from environment variables).
#' @param openai_organization The organization ID for the OpenAI API (default is NULL).
#' @param cores The number of cores to use for parallel processing (default is 1).
#' @return A data.table containing the generated text and metadata.
#' @examples
#' \dontrun{
#' llm_api_completions(id = "example_id", user_message = "What is the capital of France?", openai_api_key = "your_api_key")
#' }
#' @import data.table
#' @importFrom parallel makeCluster clusterExport stopCluster
#' @importFrom pbapply pblapply
#' @importFrom httr POST add_headers content http_error status_code
#' @importFrom jsonlite fromJSON
#' @export
llm_api_completions <- function(id,
                                user_message = '',
                                annotators = 1,
                                model_name = 'gpt-3.5-turbo',
                                temperature = 1,
                                top_p = 1,
                                max_tokens = NULL,
                                is_json_output = TRUE,
                                max_attempts = 10,
                                openai_api_key = Sys.getenv("OPENAI_API_KEY"),
                                openai_organization = NULL,
                                cores = 1) {
  # Prepare data
  text_df <- data.table::data.table(id = rep(id, annotators),
                                    annotator_id = .generate_random_ids(annotators),
                                    user_message = rep(user_message, annotators))

  # Define the processing function
  process_function <- function(row) {
    make_call <- function() {
      x <- .openai_chat_completions(model = model_name,
                                    system_message = '',
                                    user_message = row$user_message,
                                    temperature = temperature,
                                    top_p = top_p,
                                    max_tokens = max_tokens,
                                    openai_api_key = openai_api_key,
                                    openai_organization = openai_organization,
                                    is_json_output = is_json_output)

      parsed_output <- jsonlite::fromJSON(x)
      parsed_output$choices$message$content
    }

    validation_result <- .validate_json_output(make_call, is_json_output, max_attempts)

    list(id = row$id,
         annotator_id = row$annotator_id,
         response = validation_result$response,
         attempts = validation_result$attempts,
         success = validation_result$success)
  }

  if (cores > 1) {
    cl <- parallel::makeCluster(cores)
    parallel::clusterExport(cl, varlist = c(".openai_chat_completions", ".is_valid_json"),
                            envir = environment())

    results <- pbapply::pblapply(split(text_df, seq(nrow(text_df))), function(row) {
      process_function(row)
    }, cl = cl)

    parallel::stopCluster(cl)
  } else {
    #row <- split(text_df, seq(nrow(text_df)))[[1]]
    results <- pbapply::pblapply(split(text_df, seq(nrow(text_df))), function(row) {
      process_function(row)
    })
  }

  # Process results
  processed_results <- .process_results(results, is_json_output)

  return(processed_results)
}



#' OpenAI Chat Completions
#'
#' This function interacts with the OpenAI API to generate text completions.
#'
#' @param model The model to use for the API call.
#' @param system_message The message provided by the system (e.g., instructions or context).
#' @param user_message The message provided by the user.
#' @param temperature The temperature for the model's output.
#' @param top_p The top-p sampling value.
#' @param max_tokens The maximum number of tokens to generate.
#' @param openai_api_key The API key for the OpenAI API.
#' @param openai_organization The organization ID for the OpenAI API.
#' @param is_json_output A logical indicating whether the output should be JSON.
#' @param max_attempts The maximum number of attempts to make for generating valid output.
#' @return The generated text.
#' @importFrom httr POST add_headers content http_error status_code
#' @importFrom jsonlite fromJSON
#' @export
.openai_chat_completions <- function(model = 'gpt-3.5-turbo',
                                     system_message = '',
                                     user_message = '',
                                     temperature = 1,
                                     top_p = 1,
                                     max_tokens = NULL,
                                     openai_api_key,
                                     openai_organization,
                                     is_json_output = TRUE) {

  if (is.null(openai_api_key) || openai_api_key == "") {
    stop("OpenAI API key is missing.", call. = FALSE)
  }

  messages <- list(
    list("role" = "system", "content" = system_message),
    list("role" = "user", "content" = user_message)
  )

  response <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    httr::add_headers("Authorization" = paste("Bearer", openai_api_key),
                      "Content-Type" = "application/json"),
    body = list(model = model,
                messages = messages,
                temperature = temperature,
                top_p = top_p,
                max_tokens = max_tokens),
    encode = "json"
  )

  if (httr::http_error(response)) {
    error_content <- httr::content(response, "text", encoding = "UTF-8")
    cat("API request failed with status code:", httr::status_code(response), "\n")
    cat("Error response content:\n", error_content, "\n")
    stop("API request failed with status code: ", httr::status_code(response), call. = FALSE)
  }

  httr::content(response, "text", encoding = "UTF-8")
}
