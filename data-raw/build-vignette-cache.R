# Refresh the cached data used by the vignettes.
#
# Vignette chunks marked `cache_rds` (fetching feeds and Wikipedia, embeddings,
# LLM calls) save their results to vignettes/data/. Later renders, including
# R CMD check and the pkgdown site, load those files instead of going online.
#
# This script deletes the cache and re-renders every vignette, so all network
# chunks run once more. Requirements: internet access, a local Ollama server
# with `ollama pull all-minilm`, and OPENAI_API_KEY for the LLM chunks.

pkgload::load_all(".")

unlink("vignettes/data", recursive = TRUE)

out_dir <- tempfile("vignettes-")
for (f in list.files("vignettes", "[.]Rmd$", full.names = TRUE)) {
  message("Rendering ", basename(f))
  rmarkdown::render(f, output_dir = out_dir, intermediates_dir = tempdir(),
                    quiet = TRUE)
}

message("Cache rebuilt: ", format(sum(file.size(
  list.files("vignettes/data", full.names = TRUE))) / 1e6, digits = 2), " MB")
