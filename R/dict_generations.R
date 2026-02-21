#' Demo dictionary of generation-name variants for NER
#'
#' A small dictionary of generational cohort terms (Greatest, Silent, Boomers,
#' Gen X, Millennials, Gen Z, Alpha, etc.) and spelling/variant forms, for use
#' with \code{\link{search_dict}}. All entries are global (no \code{doc_id}).
#' Built in-package (no \code{data()}).
#'
#' @format A data frame with columns \code{variant} (surface form to match),
#'   \code{TermName} (standardized label), and \code{doc_id} (NA for global).
#' @export
#' @examples
#' head(dict_generations)
#' # use as default in NER
#' # search_dict(corpus, by = "doc_id", dictionary = dict_generations)
dict_generations <- local({
  d <- data.frame(
    variant = c(
      "Greatest Generation", "GI Generation", "G.I. Generation",
      "WWII Generation", "World War II Generation", "Depression Era Generation",
      "Silent Generation", "Radio Generation", "Forgotten Generation", "The Silent Generation",
      "Baby Boomers", "Baby-Boomers", "Boomers", "Boomer",
      "Baby Boom Generation", "Post-War Generation",
      "Generation Jones", "Gen Jones", "The Jones Generation", "Late Boomers",
      "Generation X", "Gen X", "Gen-X", "GenX",
      "Latchkey Generation", "Latchkey Kids", "MTV Generation",
      "Baby Busters", "Middle Child Generation",
      "Xennials", "X-ennials", "Oregon Trail Generation",
      "Millennials", "Millennial", "Millenials", "Millenial",
      "Generation Y", "Gen Y", "Echo Boomers",
      "Trophy Generation", "Boomerang Generation", "Peter Pan Generation",
      "Zillennials", "Zillenials", "Zillennial", "Cuspers",
      "Generation Z", "Gen Z", "Gen-Z", "GenZ", "Zoomers", "Zoomer",
      "iGeneration", "iGen", "Post-Millennials", "Homeland Generation",
      "Gen Zers", "Gen Z-ers", "Gen Zer", "Gen Z-er",
      "Generation Alpha", "Gen Alpha", "Generation A", "Gen A"
    ),
    TermName = c(
      rep("Greatest", 6), rep("Silent", 4), rep("Boomers", 6),
      rep("Generation Jones", 4), rep("Gen X", 9), rep("Xennials", 3),
      rep("Millennial", 10), rep("Zillennials", 4), rep("Gen Z", 14),
      rep("Alpha", 4)
    ),
    stringsAsFactors = FALSE
  )
  d$doc_id <- NA_character_
  d
})
