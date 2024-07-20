#' Build RSS Feed URL
#'
#' This function constructs an RSS feed URL based on the given query. If no query is provided, it defaults to the top news URL.
#' @param x A string query to search in the RSS feed, defaults to NULL for top news.
#' @return A string containing the URL of the RSS feed.
#' @examples
#' .build_rss() # returns top news RSS feed
#' .build_rss("technology AND innovation") # returns RSS feed for technology and innovation news
#' @noRd
.build_rss <- function(x = NULL) {
  # Define RSS feed URL components
  clang_suffix <- "hl=en-US&gl=US&ceid=US:en&q="
  base <- "https://news.google.com/news/rss/search?"
  tops <- "https://news.google.com/news/rss/?ned=us&hl=en&gl=us"

  # Handle case when no query is provided
  if (is.null(x)) {
    return(tops)
  } else {
    # Process the query for URL encoding
    x <- strsplit(x, " AND ")[[1]]
    y <- unlist(lapply(x, URLencode))
    y1 <- lapply(y, function(q) gsub("(^.*$)", "%22\\1%22", q))

    # Construct the search URL
    search1 <- paste(y1, collapse = "%20AND%20")
    return(paste0(base, clang_suffix, search1))
  }
}


#' Retrieve URLs from a List of Web Pages
#'
#' This function takes a vector of URLs, attempts to retrieve HTML content from each, and extracts specific text elements.
#' @param x A character vector of URLs.
#' @return A character vector with the extracted text from each URL or NA if retrieval fails.
#' @examples
#' urls <- c("http://example.com", "http://example.org")
#' .get_urls(urls)
#' @noRd
.get_urls <- function(x) {
  # Use lapply to process each URL in the vector
  result <- lapply(x, function(encoded_url) {
    # Extract the base64 encoded part from the URL
    pattern <- "https://news.google.com/rss/articles/(.*)\\?oc=5"
    encoded_part <- gsub(pattern, "\\1", encoded_url)

    # Add necessary padding to the base64 string
    encoded_part <- gsub("-", "+", encoded_part)
    encoded_part <- gsub("_", "/", encoded_part)
    encoded_part <- paste0(encoded_part, strrep("=", (4 - nchar(encoded_part) %% 4) %% 4))

    # Decode the base64 string
    decoded_raw <- base64enc::base64decode(encoded_part)

    # Remove any embedded null characters before converting to a character string
    cleaned_raw <- decoded_raw[decoded_raw != as.raw(0)]
    decoded_str <- rawToChar(cleaned_raw)

    # Extract the original URL from the decoded string
    original_url <- stringr::str_extract(decoded_str, "http[s]?://[\\w./?=&-]+")

    return(original_url)
  })

  # Unlist and return the result
  unlist(result)
}



#' Parse RSS Feed
#'
#' This function takes an RSS feed XML content and extracts relevant information such as title, link, publication date, and source.
#' @param x XML content of an RSS feed.
#' @return A data frame containing columns for date, source, title, and link. Returns NA in case of an error.
#' @examples
#' rss_content <- xml2::read_xml("http://example.com/rss")
#' .parse_rss(rss_content)
#' @noRd
.parse_rss <- function(x) {
  # Try to read the XML content, return NA on error
  doc <- tryCatch(
    xml2::read_xml(x),
    error = function(e) {
      return(NA)
    }
  )

  if (is.na(doc)) {
    return(NA)
  } else {
    # Extracting the necessary elements from the XML
    title1 <- xml2::xml_text(xml2::xml_find_all(doc, "//item/title"))
    title <- gsub(" - .*$", "", title1)
    link <- xml2::xml_text(xml2::xml_find_all(doc, "//item/link"))
    pubDate <- xml2::xml_text(xml2::xml_find_all(doc, "//item/pubDate"))

    source1 <- sub("^.* - ", "", title1)
    source2 <- xml2::xml_text(xml2::xml_find_all(doc, "//channel/title"))

    # Determine the source based on the XML structure
    source <- if (grepl("Google News", source2)) source1 else source2

    # Formatting the publication date
    date <- gsub("^.+, ", "", pubDate)
    date <- gsub(" [0-9]*:.+$", "", date)
    date <- as.Date(date, "%d %b %Y")

    # Returning the results as a data frame
    data.frame(date, source, title, link)
  }
}



