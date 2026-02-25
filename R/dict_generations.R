#' Demo dictionary of generation-name variants for NER
#'
#' A small dictionary of generational cohort terms (Greatest, Silent, Boomers,
#' Gen X, Millennials, Gen Z, Alpha, etc.) and spelling/variant forms, for use
#' with \code{\link{search_dict}}. Built in-package (no \code{data()}).
#'
#' @format A data frame with columns \code{variant} (surface form to match), \code{TermName} (standardized label), \code{is_cusp} (logical), \code{start} and \code{end} (birth year range; Pew definitions where applicable, see \url{https://github.com/jaytimm/AmericanGenerations/blob/main/data/pew-generations.csv}).
#' @export
#' @examples
#' head(dict_generations)
#' # use as term list: search_dict(corpus, by = "doc_id", terms = dict_generations$variant)
dict_generations <- local({
  d <- data.frame(
    variant = c(
      "Greatest Generation", "GI Generation", "G.I. Generation",
      "WWII Generation", "World War II Generation", "Depression Era Generation",
      "Silent Generation", "Radio Generation", "The Silent Generation",
      "Baby Boomers", "Baby-Boomers", "Boomers", "Boomer",
      "Baby Boom Generation", "Post-War Generation",
      "Generation Jones", "Gen Jones", "Jones Generation", "Late Boomers",
      "Generation X", "Gen X", "Gen-X", "GenX",
      "Gen Xers", "Gen X-ers", "Gen Xer", "Gen X-er",
      "Latchkey Generation", "Latchkey Kids", "MTV Generation",
      "Baby Busters", "Middle Child Generation",
      "Xennials", "X-ennials", "Oregon Trail Generation",
      "Millennials", "Millennial", "Millenials", "Millenial",
      "Generation Y", "Gen Y", "Gen Yers", "Gen Y-ers", "Gen Yer", "Gen Y-er",
      "Echo Boomers", "Trophy Generation", "Boomerang Generation", "Peter Pan Generation",
      "Zillennials", "Zillenials", "Zillennial", "Cuspers",
      "Generation Z", "Gen Z", "Gen-Z", "GenZ", "Zoomers", "Zoomer",
      "iGeneration", "iGen", "Post-Millennials", "Homeland Generation",
      "Gen Zers", "Gen Z-ers", "Gen Zer", "Gen Z-er",
      "Generation Alpha", "Gen Alpha", "Generation A", "Gen A"
    ),
    TermName = c(
      rep("Greatest", 6), rep("Silent", 3), rep("Boomers", 6),
      rep("Generation Jones", 4), rep("Gen X", 13), rep("Xennials", 3),
      rep("Millennial", 14), rep("Zillennials", 4), rep("Gen Z", 14),
      rep("Alpha", 4)
    ),
    stringsAsFactors = FALSE
  )
  # Cusp = between two generations (Jones, Xennials, Zillennials)
  d$is_cusp <- d$TermName %in% c("Generation Jones", "Xennials", "Zillennials")
  # Birth year ranges: Pew (Greatest–Gen Z, Post-Z) + cusp ranges
  # https://github.com/jaytimm/AmericanGenerations/blob/main/data/pew-generations.csv
  pew <- data.frame(
    TermName = c("Greatest", "Silent", "Boomers", "Generation Jones", "Gen X", "Xennials", "Millennial", "Zillennials", "Gen Z", "Alpha"),
    start = c(1901L, 1928L, 1946L, 1954L, 1965L, 1977L, 1981L, 1993L, 1997L, 2013L),
    end   = c(1927L, 1945L, 1964L, 1965L, 1980L, 1985L, 1996L, 1998L, 2012L, 2028L),
    stringsAsFactors = FALSE
  )
  d$._ord <- seq_len(nrow(d))
  d <- merge(d, pew, by = "TermName", sort = FALSE)
  d <- d[order(d$._ord), ]
  d$._ord <- NULL
  d
})
