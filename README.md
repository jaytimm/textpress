[![](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)
[![](http://cranlogs.r-pkg.org/badges/last-month/textpress)](https://cran.r-project.org/package=textpress)

# textpress

A lightweight toolkit for text retrieval and NLP with a consistent API: **Fetch, Read, Process, and Search.** Functions cover the full pipeline from web data to text processing and indexing. Multiple search strategies -- regex, BM25, cosine similarity, dictionary matching. Verb_noun naming; pipe-friendly; no heavy dependencies; outputs are plain data frames.

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

### 1. Data acquisition (`fetch_*`)

These functions talk to the outside world to find **locations** of information. They return URLs or metadata, not full text.

- **`fetch_urls()`** — Web (general). Search engines for a list of relevant links.
- **`fetch_wiki_urls()`** — Wikipedia. Find specific page titles/URLs.
- **`fetch_wiki_refs()`** — Wikipedia. Extract the external "References" URLs from a page.

### 2. Ingestion (`read_*`)

Once you have locations, bring the data into R.

- **`read_urls()`** — Input: character vector of URLs. Output: data frame of cleaned text/markdown.

### 3. Processing (`nlp_*`)

Prepare raw text for analysis or indexing. Designed to be used with the pipe `|>`.

- **`nlp_split_paragraphs()`** — Break large documents into structural blocks.
- **`nlp_split_sentences()`** — Refine blocks into individual sentences.
- **`nlp_tokenize_text()`** — Normalize text into a clean token stream.
- **`nlp_index_tokens()`** — Build a weighted BM25 index for ranked search.
- **`nlp_roll_chunks()`** — Roll units (e.g. sentences) into fixed-size chunks with optional context (RAG-style).

### 4. Retrieval (`search_*`)

Four ways to query your data. Subject-first: first argument is the data (corpus, index, or embeddings); the second is the query/needle. Pipe-friendly.

| Function | Primary input (needle) | Use case |
|----------|------------------------|----------|
| **search_regex(corpus, query, ...)** | Character (pattern) | Specific strings/patterns, KWIC. |
| **search_dict(corpus, terms, ...)** | Character (vector of terms) | Exact phrases/MWEs; no partial-match risk. |
| **search_index(index, query, ...)** | Character (keywords) | BM25 ranked retrieval. |
| **search_vector(embeddings, query, ...)** | Numeric (vector/matrix) | Semantic neighbors. |

**Quick start** (all four stages):

```r
library(textpress)
links  <- fetch_urls("R high performance computing")
corpus <- read_urls(links$url)
corpus$doc_id <- seq_len(nrow(corpus))
toks   <- nlp_tokenize_text(corpus, by = "doc_id", include_spans = FALSE)
index  <- nlp_index_tokens(toks)
search_regex(corpus, "parallel|future", by = "doc_id")
search_dict(corpus, terms = c("OpenMP", "Socket"), by = "doc_id")
search_index(index, "distributed computing")
# search_vector(embeddings, query)  # use util_fetch_embeddings() for embeddings
```

---

## Extension: Using textpress with LLMs & agents

While textpress is a general-purpose text toolkit, its design fits LLM-based workflows (e.g. RAG) and autonomous agents.

**Lightweight RAG (retrieval-augmented generation)**  
You can build a local-first RAG pipeline without a heavy vector DB:

- **Precision retrieval** — Use `search_index()` (BM25) to pull relevant chunks by keyword; often more accurate for technical data than semantic search alone.
- **Context window management** — Use `nlp_split_paragraphs()` and related functions so you send only relevant snippets to an LLM, cutting token cost and improving answers.
- **Deterministic tagging** — Use `search_dict()` to extract known entities or IDs before calling an LLM, so the model does not hallucinate core facts.

**Tool-use for autonomous agents**  
If you are building an agent (e.g. via \pkg{reticulate} or another R framework), textpress functions work well as **tools**: flat naming and predictable data-frame outputs make them easy for a model to call.

- `fetch_urls()` — agent "Search" tool.
- `read_urls()` — agent "Browse" tool.
- `search_regex()` — agent "Find in page" tool.
- `search_dict()` — agent "Entity extraction" tool (deterministic; reduces hallucination).

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
