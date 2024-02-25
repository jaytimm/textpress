#' Chunk Sentences for NLP
#'
#' This function processes text data for NLP tasks by dividing text into chunks
#' based on sentences or paragraphs, and includes additional context around each chunk.
#'
#' @param df A data.table object containing the text data.
#' @param chunk_level The level at which to chunk the text: "sentence" or "paragraph"
#' @param chunk_size The number of sentences in each chunk.
#' @param context_size The number of sentences around each chunk to include as context.
#' @return A data.table object with chunks of text and their context.
#' @export
#'
#'
rag_build_chunks <- function(df,
                             chunk_level,
                             chunk_size,
                             context_size) {
  # Ensure dt is a data.table
  data.table::setDT(df)

  # If chunk_level is "paragraph", collapse text to paragraph_id and rename to sentence_id
  if (chunk_level == "paragraph") {
    df <- df[, .(text = paste(text, collapse = " ")), by = .(doc_id, paragraph_id)]
    data.table::setnames(df, "paragraph_id", "sentence_id")
  }

  # Create chunk_id based on doc_id and sentence_id
  df[, chunk_id := paste0(doc_id, ".", ceiling(sentence_id / chunk_size))]

  # Compute neighbors for each sentence and filter out-of-bounds neighbors in one step
  neighbors_dt <- df[, .(neighbor_id = c(
    sentence_id - context_size,
    sentence_id,
    sentence_id + context_size
  )),
  by = .(chunk_id, doc_id)
  ]

  neighbors_dt <- unique(neighbors_dt)

  # Aggregate text by chunk_id
  chunk_dt <- df[, .(chunk = paste(text, collapse = " ")), by = .(doc_id, chunk_id)]

  # Join with original dt to aggregate text by neighbors
  dt_neighbors_joined <- df[neighbors_dt, on = .(doc_id, sentence_id = neighbor_id)]

  # Create a grouping variable for consecutive runs of the same value in is_chunk
  dt_neighbors_joined[, is_chunk := ifelse(chunk_id == i.chunk_id, 1, 0)]
  dt_neighbors_joined[, group := data.table::rleid(is_chunk)]

  # Assign row numbers for each consecutive sequence of 1s in is_chunk
  dt_neighbors_joined[is_chunk == 1, id := seq_len(.N), by = group]

  # Handle NA in 'id' column
  dt_neighbors_joined[is.na(id), id := 0]

  # Highlight start and end of each chunk with asterisks
  dt_neighbors_joined[, text := ifelse(id == 1, paste0("<b>", text), text)]
  dt_neighbors_joined[, text := ifelse(id == chunk_size, paste0(text, "</b>"), text)]

  # Create a data table of chunks with context
  chunk_with_context_df <- dt_neighbors_joined[!is.na(text),
                                               .(chunk_plus_context = paste(text, collapse = " ")),
                                               by = .(doc_id, i.chunk_id)
  ]

  # Rename column for clarity
  data.table::setnames(chunk_with_context_df, "i.chunk_id", "chunk_id")

  # Merge chunk and context data
  result_df <- merge(chunk_dt,
                     chunk_with_context_df,
                     by = c("doc_id", "chunk_id"),
                     all.x = TRUE,
                     sort = FALSE
  )

  return(result_df)
}
