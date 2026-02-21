#' Search a text corpus for patterns (regex), with optional KWIC-style context.
#'
#' Searches a text corpus for specified patterns, with support for parallel processing.
#'
#' @param corpus A data frame or data.table with \code{text} and id columns given in \code{by}.
#' @param by Character vector of columns defining text units (e.g. \code{c("doc_id", "sentence_id")}).
#' @param search The search pattern or query (regex; multiple patterns as vector are OR'd).
#' @param context_size Numeric, default 0. Context size in sentences around matches.
#' @param highlight Length-two character vector for match highlighting (default \code{c('<b>', '</b>')}).
#' @param cores Numeric, default 1. Number of cores for parallel processing.
#' @return A data.table with \code{by} columns, \code{text}, \code{start}, \code{end}, \code{pattern}.
#' @export
#' @examples
#' corpus <- data.frame(doc_id = c('1', '1', '2'),
#'                     sentence_id = c('1', '2', '1'),
#'                     text = c("Hello world.",
#'                              "This is an example.",
#'                              "This is a party!"))
#' search_corpus(corpus, search = 'This is', by = c('doc_id', 'sentence_id'))
search_corpus <- function(corpus,
                          by = c('doc_id', 'paragraph_id', 'sentence_id'),
                          search,
                          context_size = 0,
                          highlight = c("<b>", "</b>"),
                          cores = 1) {
  if (cores == 1) {
    return(.search_corpus(
      corpus = corpus,
      search = search,
      context_size = context_size,
      by = by,
      highlight = highlight
    ))
  } else {
    batches <- split(corpus, ceiling(seq(1, nrow(corpus)) / 300))
    clust <- parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(clust))
    parallel::clusterExport(cl = clust, varlist = c(".search_corpus"), envir = environment())
    search_fun <- function(batch) {
      .search_corpus(batch, search, by, context_size, highlight)
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




#' @noRd
.search_corpus <- function(corpus,
                           search,
                           by,
                           context_size,
                           highlight) {
  LL <- gsub("([][{}()+*^$.|\\\\?])", "\\\\\\1", highlight[1])
  RR <- gsub("([][{}()+*^$.|\\\\?])", "\\\\\\1", highlight[2])

  data.table::setDT(corpus)

  if (length(by) == 1) {
    by <- c('dummy', by)
    corpus[, dummy := '1']
  }

  search_level <- tail(by, 1)
  grouping_vars <- head(by, -1)

  term1 <- paste0("(?i)", search)
  term2 <- paste0(term1, collapse = "|")

  corpus[, text_id := do.call(paste, c(.SD, list(sep = "."))), .SDcols = by]

  found <- stringi::stri_locate_all(corpus$text, regex = term2)
  names(found) <- corpus$text_id
  found1 <- lapply(found, data.frame)
  df1 <- data.table::rbindlist(found1, idcol = "text_id", use.names = FALSE)
  df1 <- subset(df1, !is.na(start))

  if (nrow(df1) == 0) {
    return(data.table::data.table(
      doc_id = character(),
      sentence_id = character(),
      text = character(),
      start = integer(),
      end = integer(),
      pattern = character()
    ))
  } else {

      df1[, (by) := data.table::tstrsplit(text_id, "\\.")]

      generate_neighbors <- function(x, n) {
        seq(max(1, x - n), x + n)
      }

      df1$neighbors <- lapply(as.numeric(df1[[search_level]]),
                              generate_neighbors,
                              n = context_size)

      df3 <- df1[, setNames(list(unlist(neighbors)), search_level),
                 by = c("text_id", grouping_vars, "start", "end")]

      df3[, is_target := ifelse(text_id == do.call(paste, c(.SD, sep = ".")), 1, 0), .SDcols = by]
      df3[, (by) := lapply(.SD, as.character), .SDcols = by]

      join_columns <- setNames(by, by)
      df4 <- corpus[df3, on = join_columns, nomatch = 0]

      df4[, pattern := ifelse(is_target == 1, stringi::stri_sub(text, start, end), "")]
      df4[, text := ifelse(is_target == 1, .insert_highlight(text, start, end, highlight = highlight), text)]

      df5 <- df4[, list(text = paste(text, collapse = " ")),
                 by = list(i.text_id, start, end)
      ]

      df5[, (by) := data.table::tstrsplit(i.text_id, "\\.")]

      patsy <- paste0(".*", LL, "(.*)", RR, ".*")
      df5[, pattern := gsub(patsy, "\\1", text)]

      df5[, c(setdiff(by, 'dummy'), "text", "start", "end", "pattern"), with = FALSE]
  }
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
#' @noRd
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
