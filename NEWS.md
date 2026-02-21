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

## Documentation

- README revamped around the API map and a single “golden path” workflow.
- DESCRIPTION and package help updated for the four-stage pipeline; version set to 1.1.0.

---

# textpress 1.0.0

- Initial release: URL fetching, URL content reading, NLP processing (split, tokenize, index), and corpus/search utilities.
