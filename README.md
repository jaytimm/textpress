[![](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)
[![](http://cranlogs.r-pkg.org/badges/last-month/textpress)](https://cran.r-project.org/package=textpress)

# textpress

**Ol' timey NLP meets modern R** — web search, Wikipedia, scraping, chunking, KWIC, BM25, and semantic search. A lightweight toolkit with a consistent API: **Fetch, Read, Process, and Search.** Simple, unobtrusive, data-frame-friendly; no new classes, no bloat.

For corpus linguists, text analysts, data journalists, and R users building LLM pipelines — or anyone dipping a toe into NLP.

---

## Installation

From CRAN:

```r
install.packages("textpress")
```

Development version:

```r
remotes::install_github("jaytimm/textpress")
```

---

## The textpress API map

**Conventions:** Corpus is a data frame with a `text` column plus identifier column(s) in `by` (default `doc_id`; use e.g. `c("url", "node_id")` after `read_urls()`). Outputs are plain data frames or data.tables; pipe-friendly.

### 1. Data acquisition (`fetch_*`)

These functions find **locations** of information (URLs or metadata), not full text. Use `read_urls()` to get content.

- **`fetch_urls()`** — Web (general). Search engine for a list of relevant links.
- **`fetch_wiki_urls()`** — Wikipedia. Article URLs matching a search phrase.
- **`fetch_wiki_refs(url, n)`** — Wikipedia. External citation URLs from an article’s References section; returns a data.table with `source_url` and `ref_url`.

### 2. Ingestion (`read_*`)

Bring data into R from URLs.

- **`read_urls()`** — Character vector of URLs → data frame (one row per node: headings, paragraphs, lists). For Wikipedia, use `exclude_wiki_refs = TRUE` to drop References / See also / Bibliography / Sources sections.

### 3. Processing (`nlp_*`)

Prepare raw text for analysis or indexing. Designed to be used with the pipe `|>`.

- **`nlp_split_paragraphs()`** — Break large documents into structural blocks.
- **`nlp_split_sentences()`** — Refine blocks into individual sentences.
- **`nlp_tokenize_text()`** — Normalize text into a clean token stream.
- **`nlp_index_tokens()`** — Build a weighted BM25 index for ranked search.
- **`nlp_roll_chunks()`** — Roll units (e.g. sentences) into fixed-size chunks with optional context (RAG-style).

### 4. Retrieval (`search_*`)

Four ways to query your data. Subject-first: data (corpus, index, or embeddings) then query. Pipe-friendly.

| Function | Primary input (needle) | Use case |
|----------|------------------------|----------|
| **search_regex(corpus, query, ...)** | Character (pattern) | Specific strings/patterns, KWIC. |
| **search_dict(corpus, terms, ...)** | Character (vector of terms) | Exact phrases/MWEs; no partial-match risk. N-gram range is set from word counts in `terms`. Built-in dicts: `dict_generations`, `dict_political`. |
| **search_index(index, query, ...)** | Character (keywords) | BM25 ranked retrieval. |
| **search_vector(embeddings, query, ...)** | Numeric (vector/matrix) | Semantic neighbors (use `util_fetch_embeddings()` for embeddings). |

**Quick start** — runnable in a few seconds, no network:

```r
library(textpress)

# Minimal corpus (or use read_urls() after fetch_urls() / fetch_wiki_urls())
corpus <- data.frame(
  doc_id = c("1", "2"),
  text   = c("R runs on parallel and distributed systems.", "Use future and OpenMP for speed.")
)

# Process: sentences or tokens
sentences <- nlp_split_sentences(corpus, by = "doc_id")
tokens    <- nlp_tokenize_text(corpus, by = "doc_id", include_spans = FALSE)
index     <- nlp_index_tokens(tokens)

# Search: regex, exact terms, or BM25
search_regex(corpus, "parallel|future", by = "doc_id")
search_dict(corpus, by = "doc_id", terms = c("OpenMP", "distributed"))
search_index(index, "parallel")
```

**With web data** — fetch URLs, then read and search (requires network):

```r
links  <- fetch_urls("R high performance computing", n_pages = 1)
corpus <- read_urls(links$url)
corpus$doc_id <- seq_len(nrow(corpus))
search_regex(corpus, "parallel|future", by = "doc_id")
```

**Wikipedia:** `fetch_wiki_urls("topic")` → `read_urls(urls, exclude_wiki_refs = TRUE)`. For citation URLs from an article’s References section: `fetch_wiki_refs(wiki_url, n = 10)` → `read_urls(refs$ref_url)`.

---

## Extension: LLMs & agents

Design fits RAG and agentic workflows.

### RAG

Local-first RAG without a heavy vector DB: `search_index()` (BM25) for keyword chunks; `nlp_split_paragraphs()` / `nlp_roll_chunks()` for context windows; `search_dict()` for deterministic entities before the LLM (reduces hallucination).

### Agent tools

Flat names and data-frame in/out make functions easy for a model to call: `fetch_urls()` (Search), `read_urls()` (Browse), `search_regex()` (Find in page), `search_dict()` (Entity extraction).

---

## License

MIT © [Jason Timm, MA, PhD](https://github.com/jaytimm)

## Citation

If you use this package in your research, please cite:

```r
citation("textpress")
```

## Issues

Report bugs or request features at [https://github.com/jaytimm/textpress/issues](https://github.com/jaytimm/textpress/issues)

## Contributing

Contributions welcome! Please open an issue or submit a pull request.
