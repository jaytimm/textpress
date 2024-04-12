#' Fetch Chat Completions from OpenAI API with JSON Validation
#'
#' Interacts with the OpenAI API to obtain chat completions based on the GPT model. The function
#' supports various customization parameters for the request. Additionally, it includes
#' functionality to re-call the API if the returned 'message.content' is not properly
#' formed JSON, ensuring more robust API interaction.
#'
#' @param model The model to use, defaults to 'gpt-3.5-turbo'.
#' @param system_message System prompt
#' @param user_message User prompt
#' @param temperature Controls randomness in generation, default 1.
#' @param top_p Controls diversity of generation, default 1.
#' @param n Number of completions to generate, default 1.
#' @param stream If TRUE, returns a stream of responses, default FALSE.
#' @param stop Sequence of tokens which will automatically complete generation.
#' @param max_tokens The maximum number of tokens to generate, NULL for no limit.
#' @param presence_penalty Alters likelihood of new topics, default 0.
#' @param frequency_penalty Alters likelihood of repeated topics, default 0.
#' @param logit_bias A named list of biases to apply to token logits.
#' @param user An identifier for the user, if applicable.
#' @param openai_api_key The API key for OpenAI, defaults to the environment variable OPENAI_API_KEY.
#' @param openai_organization Optional organization identifier for the API.
#' @param is_json_output If TRUE, ensures output is valid JSON, default TRUE.
#' @return Returns a string with the API response, or JSON if is_json_output is TRUE.
#' @export
#' @examples
#' \dontrun{
#' api_openai_chat_completions(
#'    model = "gpt-3.5-turbo",
#'    messages = list(
#'        list(
#'            "role" = "system",
#'            "content" = "You are an expert at life."
#'        ),
#'        list(
#'            "role" = "user",
#'            "content" = "Where is the party at?"
#'        )
#'    )
#' )
#' }
#'
#'
#'
api_openai_chat_completions <- function(model = 'gpt-3.5-turbo',
                                        #messages = NULL,

                                        system_message = '',
                                        user_message = '',

                                        temperature = 1,
                                        top_p = 1,
                                        n = 1,
                                        stream = FALSE,
                                        stop = NULL,
                                        max_tokens = NULL,
                                        presence_penalty = 0,
                                        frequency_penalty = 0,
                                        logit_bias = NULL,
                                        user = NULL,
                                        openai_api_key = Sys.getenv("OPENAI_API_KEY"),
                                        openai_organization = NULL,

                                        is_json_output = TRUE) {

  # Ensure that the OpenAI API key is provided
  if (is.null(openai_api_key) || openai_api_key == "") {
    stop("OpenAI API key is missing.", call. = FALSE)
  }

  messages = list(
    list(
      "role" = "system",
      "content" = system_message
    ),

    list(
      "role" = "user",
      "content" = user_message
    )
  )

  # Internal function to make the API call
  make_call <- function() {
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(
        "Authorization" = paste("Bearer", openai_api_key),
        "Content-Type" = "application/json"
      ),
      body = list(
        model = model,
        messages = messages,
        temperature = temperature,
        top_p = top_p,
        n = n,
        stream = stream,
        stop = stop,
        max_tokens = max_tokens,
        presence_penalty = presence_penalty,
        frequency_penalty = frequency_penalty,
        logit_bias = logit_bias,
        user = user
      ),
      encode = "json"
    )

    # Handle HTTP errors
    if (httr::http_error(response)) {
      stop("API request failed with status code: ", httr::status_code(response), call. = FALSE)
    }

    out <- httr::content(response, "text", encoding = "UTF-8")
    jsonlite::fromJSON(out, flatten = TRUE)
  }

  # Make the initial API call
  output <- make_call()$choices$message.content

  # Check and retry for valid JSON output if necessary
  # If JSON validation is required
  if (is_json_output) {
    attempt <- 1
    max_attempts <- 10

    # Loop to ensure valid JSON response
    while (!.is_valid_json(output) && attempt <= max_attempts) {
      # Print attempt information
      cat("Attempt", attempt, ": Invalid JSON received. Regenerating...\n")
      # Retry API call
      output <- make_call()$choices$message.content
      attempt <- attempt + 1
    }

    # If valid JSON is not received after max attempts, stop execution
    if (!.is_valid_json(output)) {
      stop("Failed to receive valid JSON after ", max_attempts, " attempts.", call. = FALSE)
    }
  }

  # Return the final output
  output
}

# Internal helper function to check if a string is valid JSON
# @noRd
.is_valid_json <- function(json_string) {
  tryCatch({
    # Attempt to parse the JSON string
    jsonlite::fromJSON(json_string)
    # Return TRUE if parsing is successful
    TRUE
  }, error = function(e) {
    # Return FALSE if an error occurs (invalid JSON)
    FALSE
  })
}
