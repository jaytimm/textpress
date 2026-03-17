# textpress

[![CRAN version](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)
[![CRAN downloads](http://cranlogs.r-pkg.org/badges/last-month/textpress)](https://cran.r-project.org/package=textpress)

`textpress` is an R toolkit for building text corpora and searching them -- no custom object classes, just plain data frames from start to finish. It covers the full arc from URL to retrieved passage through a consistent four-step API: **Fetch**, **Read**, **Process**, **Search**. Traditional tools (KWIC, BM25, dictionary matching) sit alongside modern ones (semantic search, LLM-ready chunking), and the pipeline composes cleanly with the pipe.

```r
library(textpress)
library(dplyr)

# Fetch candidate URLs, scrape text, split into sentences
web_urls <- fetch_urls("US generational politics 2026", n_pages = 2, date_filter = "m")

corpus <- web_urls |>
  filter(path_depth > 0) |>
  pull(url) |>
  read_urls()

web_ss <- corpus$text |> nlp_split_sentences(by = c("doc_id", "node_id"))

# Build a BM25 index and fetch embeddings for semantic search
index  <- web_ss |> nlp_tokenize_text(by = "doc_id") |> nlp_index_tokens()
embeds <- util_fetch_embeddings(web_ss, by = "doc_id", api_token = Sys.getenv("HUGGINGFACE_API_TOKEN"))

# Search: regex, dictionary, BM25, semantic -- same corpus, same pipe
search_regex(web_ss,  query = "\\bGen Z\\b")
search_dict(web_ss,   terms = dict_generations$variant)
search_index(index,   query = "generational party alignment")
search_vector(embeds, query = util_fetch_embeddings("generational party alignment", api_token = Sys.getenv("HUGGINGFACE_API_TOKEN")))
```

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

## The `textpress` API

**Conventions:** corpus is a data frame with a `text` column plus identifier column(s) passed to `by` (default `doc_id`). All outputs are plain data frames or data.tables; pipe-friendly.

### 1. Fetch (`fetch_*`)

Find URLs and metadata -- not full text. Pass results to `read_urls()` to get content.

- **`fetch_urls(query, n_pages, date_filter)`** -- Search engine query; returns candidate URLs with metadata.
- **`fetch_wiki_urls(query, limit)`** -- Wikipedia article URLs matching a search phrase.
- **`fetch_wiki_refs(url, n)`** -- External citation URLs from a Wikipedia article's References section.

### 2. Read (`read_*`)

Scrape and parse URLs into a structured corpus.

- **`read_urls(urls, ...)`** -- Character vector of URLs → `list(text, meta)`. `text` is one row per node (headings, paragraphs, lists); `meta` is one row per URL. For Wikipedia, `exclude_wiki_refs = TRUE` drops References / See also / Bibliography sections.

### 3. Process (`nlp_*`)

Prepare text for search or indexing.

- **`nlp_split_paragraphs()`** -- Break documents into structural blocks.
- **`nlp_split_sentences()`** -- Segment blocks into individual sentences.
- **`nlp_tokenize_text()`** -- Normalize text into a clean token stream.
- **`nlp_index_tokens()`** -- Build a weighted BM25 index for ranked retrieval.
- **`nlp_roll_chunks()`** -- Roll sentences into fixed-size chunks with surrounding context (RAG-style).

### 4. Search (`search_*`)

Four retrieval modes over the same corpus. Data-first, pipe-friendly.

| Function                              | Query type    | Use case                                                                    |
|---------------------------------------|---------------|-----------------------------------------------------------------------------|
| **`search_regex(corpus, query)`**     | Regex pattern | Specific strings, KWIC with inline highlighting.                            |
| **`search_dict(corpus, terms)`**      | Term vector   | Exact phrases and MWEs; built-in `dict_generations`, `dict_political`.      |
| **`search_index(index, query)`**      | Keywords      | BM25 ranked retrieval over a token index.                                   |
| **`search_vector(embeddings, query)`**| Numeric vector| Semantic nearest-neighbor search; use `util_fetch_embeddings()` to embed.   |

---

## RAG & LLM pipelines

`textpress` is designed to compose cleanly into retrieval-augmented generation pipelines.

**Hybrid retrieval** -- run `search_index()` and `search_vector()` over the same chunks, then merge with reciprocal rank fusion (RRF). Chunks that rank well under both term frequency and meaning rise to the top.

**Context assembly** -- `nlp_roll_chunks()` with `context_size > 0` gives each chunk a focal sentence plus surrounding context, so retrieved passages are self-contained when passed to an LLM.

**Agent tool-calling** -- the consistent API and plain data-frame outputs map naturally to tool use:

| Agent task                                     | Function             |
|------------------------------------------------|----------------------|
| "Find recent articles on X"                    | `fetch_urls()`       |
| "Scrape these pages"                           | `read_urls()`        |
| "Find all mentions of these entities"          | `search_dict()`      |
| "Follow citations from this Wikipedia article" | `fetch_wiki_refs()`  |

---

## Vignettes

- [Web data](https://jaytimm.github.io/textpress/articles/web-data.html) -- `fetch_urls()` + `read_urls()`
- [Basic NLP](https://jaytimm.github.io/textpress/articles/basic-nlp.html) -- sentence splitting, tokenization, span-aware casting
- [Wikipedia data](https://jaytimm.github.io/textpress/articles/wiki-data.html) -- `fetch_wiki_urls()` + `fetch_wiki_refs()`
- [Regex search](https://jaytimm.github.io/textpress/articles/regex-search.html) -- `search_regex()`, KWIC
- [Dictionary search](https://jaytimm.github.io/textpress/articles/dict-search.html) -- `search_dict()`, PMI co-occurrence
- [Semantic search](https://jaytimm.github.io/textpress/articles/semantic-search.html) -- embeddings, BM25, RRF, LLM extraction

---

## License

MIT © [Jason Timm](https://github.com/jaytimm)

## Citation

```r
citation("textpress")
```

## Issues

Report bugs or request features at <https://github.com/jaytimm/textpress/issues>
