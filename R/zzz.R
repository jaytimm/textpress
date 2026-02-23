utils::globalVariables(c(
  "text", "h1_title", "type", "place", "not_pnode", "has_ellipses",
  "no_stop", "has_latest", "less_10", "has_junk", "discard", "text_id",
  "start", "neighbors", "is_target", "pattern", "end", "i.text_id",
  "pos", "pattern2", "chunk_id", "neighbor_id", "doc_id",
  "paragraph_id", "sentence_id", "unique_id",
  "is_boilerplate", "node_id", "..cols",
  "has_you", "has_quote", "has_qmark", "has_exclam", "has_cta",
  "drop_you_cta", "drop_node_bang",
  "heading_text", "parent_heading",
  "token", "tf", "df", "bm25", "score",
  "paragraph_offset",
  "variant_lc", "variant", "TermName", "ngram", "ngram_lc", "term",
  "match_type", "group", "n",
  "stopwords_en", "idf", "dl", "..final_cols", "..by"
))


utils::globalVariables(c("dummy", "text", "."))


.hollrEnv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Package initialization code (if any)
}

.onAttach <- function(libname, pkgname) {
  # Code to run when the package is attached (if any)
}

# Suppress warnings for global variables
utils::globalVariables(c("id", "annotator_id", "attempts", "success"))
