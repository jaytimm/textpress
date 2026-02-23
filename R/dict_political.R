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
      "Democrat", "Democrats", "Democratic", "Democratic Party", "Democrat Party", "Dem", "Dems",
      "DNC",
      "Republican", "Republicans", "Republican Party", "GOP", "Grand Old Party",
      "RNC",
      "Tea Party", "Tea Partier", "Tea Partiers",
      "MAGA", "Make America Great Again", "America First", "Trumpist", "Trumpists",
      "Trumpian", "Trumpism", "MAGA Republican",
      "Independent", "Independents", "No party preference",
      "Libertarian", "Libertarians", "Libertarian Party",
      "Green Party", "Greens", "The Green Party",
      "Liberal", "Liberals", "Left-leaning", "Left leaning", "Left of center",
      "Conservative", "Conservatives", "Right-leaning", "Right leaning", "Right of center",
      "Progressive", "Progressives",
      "Democratic Socialist", "Democratic Socialists",
      "Moderate", "Moderates", "Centrist", "Centrists", "Center",
      "Far Left", "Hard Left", "Radical Left",
      "Right", "The Right", "Far Right", "Hard Right", "Radical Right",
      "Neocon", "Neocons", "Neoconservative", "Neoconservatives",
      "Neoliberal", "Neoliberals", "Neoliberalism", "Neo-liberal",
      "Populist", "Populists", "Populism",
      "Nationalist", "Nationalists", "Nationalism",
      "RINO", "RINOs", "Republican in Name Only",
      "DINO", "DINOs", "Democrat in Name Only",
      "Blue Dog", "Blue Dogs", "Blue Dog Democrat", "Blue Dog Democrats",
      "Never Trump", "Never Trumper", "Never Trumpers", "Never-Trump",
      "Problem Solvers Caucus", "Problem Solver Caucus",
      "Freedom Caucus", "House Freedom Caucus",
      "Congressional Progressive Caucus",
      "New Democrat Coalition",
      "Christian Nationalist", "Christian Nationalists", "Christian Nationalism",
      "Christofascist", "Christofascism", "Christian Right",
      "The Christian Right", "Religious Right", "Theocrat",
      "Theocracy movement",
      "White Supremacist", "White Supremacists", "White Supremacy",
      "White Nationalist", "White Nationalists", "White Nationalism",
      "White Separatist",
      "Fascist", "Fascists"
    ),
    TermName = c(
      rep("Democrat", 8), rep("Republican", 9), rep("MAGA", 8),
      rep("Independent", 3), rep("Libertarian", 3), rep("Green", 3),
      rep("Liberal", 5), rep("Conservative", 5), rep("Progressive", 2),
      rep("Democratic Socialist", 2), rep("Moderate", 5), rep("Left", 3), rep("Right", 5),
      rep("Neocon", 4), rep("Neoliberal", 4), rep("Populist", 3),
      rep("Nationalist", 3), rep("RINO", 3), rep("DINO", 3),
      rep("Blue Dog", 4), rep("Never Trump", 4), rep("Problem Solvers Caucus", 2),
      rep("Freedom Caucus", 2), rep("Congressional Progressive Caucus", 1), rep("New Democrat Coalition", 1),
      rep("Christian Nationalist", 10), rep("White Supremacist", 7), rep("Fascist", 2)
    ),
    stringsAsFactors = FALSE
  )
  d
})
