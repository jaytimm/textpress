# textpress

[![CRAN version](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)
[![CRAN downloads](http://cranlogs.r-pkg.org/badges/last-month/textpress)](https://cran.r-project.org/package=textpress)

`textpress` is an R toolkit for building text corpora and searching them -- no custom object classes, just plain data frames from start to finish. It collects URLs from durable sources -- RSS and Atom feeds, Wikipedia and its citations, or URLs you already have -- then reads, processes, and searches the resulting text through a consistent four-step API: **Fetch**, **Read**, **Process**, **Search**.

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

## A source-to-corpus example

Select a small set of known publishers, retrieve their recent feed entries,
then read the linked pages. `read_urls()` retains the RSS discovery metadata.

```r
feeds <- textpress::rss_local_rags |>
  subset(state_abbr == "NM") |>
  head(2)

articles <- textpress::fetch_rss(feeds$url)
corpus <- textpress::read_urls(articles)

corpus$text
corpus$meta
```

There are three ways into the same pipeline:

| Starting point | Entry point | Best for |
|---|---|---|
| Known publishers | `rss_politics` or `rss_local_rags` -> `fetch_rss()` | Recent, source-led collections |
| A topic | `fetch_wiki_urls()` -> `fetch_wiki_refs()` | Topic- and citation-led discovery |
| Existing URLs | `read_urls()` directly | Curated or externally collected corpora |

Each route converges on `read_urls()` -> `nlp_*()` -> `search_*()`.

---

## The `textpress` API

**Conventions:** corpus is a data frame with a `text` column plus identifier column(s) passed to `by` (default `doc_id`). All outputs are plain data frames or data.tables; pipe-friendly.

### 1. Fetch (`fetch_*`)

Collect URLs and provenance from stable sources -- not full article text. `textpress`
does not provide general-purpose live web search. Pass fetch results to
`read_urls()` to retrieve their content.

- **`fetch_rss(feed_url)`** -- Retrieve recent entries from RSS and Atom feeds; bundled catalogs are available as `rss_politics` and `rss_local_rags`.
- **`fetch_wiki_urls(query, limit)`** -- Wikipedia article URLs matching a search phrase.
- **`fetch_wiki_refs(url, n)`** -- External citation URLs from a Wikipedia article's References section.

### 2. Read (`read_*`)

Scrape and parse URLs into a structured corpus.

- **`read_urls(x, ...)`** -- URL vector or fetch-result table → `list(text, meta)`. Passing a table preserves its discovery metadata and `doc_id`. `text` is one row per node; `meta` is one row per URL.

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

**Hybrid retrieval** -- run `search_index()` and `search_vector()` over the same chunks, then merge with reciprocal rank fusion (RRF).

**Context assembly** -- `nlp_roll_chunks()` with `context_size > 0` gives each chunk a focal sentence plus surrounding context, so retrieved passages are self-contained when passed to an LLM.

Because the stages exchange plain data frames, their outputs can also be
inspected, filtered, saved, or passed to an LLM without conversion to a custom
corpus class.

---

## Vignettes

- [Web data](https://jaytimm.github.io/textpress/articles/web-data.html) -- `fetch_rss()` + `read_urls()`
- [Basic NLP](https://jaytimm.github.io/textpress/articles/basic-nlp.html) -- sentence splitting, tokenization, span-aware casting
- [Wikipedia data](https://jaytimm.github.io/textpress/articles/wiki-data.html) -- `fetch_wiki_urls()` + `fetch_wiki_refs()`
- [Regex search](https://jaytimm.github.io/textpress/articles/regex-search.html) -- `search_regex()`, KWIC
- [Dictionary search](https://jaytimm.github.io/textpress/articles/dict-search.html) -- `search_dict()`, PMI co-occurrence
- [Semantic search](https://jaytimm.github.io/textpress/articles/semantic-search.html) -- RAG pipeline: embeddings, BM25, hybrid RRF retrieval, LLM extraction

---

## License

MIT © [Jason Timm](https://github.com/jaytimm)

## Citation

```r
citation("textpress")
```

## Issues

Report bugs or request features at <https://github.com/jaytimm/textpress/issues>
