[![](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)
[![](http://cranlogs.r-pkg.org/badges/last-month/textpress)](https://cran.r-project.org/package=textpress)

# textpress

`textpress` is a lightweight, local-first R toolkit that takes you from a search query to a structured data frame with minimal overhead and no custom object classes — just plain tables. It brings traditional NLP tools like KWIC and BM25 together with modern capabilities like semantic search and LLM-ready chunking, all through a consistent **Fetch**, **Read**, **Process**, **Search** API. Whether you're a corpus linguist, data journalist, RAG developer, or student, it offers a transparent, stepwise pipeline that keeps your data simple, inspectable, and bloat-free.

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

## The `textpress` API map

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

**Wikipedia:** `fetch_wiki_urls("topic")` → `read_urls(urls, exclude_wiki_refs = TRUE)`. For citation URLs from an article’s References section: `fetch_wiki_refs(wiki_url, n = 10)` → `read_urls(refs$ref_url)`.

---

## Extension: LLMs & Agents

`textpress` handles the heavy lifting of data acquisition and preparation. It is designed to function as a clean "toolset" that can be handed directly to an LLM or an automated agent.

### 1. Context Engineering (RAG)

Instead of dumping raw text into a prompt, use `textpress` to refine the intake. The pipeline moves in a straight line: chunk the corpus, retrieve the best passages, inject only what's relevant.

- **Chunking** — `nlp_roll_chunks()` breaks documents into overlapping windows sized to fit model token limits, with enough surrounding context to keep each chunk coherent on its own.
- **Hybrid Search** — `search_index()` (BM25) catches exact keyword matches; `search_vector()` catches semantic ones. Used together, they surface passages that are both lexically and conceptually relevant to the query.
- **Pre-filtering** — `search_dict()` narrows the chunk pool to only those containing relevant entities or terms before injection, keeping the context window focused and reducing noise.

### 2. The Agent's Toolbelt

The consistent API and data-frame outputs make these functions easy to map to an agent's tool-calling capabilities. An agent can "reach" for these tools to interact with the web:

| Capability | `textpress` Tool | Real-world Use Case |
|------------|----------------|---------------------|
| Search | `fetch_urls()` | "Find the top 5 articles on R performance." |
| Browse | `read_urls()` | "Scrape the content of these specific pages." |
| Locate | `search_regex()` | "Find every mention of a currency value in this text." |
| Extract | `search_dict()` | "Identify all mentions of specific competitors." |
| Dig deeper | `fetch_wiki_refs()` | "Follow the citations from this Wikipedia article." |

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
