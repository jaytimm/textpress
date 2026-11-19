# Cache results of network chunks (fetching, embeddings, LLM calls).
# A chunk with `cache_rds = c("obj", ...)` runs once and saves those objects to
# data/<vignette>-<label>.rds; later renders load them instead of re-running.
# Delete the data/ folder and re-render to refresh.
.cache_file <- function(options) {
  file.path("data", paste0(knitr::current_input(dir = FALSE) |> tools::file_path_sans_ext(),
                            "-", options$label, ".rds"))
}
knitr::opts_hooks$set(cache_rds = function(options) {
  f <- .cache_file(options)
  if (file.exists(f)) {
    list2env(readRDS(f), envir = knitr::knit_global())
    options$eval <- FALSE
  }
  options
})
knitr::knit_hooks$set(cache_rds = function(before, options, envir) {
  f <- .cache_file(options)
  if (!before && isTRUE(options$eval) && !file.exists(f)) {
    dir.create(dirname(f), showWarnings = FALSE)
    saveRDS(mget(options$cache_rds, envir = envir), f, compress = "xz")
  }
  NULL
})
