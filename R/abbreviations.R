#' Common Abbreviations for Sentence Splitting
#'
#' A character vector of common abbreviations used in English.
#' These abbreviations are used to assist in sentence splitting,
#' ensuring that sentence boundaries are not incorrectly identified
#' at these abbreviations.
#'
#' @format A character vector with some common English abbreviations.
#' @source Developed internally for sentence splitting functionality.
#' @export
abbreviations <- c(
  "\\b[A-Z]\\.",
  "No.",
  "St.",
  "U.S.A.",
  "Mr.",
  "Mrs.",
  "Ms.",
  "Dr.",
  "Prof.",
  "Sr.",
  "Jr.",
  "Sen.",
  "U.S.",
  "Rep.",
  "Sen.",
  "Gov.",
  "Jan.",
  "Feb.",
  "Mar.",
  "Apr.",
  "Aug.",
  "Sep.",
  "Oct.",
  "Nov.",
  "Dec."
)
