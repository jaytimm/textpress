#' Common abbreviations for NLP
#'
#' Common abbreviations for NLP (e.g. sentence splitting). Named list; used by
#' \code{\link{nlp_split_sentences}}.
#'
#' @format A named list with the following components:
#' \describe{
#'   \item{\code{abbreviations}}{A character vector of common abbreviations, including titles, months, and standard abbreviations.}
#' }
#' @source Internally compiled linguistic resource.
#' @export

abbreviations = c(
  "\\b[A-Z]\\.",
  'i.e.',
  'D.C.',
  "vs.",
  "Fig.",
  "No.",
  "Inc.",
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
  "Dec.",
  "Reps."
)
