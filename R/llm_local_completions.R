#' LLM Local Completions
#'
#' This function generates text using a local model.
#'
#' @param id A unique identifier for the request.
#' @param user_message The message provided by the user.
#' @param annotators The number of annotators (default is 1).
#' @param model_name The name of the local model to use.
#' @param temperature The temperature for the model's output (default is 1).
#' @param max_length The maximum length of the input prompt (default is 1024).
#' @param max_new_tokens The maximum number of new tokens to generate (default is NULL).
#' @param is_json_output A logical indicating whether the output should be JSON (default is TRUE).
#' @param max_attempts The maximum number of attempts to make for generating valid output (default is 10).
#' @return A data.table containing the generated text and metadata.
#' @examples
#' \dontrun{
#' llm_local_completions(id = "example_id", user_message = "What is the capital of France?", model_name = "mistralai/Mistral-7B-Instruct-v0.2")
#' }
#' @import data.table
#' @importFrom reticulate source_python
#' @export
llm_local_completions <- function(id,
                                  user_message = '',
                                  annotators = 1,
                                  model_name,
                                  temperature = 1,
                                  max_length = 1024,
                                  max_new_tokens = NULL,
                                  is_json_output = TRUE,
                                  max_attempts = 10) {
  # Source Python script
  reticulate::source_python(system.file("python", "llm_functions.py", package = "textpress"))

  # Initialize local model
  model_pipeline <- .get_local_model(model_name)

  # Prepare data
  text_df <- data.table::data.table(id = rep(id, annotators),
                                    annotator_id = .generate_random_ids(annotators),
                                    user_message = rep(user_message, annotators))

  # Define the processing function
  process_function <- function(row) {
    make_call <- function() {
      ## row <- text_df[1,]
      reticulate::py$generate_text(model_pipeline,
                                   row$user_message,
                                   temperature,
                                   max_length,
                                   max_new_tokens,
                                   max_attempts,
                                   is_json_output)
    }

    validation_result <- .validate_json_output(make_call,
                                               is_json_output,
                                               max_attempts)
    list(id = row$id,
         annotator_id = row$annotator_id,
         response = validation_result$response,
         attempts = validation_result$attempts,
         success = validation_result$success)
  }

  # Process requests with progress bar
  results <- pbapply::pblapply(split(text_df, seq(nrow(text_df))), function(row) {
    process_function(row)
  })

  # Process results
  processed_results <- .process_results(results, is_json_output)

  return(processed_results)
}




#' Get or Initialize Local Model
#'
#' This function gets the initialized local model pipeline or initializes it if not already done.
#'
#' @param model_name The name of the model to initialize.
#' @return The initialized local model pipeline.
#' @importFrom reticulate source_python
#' @export
.get_local_model <- function(model_name) {
  if (exists("local_model_pipeline", envir = .GlobalEnv)) {
    return(get("local_model_pipeline", envir = .GlobalEnv))
  } else {
    local_model_pipeline <- reticulate::py$initialize_model(model_name)
    assign("local_model_pipeline", local_model_pipeline, envir = .GlobalEnv)
    return(local_model_pipeline)
  }
}
