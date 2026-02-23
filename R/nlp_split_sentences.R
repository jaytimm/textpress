#' Split text into sentences
#'
#' Refine blocks into individual sentences. Splits text into sentences with
#' accurate start/end offsets; handles abbreviations (Wikipedia and web optimized).
#'
#' @param corpus Data frame or data.table with a \code{text} column and the identifier columns specified in \code{by}.
#' @param by Character vector of identifier columns that define the text unit (e.g. \code{doc_id} or \code{c("url", "node_id")}). Default \code{c("doc_id")}.
#' @param abbreviations Character vector of abbreviations to protect (default \code{textpress::abbreviations}).
#' @return Data.table with \code{by} columns, \code{sentence_id}, \code{text}, \code{start}, \code{end}.
#' @export
nlp_split_sentences <- function(corpus,
                                by = c("doc_id"),
                                abbreviations = textpress::abbreviations) {

  if (!all(by %in% names(corpus))) stop("Missing 'by' columns.")

  # 1. Deep copy to avoid shallow-copy warnings and stay thread-safe
  dt <- data.table::as.data.table(data.table::copy(corpus))

  # 2. Regex Definitions for the "Swap Hack"
  # Group 1: Punctuation + optional quotes (use actual Unicode; PCRE does not support \\u)
  # Group 2: Optional Space
  # Group 3: Citation Brackets (handles [1], [1][2], and [13]: 20)
  curly_quotes <- paste0(intToUtf8(0x201C), intToUtf8(0x201D))
  punct_pat    <- paste0("([\\.\\?\\!]+[\\\"\\\'", curly_quotes, "]*)")
  cite_pat     <- "((?:\\[[^\\]]+\\](?:[\\s]*\\:[\\s]*[0-9]+)?)+)"
  space_pat    <- "([\\s]*)"
  abbrev_sub <- gsub("\\.", "_", abbreviations)

  # Transformation Helper
  .transform <- function(x, op = "replace") {
    if (op == "replace") {
      # Move citations BEFORE the period so stringi sees 'period + space'
      x <- gsub(paste0(punct_pat, space_pat, cite_pat), "\\3\\2\\1", x, perl = TRUE)
      # Mask abbreviations
      for (i in seq_along(abbreviations)) {
        x <- gsub(abbreviations[i], abbrev_sub[i], x, fixed = TRUE)
      }
    } else {
      # Unmask abbreviations
      for (i in seq_along(abbrev_sub)) {
        x <- gsub(abbrev_sub[i], abbreviations[i], x, fixed = TRUE)
      }
      # Restore original Wikipedia/Web order
      x <- gsub(paste0(cite_pat, space_pat, punct_pat), "\\3\\2\\1", x, perl = TRUE)
    }
    return(x)
  }

  # 3. Apply transformation
  dt[, text := .transform(text, "replace")]

  # 4. Paragraph Offset Logic
  if ("paragraph_id" %in% names(dt)) {
    dt[, paragraph_offset := cumsum(c(0, nchar(text[-.N]) + 1)), by = by]
  } else {
    dt[, paragraph_offset := 0]
  }

  # 5. Segment into sentences (one text per row; each group may have multiple rows)
  res <- dt[, {
    out <- lapply(seq_len(.N), function(i) {
      t <- text[i]
      bounds <- stringi::stri_locate_all_boundaries(t, type = "sentence")[[1]]
      data.table(
        sentence_raw = stringi::stri_sub(t, bounds[, 1], bounds[, 2]),
        start = bounds[, 1] + paragraph_offset[i],
        end = bounds[, 2] + paragraph_offset[i]
      )
    })
    data.table::rbindlist(out)
  }, by = by]

  # 6. Final Clean-up
  res[, text := .transform(sentence_raw, "revert")]

  # FIX: Generate sentence_id using the 'by' columns dynamically
  res[, sentence_id := as.character(seq_len(.N)), by = by]

  output_cols <- c(by, "sentence_id", "text", "start", "end")
  return(res[, ..output_cols])
}
