#' Roll units into fixed-size chunks with optional context
#'
#' Groups consecutive rows at the finest \code{by} level (e.g. sentences) into
#' fixed-size chunks and optionally adds surrounding context. Like a rolling
#' window over the leaf units.
#'
#' @param corpus A data frame or data.table containing a \code{text} column and the identifiers specified in \code{by}.
#' @param by A character vector of column names used as unique identifiers.
#'   The last column determines the search unit and is the level rolled into chunks (e.g., if \code{by = c("doc_id", "sentence_id")}, sentences are rolled into chunks).
#' @param chunk_size Integer. Number of units per chunk.
#' @param context_size Integer. Number of units of context around each chunk.
#' @return A data.table with \code{chunk_id}, \code{chunk} (concatenated text), and \code{chunk_plus_context}.
#' @export
#' @examples
#' corpus <- data.frame(doc_id = c('1', '1', '2'),
#'                     sentence_id = c('1', '2', '1'),
#'                     text = c("Hello world.",
#'                              "This is an example.",
#'                              "This is a party!"))
#' chunks <- nlp_roll_chunks(corpus, by = c('doc_id', 'sentence_id'),
#'                           chunk_size = 2, context_size = 1)

nlp_roll_chunks <- function(corpus,
                             by,
                             chunk_size,
                             context_size) {

  data.table::setDT(corpus)

  chunk_level <- tail(by, 1)
  grouping_vars <- head(by, -1)

  corpus[, chunk_id := do.call(paste, c(.SD, sep = ".")), .SDcols = grouping_vars]
  corpus[, chunk_id := paste0(chunk_id, ".", ceiling(get(chunk_level) |> as.integer() / chunk_size)),
     by = grouping_vars]

  neighbors_dt <- corpus[, .(neighbor_id = c(
    get(chunk_level) |> as.integer() - context_size,
    get(chunk_level) |> as.integer(),
    get(chunk_level) |> as.integer() + context_size
  )), by = c("chunk_id", grouping_vars)]

  neighbors_dt <- unique(neighbors_dt)
  neighbors_dt[, neighbor_id := as.character(neighbor_id)]

  chunk_dt <- corpus[, .(chunk = paste(text, collapse = " ")), by = c(grouping_vars, "chunk_id")]

  join_conditions <- setNames(rep(names(corpus)[names(corpus) %in% grouping_vars], 1), grouping_vars)
  join_conditions[chunk_level] <- "neighbor_id"

  dt_neighbors_joined <- corpus[neighbors_dt, on = join_conditions]

  chunk_with_context_df <- dt_neighbors_joined[!is.na(text),
                                               .(chunk_plus_context = paste(text, collapse = " ")),
                                               by = c(grouping_vars, "i.chunk_id")]

  data.table::setnames(chunk_with_context_df, "i.chunk_id", "chunk_id")
  result_df <- merge(chunk_dt, chunk_with_context_df, by = c(grouping_vars, "chunk_id"),
                     all.x = TRUE,
                     sort = FALSE)

  result_df[, chunk_id := seq_len(.N), by = grouping_vars]

  return(result_df)
}
