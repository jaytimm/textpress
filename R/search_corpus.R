#' NLP Search Corpus
#'
#' Searches a text corpus for specified patterns, with support for parallel processing.
#'
#' @param tif A data frame or data.table containing the text corpus.
#' @param search The search pattern or query.
#' @param n Numeric, default 0. Specifies the context size around the found patterns.
#' @param is_inline Logical, default FALSE. Indicates if the search should be inline.
#' @param highlight A character vector of length two, default c('<b>', '</b>').
#'                  Used to highlight the found patterns in the text.
#' @param cores Numeric, default 1. The number of cores to use for parallel processing.
#' @return A data.table with the search results.
#' @importFrom data.table rbindlist setDT
#' @importFrom parallel makeCluster stopCluster clusterExport
#' @importFrom pbapply pblapply
#' @importFrom stringi stri_locate_all stri_sub
#' @export
#'
#'
search_corpus <- function(tif,
                          search,
                          n = 0,
                          is_inline = FALSE,
                          highlight = c("<b>", "</b>"),
                          cores = 1) {
  # If only one core is used, run the non-parallel version of the function
  if (cores == 1) {
    return(.search_corpus(
      tif,
      search,
      n,
      is_inline,
      highlight
    ))
  } else {
    # Split the dataframe into batches
    batches <- split(tif, ceiling(seq(1, nrow(tif)) / 300))

    # Set up a parallel cluster
    clust <- parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(clust)) # Ensure cluster is stopped when the function exits

    # Export the nlp_search_corpus function to each worker
    parallel::clusterExport(
      cl = clust,
      varlist = c(".search_corpus"),
      envir = environment()
    )

    # Create a function to pass additional parameters to nlp_search_corpus
    search_fun <- function(batch) {
      .search_corpus(
        batch,
        search,
        n,
        is_inline,
        highlight
      )
    }


    # Execute the task function in parallel
    results <- pbapply::pblapply(
      X = batches,
      FUN = search_fun,
      cl = clust
    )

    # Combine the results
    combined_results <- data.table::rbindlist(results)
    combined_results
  }
}


#' @keywords internal
.search_corpus <- function(tif, search, n, is_inline, highlight) {
  # Escaping regex special characters in highlight markers
  LL <- gsub("([][{}()+*^$.|\\\\?])", "\\\\\\1", highlight[1])
  RR <- gsub("([][{}()+*^$.|\\\\?])", "\\\\\\1", highlight[2])

  # Converting input data to data.table if not already
  data.table::setDT(tif)

  # Prepare search term based on inline flag
  if (is_inline) {
    # For inline searches, translate the query for regex matching
    term2 <- .translate_query(search) |> trimws()
  } else {
    # For standard searches, construct a case-insensitive regex pattern
    term1 <- paste0("(?i)", search)
    term2 <- paste0(term1, collapse = "|")
  }

  # Create a unique identifier for each text entry
  tif[, text_id := paste0(doc_id, ".", sentence_id)]
  tif[, sentence_id := as.integer(sentence_id)]

  # Locate all occurrences of the search pattern in each text entry
  found <- stringi::stri_locate_all(tif$text, regex = term2)

  # Assigning names to the found locations based on text identifiers
  names(found) <- tif$text_id
  found1 <- lapply(found, data.frame)
  df1 <- data.table::rbindlist(found1, idcol = "text_id", use.names = FALSE)
  df1 <- subset(df1, !is.na(start))
  df1[, c("doc_id", "sentence_id") := data.table::tstrsplit(text_id, "\\.")]

  # Determine neighboring text entries to include as context
  df1[, neighbors := lapply(
    as.integer(sentence_id),
    function(x) list(c((x - n):(x + n)))
  )]
  df3 <- df1[, .(sentence_id = unlist(neighbors)),
    by = list(text_id, doc_id, start, end)
  ]
  df3[, is_target := ifelse(text_id == paste0(doc_id, ".", sentence_id), 1, 0)]

  # Join the context sentences with the main dataframe
  df4 <- tif[df3, on = c("doc_id", "sentence_id"), nomatch = 0]

  # Insert highlight tags around the found patterns
  df4[, pattern := ifelse(is_target == 1, stringi::stri_sub(text, start, end), "")]
  df4[, text := ifelse(is_target == 1, .insert_highlight(text, start, end, highlight = highlight), text)]

  # Combine text entries to form the context around each found pattern
  df5 <- df4[, list(text = paste(text, collapse = " ")),
    by = list(i.text_id, start, end)
  ]

  # Extract document and sentence identifiers
  df5[, c("doc_id", "sentence_id") := data.table::tstrsplit(i.text_id, "\\.")]

  # Extract and clean the found pattern from the highlighted text
  patsy <- paste0(".*", LL, "(.*)", RR, ".*")
  df5[, pattern := gsub(patsy, "\\1", text)]

  # Additional processing for inline queries
  if (is_inline) {
    df5[, pos := gsub("\\S+/(\\S+)/\\S+", "\\1", pattern) |> trimws()]
    df5[, pattern2 := gsub("(\\S+)/\\S+/\\S+", "\\1", pattern) |> trimws()]
  } else {
    df5[, pos := NA]
    df5[, pattern2 := NA]
  }

  # Return the final dataframe with relevant columns
  df5[, c("doc_id", "sentence_id", "text", "start", "end", "pattern", "pattern2", "pos"), with = FALSE]
}





#' Translate Search Query
#'
#' Translates a search query into a format suitable for regex matching,
#' particularly for inline searches.
#'
#' @param x The search query string to be translated.
#' @return A character string representing the translated query.
#' @keywords internal

.translate_query <- function(x) {
  # Splitting the query into individual words
  q <- unlist(strsplit(x, " "))

  # Process each word in the query
  y0 <- lapply(q, function(x) {
    # Check if the word is in uppercase (indicating a specific POS tag)
    if (x == toupper(x)) {
      # For uppercase words, translate to a pattern that matches POS tags
      gsub("([A-Z_]+)", "\\\\S+/\\1/[0-9]+ ", x)
    } else {
      # For other words, create a pattern that matches any POS tag
      paste0(x, "/\\S+/[0-9]+ ")
    }
  })

  # Clean up the resulting patterns to remove any redundant parts
  y0 <- gsub("(^.*/[A-Z]*/)(\\S+/)(.*$)", "\\1\\3", y0)

  # Combine the individual word patterns into a single string
  paste0(y0, collapse = "")
}



#' Insert Highlight in Text
#'
#' Inserts highlight markers around a specified substring in a text string.
#' Used to visually emphasize search query matches in the text.
#'
#' @param text The text string where highlighting is to be applied.
#' @param start The starting position of the substring to highlight.
#' @param end The ending position of the substring to highlight.
#' @param highlight A character vector of length two specifying the
#'                  opening and closing highlight markers.
#' @return A character string with the specified substring highlighted.
#' @keywords internal
#'
.insert_highlight <- function(text,
                              start,
                              end,
                              highlight) {
  # Extract the substring of the text before the highlight start position
  before_term <- substr(text, 1, start - 1)

  # Extract the substring to be highlighted
  term <- substr(text, start, end)

  # Extract the substring of the text after the highlight end position
  after_term <- substr(text, end + 1, nchar(text))

  # Reconstruct the text with highlight markers inserted around the term
  paste0(before_term, highlight[1], term, highlight[2], after_term)
}
