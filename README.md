[![](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)

# textpress

A lightweight R toolkit for text retrieval: **Fetch, Read, Process, and Search.** Every function follows a verb_noun pattern so the API is predictable and discoverable (e.g. type `search_` to see all retrieval options). No heavy dependencies; data stays in data frames.

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

### 4. Retrieval (`search_*`)

Four ways to query your data. Each accepts a corpus or index and returns a ranked or filtered data frame.

- **`search_corpus()`** — Regex / KWIC. Finding exact patterns or strings in raw text.
- **`search_index()`** — BM25 / tokens. Keyword-based ranked retrieval (traditional search).
- **`search_vector()`** — Cosine similarity. Semantic search using **your own** embedding matrix (textpress does not build embeddings; use e.g. \pkg{reticulate} with sentence-transformers and pass the matrix in).
- **`search_dict()`** — Dictionary match. Extract specific entities/terms from a provided list.

---

## The golden path

The naming schema lets the code read like the researcher’s intent:

```r
library(textpress)

# 1. Acquire & ingest
urls    <- fetch_urls("R high performance computing")
corpus  <- read_urls(urls)

# 2. Process & index
index   <- corpus |> 
  nlp_tokenize_text() |> 
  nlp_index_tokens()

# 3. Search (four ways)
results_bm25   <- search_index(index, "parallel processing")
results_regex  <- search_corpus(corpus, "furrr|future")
results_entity <- search_dict(corpus, dictionary = tech_dict)
results_vector <- search_vector(query_embedding, my_matrix)
```

---

## Why this works

- **Discovery** — Type `search_` and see all retrieval options in one list.
- **Honesty** — `search_dict` is clearer than “extract entities”: the result is only as good as the dictionary you provide.
- **Extensibility** — A future `search_fuzzy()` or `fetch_arxiv()` already has a home in the naming convention.

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

- `fetch_urls()` — agent “Search” tool.
- `read_urls()` — agent “Browse” tool.
- `search_corpus()` — agent “Find in page” tool.

```r
# Example: textpress as a research tool before calling an LLM
query   <- "latest version of the R furrr package"
docs    <- read_urls(fetch_urls(query)$url)
corpus  <- docs |> mutate(doc_id = row_number())
index   <- corpus |> nlp_tokenize_text() |> nlp_index_tokens()
best    <- search_index(index, "version release")
# Pass best (or its text) to your LLM as context.
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
