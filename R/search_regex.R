#' Search corpus via regex
#'
#' @param corpus A data frame or data.table with a \code{text} column.
#' @param query The search pattern (regex).
#' @param by Character vector of identifier columns.
#' @param highlight Length-two character vector (default \code{c('<b>', '</b>')}).
#' @export
search_regex <- function(corpus,
                         query,
                         by,
                         highlight = c("<b>", "</b>")) {

  # 1. Setup Data & Clean Existing Coordinates
  # We copy to avoid modifying the user's object by reference.
  results_dt <- data.table::as.data.table(data.table::copy(corpus))

  # Remove old start/end columns to avoid name collisions with new search hits
  drop_cols <- intersect(names(results_dt), c("start", "end"))
  if(length(drop_cols) > 0) results_dt[, (drop_cols) := NULL]

  # 2. Locate Hits Locally
  # Calculates coordinates relative to the text in each row
  locs <- stringi::stri_locate_all_regex(results_dt$text,
                                         query,
                                         omit_no_match = TRUE)

  # 3. Handle Multi-Hit Expansion
  # Count hits per row to expand the table correctly
  hit_counts <- vapply(locs, function(x) if(is.matrix(x)) nrow(x) else 0L, integer(1))

  if (sum(hit_counts) == 0) return(NULL)

  # Expand the corpus rows to match the number of hits
  results <- results_dt[rep(seq_len(.N), hit_counts)]

  # Bind the NEW local coordinates for the search hits
  coords <- data.table::as.data.table(do.call(rbind, locs))
  data.table::setnames(coords, c("start", "end"))
  results <- data.table::as.data.table(cbind(results, coords))

  # 4. Extract Pattern and Highlight
  # Extract the specific slice of text that triggered the match
  results[, pattern := substr(text, start, end)]

  # Apply visual highlighting
  results[, text := mapply(.insert_highlight,
                            text,
                            start,
                            end,
                            MoreArgs = list(highlight = highlight))]

  # 5. Generate Simple Identifiers (No Padding)
  # Pastes identifiers exactly as provided by the user
  results[, id := do.call(paste, c(.SD, sep = ".")), .SDcols = by]

  # 6. Final Formatting
  # Return only the essential columns in a standardized order
  final_cols <- c("id", by, "text", "start", "end", "pattern")
  return(results[, ..final_cols])
}

#' @noRd
.insert_highlight <- function(text, start, end, highlight) {
  if (is.na(start) || is.na(end)) return(text)
  paste0(
    substr(text, 1, start - 1),
    highlight[1],
    substr(text, start, end),
    highlight[2],
    substr(text, end + 1, nchar(text))
  )
}
