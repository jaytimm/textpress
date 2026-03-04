#' Roll units into fixed-size chunks with optional context
#'
#' Roll units (e.g. sentences) into fixed-size chunks with optional context
#' (RAG-style). Groups consecutive rows at the finest \code{by} level into chunks
#' and optionally adds surrounding context.
#'
#' @param corpus Data frame or data.table with a \code{text} column and the identifier columns specified in \code{by}.
#' @param by Character vector of identifier columns that define the text unit (e.g. \code{doc_id} or \code{c("url", "node_id")}). The last column is the level rolled into chunks (e.g. sentences).
#' @param chunk_size Integer. Number of units per chunk.
#' @param context_size Integer. Number of units of context around each chunk.
#' @param id_col Character. Name of the column holding the unique chunk id (default \code{"uid"}).
#' @return Data.table with \code{id_col} (pasted grouping + chunk index), grouping columns from \code{by}, and \code{text} (chunk plus context). Unique on \code{by[1]} and \code{text}.
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
                            context_size,
                            id_col = "uid") {

  corpus <- data.table::copy(data.table::as.data.table(corpus))
  if (!all(by %in% names(corpus))) stop("Missing 'by' columns.", call. = FALSE)
  if (any(duplicated(corpus, by = by))) stop("'by' must uniquely identify rows; found duplicate key combinations.", call. = FALSE)

  chunk_level <- tail(by, 1)
  grouping_vars <- head(by, -1)

  corpus[, chunk_id := do.call(paste, c(.SD, sep = ".")), .SDcols = grouping_vars]
  corpus[, chunk_id := paste0(chunk_id, ".", ceiling(as.integer(get(chunk_level)) / chunk_size)),
     by = grouping_vars]

  neighbors_dt <- corpus[, .(neighbor_id = c(
    as.integer(get(chunk_level)) - context_size,
    as.integer(get(chunk_level)),
    as.integer(get(chunk_level)) + context_size
  )), by = c("chunk_id", grouping_vars)]

  neighbors_dt <- unique(neighbors_dt)
  # Ensure join type matches corpus's chunk_level (often integer from nlp_split_sentences)
  chunk_level_type <- typeof(corpus[[chunk_level]])
  if (chunk_level_type == "character") {
    neighbors_dt[, neighbor_id := as.character(neighbor_id)]
  }
  # else keep neighbor_id as integer for join

  chunk_dt <- corpus[, .(chunk = paste(text, collapse = " ")), by = c(grouping_vars, "chunk_id")]

  corpus_one_per_key <- unique(corpus, by = c(grouping_vars, chunk_level))
  join_on <- c(setNames(grouping_vars, grouping_vars), "neighbor_id" = chunk_level)
  dt_neighbors_joined <- neighbors_dt[corpus_one_per_key, on = join_on, nomatch = 0]

  chunk_with_context_df <- dt_neighbors_joined[,
    .(chunk_plus_context = paste(text[order(neighbor_id)], collapse = " ")),
    by = c(grouping_vars, "chunk_id")]
  result_df <- merge(chunk_dt, chunk_with_context_df, by = c(grouping_vars, "chunk_id"),
                     all.x = TRUE,
                     sort = FALSE)

  result_df[, chunk_id := seq_len(.N), by = grouping_vars]
  result_df[, (id_col) := do.call(paste, c(.SD, sep = "_")), .SDcols = c(grouping_vars, "chunk_id")]
  drop_cols <- c("chunk", "chunk_id")
  result_df[, (drop_cols) := NULL]
  data.table::setnames(result_df, "chunk_plus_context", "text")
  result_df <- unique(result_df, by = c(by[1L], "text"))
  data.table::setcolorder(result_df, c(id_col, setdiff(names(result_df), id_col)))

  return(result_df)
}