#' Validate JSON String
#'
#' This function checks if a given string is a valid JSON.
#'
#' @param json_string The string to validate.
#' @return TRUE if the string is valid JSON, FALSE otherwise.
#' @importFrom jsonlite fromJSON
#' @export
.is_valid_json <- function(json_string) {
  tryCatch({ jsonlite::fromJSON(json_string); TRUE }, error = function(e) { FALSE })
}




#' Generate Random IDs
#'
#' This function generates a specified number of random IDs.
#'
#' @param n The number of IDs to generate.
#' @return A vector of random IDs.
#' @export
.generate_random_ids <- function(n) {
  replicate(n, paste0(sample(c(0:9, letters, LETTERS), 10, replace = TRUE), collapse = ""))
}



#' Process Results from LLM Completions
#'
#' This internal function processes the results from LLM completions,
#' ensuring consistent structure and output.
#'
#' @param results A list of results to be processed.
#' @param is_json_output A logical indicating whether the output should be JSON.
#' @return A data.table containing the processed results.
#' @import data.table
.process_results <- function(results, is_json_output) {
  processed_list <- lapply(results, function(element) {
    # Initialize an empty list for the response
    response_list <- list()

    # Check if JSON output is expected and the response is a character
    if (is_json_output && is.character(element$response)) {
      response_list <- tryCatch({
        jsonlite::fromJSON(element$response)  # Directly return the parsed JSON
      }, error = function(e) {
        list(raw_output = element$response)  # Return the raw response as raw_output if error
      })
    } else {
      # Directly assign the response to 'raw_output' key if JSON is not required
      response_list$raw_output <- element$response
    }

    # Convert the list to a data table
    response_df <- data.table::as.data.table(response_list)

    # Assign metadata
    response_df[, id := element$id]
    response_df[, annotator_id := element$annotator_id]
    response_df[, attempts := element$attempts]
    response_df[, success := element$success]

    return(response_df)
  })

  # Combine all data tables into a single data table and ensure id is the first column
  df <- data.table::rbindlist(processed_list, fill = TRUE)
  data.table::setcolorder(df, c("id", "annotator_id", "attempts", "success", names(df)[!(names(df) %in% c("id", "annotator_id", "attempts", "success"))]))

  return(df)
}



#' Validate JSON Output and Track Metrics
#'
#' This function validates the JSON output and attempts to regenerate if the output is invalid.
#' It also tracks the number of attempts required for successful JSON validation.
#'
#' @param make_call A function that makes the API call or generates the output.
#' @param is_json_output A logical indicating whether the output should be JSON.
#' @param max_attempts The maximum number of attempts to make for generating valid output.
#' @return A list containing the validated JSON output (or NA if validation fails) and the number of attempts.
#' @importFrom jsonlite fromJSON
#' @importFrom httr content

.validate_json_output <- function(make_call,
                                  is_json_output,
                                  max_attempts) {
  attempt <- 1  # Initialize the attempt counter

  while (attempt <= max_attempts) {
    output <- make_call()  # Call the make_call function to get output

    if (is_json_output) {  # Check if JSON output is expected
      if (.is_valid_json(output)) {
        return(list(response = output,
                    attempts = attempt,
                    success = TRUE))
      } else {
        cat("Attempt ", attempt, ": Invalid JSON received. Regenerating...\n")
        attempt <- attempt + 1  # Increment attempt only if JSON is invalid
      }
    } else {
      # If JSON output is not expected, return success without incrementing the attempt counter
      return(list(response = output,
                  attempts = attempt,
                  success = TRUE))
    }
  }

  # After exhausting all attempts without success
  cat("Failed to receive valid JSON after ", max_attempts, " attempts. Carrying on ...\n")
  return(list(response = output,
              attempts = max_attempts,
              success = FALSE))
}




