.junk_phrases <- c(
  "your (email )?inbox",
  "all rights reserved",
  "free subsc",
  "^please",
  "^sign up",
  "Check out",
  "^Get",
  "^got",
  "^you must",
  "^you can",
  "^Thanks",
  "^We ",
  "^We've",
  "login",
  "log in",
  "logged in",
  "Data is a real-time snapshot",
  "^do you",
  "^subscribe to",
  "your comment"
)


setwd("/home/jtimm/pCloudDrive/GitHub/packages/textpress/data")
usethis::use_data(.junk_phrases, overwrite = TRUE, internal = T)
