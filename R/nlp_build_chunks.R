#' Build Chunks for NLP Analysis
#'
#' This function processes a data frame for NLP analysis by dividing text into chunks and providing context.
#' It generates chunks of text with a specified size and includes context based on the specified context size.
#'
#' @param tif A data.table containing the text to be chunked.
#' @param chunk_size An integer specifying the size of each chunk.
#' @param context_size An integer specifying the size of the context around each chunk.
#' @param text_hierarchy A character vector specifying the columns used for grouping and chunking.
#' @return A data.table with the chunked text and their respective contexts.
#' @import data.table
#' @export
#'
nlp_build_chunks <- function(tif,
                             text_hierarchy,
                             chunk_size,
                             context_size) {

  # Convert input to data.table if not already
  data.table::setDT(tif)

  # Check uniqueness of BY columns

  # Determine the chunk level and grouping variables
  chunk_level <- tail(text_hierarchy, 1)
  grouping_vars <- head(text_hierarchy, -1)

  # Create a unique identifier for each chunk
  tif[, chunk_id := do.call(paste, c(.SD, sep = ".")), .SDcols = grouping_vars]
  tif[, chunk_id := paste0(chunk_id, ".", ceiling(get(chunk_level) |> as.integer() / chunk_size)),
     by = grouping_vars]

  # Generate neighbor ids for context
  neighbors_dt <- tif[, .(neighbor_id = c(
    get(chunk_level) |> as.integer() - context_size,
    get(chunk_level) |> as.integer(),
    get(chunk_level) |> as.integer() + context_size
  )), by = c("chunk_id", grouping_vars)]

  # Remove duplicate neighbors
  neighbors_dt <- unique(neighbors_dt)
  neighbors_dt[, neighbor_id := as.character(neighbor_id)]

  # Aggregate text into chunks
  chunk_dt <- tif[, .(chunk = paste(text, collapse = " ")), by = c(grouping_vars, "chunk_id")]

  # Prepare conditions for joining with neighbor data
  join_conditions <- setNames(rep(names(tif)[names(tif) %in% grouping_vars], 1), grouping_vars)
  join_conditions[chunk_level] <- "neighbor_id"

  # Join df with neighbors to get context
  dt_neighbors_joined <- tif[neighbors_dt, on = join_conditions]

  # Combine chunk text with context
  chunk_with_context_df <- dt_neighbors_joined[!is.na(text),
                                               .(chunk_plus_context = paste(text, collapse = " ")),
                                               by = c(grouping_vars, "i.chunk_id")]

  # Rename and merge data.tables for final output
  data.table::setnames(chunk_with_context_df, "i.chunk_id", "chunk_id")
  result_df <- merge(chunk_dt, chunk_with_context_df, by = c(grouping_vars, "chunk_id"),
                     all.x = TRUE,
                     sort = FALSE)

  return(result_df)
}
