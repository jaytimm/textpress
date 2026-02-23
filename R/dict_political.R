#' Demo dictionary of political / partisan term variants for NER
#'
#' A small dictionary of political party and ideology terms (Democrat, Republican,
#' MAGA, Liberal, Conservative, Christian Nationalist, White Supremacist, etc.)
#' and spelling/variant forms, for use with \code{\link{search_dict}}. Built in-package (no \code{data()}).
#'
#' @format A data frame with columns \code{variant} (surface form to match) and \code{TermName} (standardized label).
#' @export
#' @examples
#' head(dict_political)
#' # search_dict(corpus, by = "doc_id", terms = dict_political$variant)
dict_political <- local({
  d <- data.frame(
    variant = c(
      "Democrat", "Democrats", "Democratic", "Democratic Party", "Dem", "Dems",
      "Blue", "Donkey Party", "DNC",
      "Republican", "Republicans", "Republican Party", "GOP", "Grand Old Party",
      "Red", "Elephant Party", "RNC",
      "Tea Party", "Tea Partier", "Tea Partiers",
      "MAGA", "Make America Great Again", "America First", "Trumpist", "Trumpists",
      "Trumpian", "Trumpism", "MAGA Republican",
      "Independent", "Independents", "Unaffiliated", "No party preference", "NPA",
      "Libertarian", "Libertarians", "Libertarian Party",
      "Green Party", "Greens", "The Green Party",
      "Liberal", "Liberals", "Left-leaning", "Left leaning", "Left of center",
      "Conservative", "Conservatives", "Right-leaning", "Right leaning", "Right of center",
      "Progressive", "Progressives", "The Squad", "Squad",
      "Moderate", "Moderates", "Centrist", "Centrists", "Center",
      "Left", "The Left", "Far Left", "Hard Left", "Radical Left",
      "Right", "The Right", "Far Right", "Hard Right", "Radical Right",
      "Neocon", "Neocons", "Neoconservative", "Neoconservatives",
      "Neoliberal", "Neoliberals", "Neoliberalism", "Neo-liberal",
      "Populist", "Populists", "Populism",
      "Nationalist", "Nationalists", "Nationalism",
      "RINO", "RINOs", "Republican in Name Only",
      "DINO", "DINOs", "Democrat in Name Only",
      "Blue Dog", "Blue Dogs", "Blue Dog Democrat", "Blue Dog Democrats",
      "Never Trump", "Never Trumper", "Never Trumpers", "Never-Trump",
      "Christian Nationalist", "Christian Nationalists", "Christian Nationalism",
      "Christofascist", "Christofascism", "Christian Right",
      "The Christian Right", "Religious Right", "Theocrat",
      "Theocracy movement",
      "White Supremacist", "White Supremacists", "White Supremacy",
      "White Nationalist", "White Nationalists", "White Nationalism",
      "White Identitarian", "White Identitarianism", "White Separatist"
    ),
    TermName = c(
      rep("Democrat", 9), rep("Republican", 11), rep("MAGA", 8),
      rep("Independent", 5), rep("Libertarian", 3), rep("Green", 3),
      rep("Liberal", 5), rep("Conservative", 5), rep("Progressive", 4),
      rep("Moderate", 5), rep("Left", 5), rep("Right", 5),
      rep("Neocon", 4), rep("Neoliberal", 4), rep("Populist", 3),
      rep("Nationalist", 3), rep("RINO", 3), rep("DINO", 3),
      rep("Blue Dog", 4), rep("Never Trump", 4),
      rep("Christian Nationalist", 10), rep("White Supremacist", 9)
    ),
    stringsAsFactors = FALSE
  )
  d
})
