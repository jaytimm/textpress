## Submission

textpress 1.1.2 (update from 1.1.1).

- Adds `fetch_rss()` with the `rss_politics` and `rss_local_rags` feed catalogs.
- Removes `fetch_urls()`.
- Adds `nlp_find_abbreviations()` and an "Abbreviations" vignette.
- `util_fetch_embeddings()` now calls any OpenAI-compatible endpoint and
  defaults to a local Ollama server; its arguments changed.

See NEWS.md for details.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Jason Timm <JaTimm@salud.unm.edu>'

## Test environments

* local Ubuntu, R 4.3.1
* GitHub Actions: macOS, Windows, Ubuntu (R release, devel, oldrel-1)
* win-builder (devel)

## Notes

Vignettes make no network requests during checks. Results of network steps
(feeds, Wikipedia, embeddings, LLM calls) are saved in `vignettes/data/`
(about 3 MB) and loaded when the vignettes are built. The saved text comes
from sources that permit reuse with attribution: Wikipedia (CC BY-SA),
The Conversation (CC BY-ND) and Pew Research Center.

Examples that need a local embedding server or network access are wrapped in
`\dontrun{}`.

## Reverse dependencies

One reverse dependency, puremoe, which uses only `nlp_split_sentences()`.
That function is unchanged in this release.
