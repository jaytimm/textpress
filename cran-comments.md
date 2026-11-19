## Submission

textpress 1.1.2 (update from 1.1.1).

- Adds `fetch_rss()` with the `rss_politics` and `rss_local_rags` feed catalogs.
- Removes `fetch_urls()`.
- Adds `nlp_find_abbreviations()` and an "Abbreviations" vignette.

See NEWS.md for details.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Jason Timm <JaTimm@salud.unm.edu>'

## Test environments

* local Ubuntu, R 4.3.1
* win-builder (devel)

## Notes

Vignettes that fetch live web data run only when the environment variable
`TEXTPRESS_BUILD_LIVE_VIGNETTES` is `"true"`. On CRAN their code is shown but
not run, so checks make no network requests.

## Reverse dependencies

One reverse dependency, puremoe, which uses only `nlp_split_sentences()`.
That function is unchanged in this release.
