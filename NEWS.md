# textpress 1.1.2

## Fetch

- `fetch_urls()` and its DuckDuckGo scraping implementation have been removed.
- `fetch_rss()` adds publisher-supported RSS and Atom discovery. It returns a
  flat table of article URLs and feed-supplied metadata that can be filtered
  before the selected URLs are passed to `read_urls()`.
- `fetch_rss()` assigns stable `doc_id` values. Passing its result table
  directly to `read_urls()` preserves discovery metadata in the returned
  `meta` table.
- `rss_politics` adds a verified collection of 67 active, non-government US
  politics feeds from 61 sources. The exported catalog and its canonical CSV
  cover general political news, Congress, elections, polling, public opinion,
  and state politics; it is available directly as `textpress::rss_politics`.
- `rss_local_rags` adds a pinned Local Rags RSS snapshot with the shared feed
  schema plus Census region, state, county, and FIPS geography. Detailed
  discovery and 3DLNews provenance remain in the source repository.
- `fetch_wiki_refs()` now always returns one flat table for single or multiple
  Wikipedia URLs, allowing its results to pass directly to `read_urls()`.
- Wikipedia requests now identify textpress with a package User-Agent.

---

# textpress 1.1.1

## Documentation

- Six vignettes added covering the full pipeline: web data, Wikipedia data, regex search, dictionary search, semantic search (RAG), and basic NLP processing.
- Basic NLP vignette walks through `nlp_split_sentences()`, `nlp_tokenize_text()` (word and Biber methods), and `nlp_cast_tokens()` stepwise and as a single pipe.
- README revamped: tighter intro, API map, RAG/agent positioning, vignette links.

## Changes

- `util_fetch_embeddings()` re-added for embedding generation via Hugging Face inference endpoints (reversed 1.1.0 removal; now calls the HF inference API rather than loading models locally).
- `nlp_cast_tokens()` documented and surfaced -- flattens the token list from `nlp_tokenize_text()` into a long-format data frame with optional character spans.
- Suggests trimmed: `ellmer` and unused packages removed.

---

# textpress 1.1.0

## API and naming

- Package is now organized around a **four-stage pipeline**: Fetch → Read → Process → Search. All functions use a consistent verb_noun pattern.
- **Acquire:** `fetch_urls()` (from web search), `fetch_wiki_urls()`, `fetch_wiki_refs()` — return URLs or metadata, not full text.
- **Ingest:** `read_urls()` — read content from URLs into R (replaces `web_scrape_urls`).
- **Process:** `nlp_split_*`, `nlp_tokenize_text()`, `nlp_index_tokens()` (and `nlp_roll_chunks()` for rolling windows).
- **Search:** Four retrieval options — `search_regex()` (regex/KWIC), `search_index()` (BM25), `search_vector()` (cosine over your own embeddings), `search_dict()` (dictionary match; replaces `ner_extract_entities`).
- Common parameters standardized: `corpus` (replaces `tif`), `by` (replaces `text_hierarchy`).

## Removed

- In-package embedding generation (e.g. Hugging Face API). Use your own embedding pipeline and pass your embedding matrix as the \code{embeddings} argument to \code{search_vector()}.
- Legacy names: `web_search`, `wiki_search`, `wiki_find_references`, `web_scrape_urls`, `ner_extract_entities`, `sem_nearest_neighbors` / `sem_search_corpus` (replaced by `search_vector` and `search_regex`).

## Docs

- README revamped around the API map and a single “golden path” workflow.
- DESCRIPTION and package help updated for the four-stage pipeline; version set to 1.1.0.

---

# textpress 1.0.0

- Initial release: URL fetching, URL content reading, NLP processing (split, tokenize, index), and corpus/search utilities.
