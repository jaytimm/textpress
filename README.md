[![](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)
[![](http://cranlogs.r-pkg.org/badges/last-month/textpress)](https://cran.r-project.org/package=textpress)

# textpress

**Ol' timey NLP meets modern R** — web search, Wikipedia, scraping, chunking, KWIC, BM25, and semantic search. A lightweight toolkit with a consistent API: **Fetch, Read, Process, and Search.** Simple, unobtrusive, data-frame-friendly; no new classes, no bloat.

For corpus linguists, text analysts, data journalists, and R users building LLM pipelines — or anyone dipping a toe into NLP.

### Why textpress?

In an era of heavy AI frameworks and complex vector databases, textpress takes a rugged, local-first approach. Get from a search query to a structured data frame without the overhead.

- **Corpus linguists** — KWIC and BM25 are first-class. Your data stays in data frames; no proprietary objects.
- **Data journalists** — Speed from lead to data. Fetch URLs from search or Wikipedia, ingest into Tidyverse-ready formats.
- **LLM & RAG developers** — A no-nonsense middle layer: `nlp_roll_chunks()` for context windows, `search_index()` for keyword retrieval before prompts.
- **Everyone** — Zero bloat. A consistent four-step pattern (Fetch → Read → Process → Search) that fits in a `|>` pipeline.

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

### Quick start

Build a searchable index from the web in six lines (requires network):

```r
library(textpress)

# 1. Fetch & Read
links  <- fetch_urls("R high performance computing", n_pages = 1)
corpus <- read_urls(links$url)

# 2. Process
tokens <- nlp_tokenize_text(corpus, by = "url")
index  <- nlp_index_tokens(tokens)

# 3. Search (BM25 ranked)
search_index(index, "parallel distributed")
```

**Wikipedia:** `fetch_wiki_urls("topic")` → `read_urls(urls, exclude_wiki_refs = TRUE)`. For citation URLs from an article’s References section: `fetch_wiki_refs(wiki_url, n = 10)` → `read_urls(refs$ref_url)`.

---

## Extension: LLMs & Agents

textpress handles the heavy lifting of data acquisition and preparation for LLM pipelines.

### RAG & Retrieval

- **Context Windows** — `nlp_roll_chunks()` creates the precise text snippets needed for prompts or embeddings.
- **Hybrid Search** — Use `search_index()` (BM25) for fast keyword retrieval, or pipe results into a vector database for semantic search.
- **Fact Checking** — `search_dict()` provides a deterministic way to verify entities before they reach the model, reducing hallucinations.

### Agentic Tooling

The consistent API and data-frame outputs make these functions easy to map to an agent's toolset:

| Tool | Function | Result |
|------|----------|--------|
| Search | `fetch_urls()` | Targeted URL list |
| Browse | `read_urls()` | Structured text nodes |
| Find | `search_regex()` | Precise matches/coordinates |
| Extract | `search_dict()` | Categorized entities |

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
