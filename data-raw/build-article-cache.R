# Refresh the cached data used by the site articles.
#
# Article chunks marked `cache_rds` (fetching feeds and Wikipedia, embeddings,
# LLM calls) save their results to vignettes/articles/data/. Later renders,
# including the pkgdown site, load those files instead of going online.
#
# This script deletes the cache and re-renders every article, so all network
# chunks run once more. Requirements: internet access, a local Ollama server
# with `ollama pull all-minilm`, and OPENAI_API_KEY for the LLM chunks.

pkgload::load_all(".")

unlink("vignettes/articles/data", recursive = TRUE)

out_dir <- tempfile("vignettes-")
for (f in list.files("vignettes/articles", "[.]Rmd$", full.names = TRUE)) {
  message("Rendering ", basename(f))
  rmarkdown::render(f, output_dir = out_dir, intermediates_dir = tempdir(),
                    quiet = TRUE)
}

message("Cache rebuilt: ", format(sum(file.size(
  list.files("vignettes/articles/data", full.names = TRUE))) / 1e6, digits = 2), " MB")
