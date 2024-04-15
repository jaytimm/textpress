[![R build
status](https://github.com/jaytimm/textpress/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/textpress/actions)

# textpress

A lightweight, versatile NLP companion in R. No substantial
dependencies. Data-frame-centric. Easy integration into LLM-based RAG
systems.

The package provides features for (1) basic text processing, (2) corpus
search, and (3) web scraping. Additionally included are utility
functions for (4) building text embeddings via the HuggingFace API, and
(5) fetching chat completions via the OpenAI API.

Ideal for users who need a basic, unobtrusive NLP toolkit in R.

## Installation

``` r
devtools::install_github("jaytimm/textpress")
```

## Usage

> A sample RAG workflow demonstration: Web Scraping \> Chunk Building \>
> HuggingFace Embeddings \> Semantic Search \> Chat Competion via OpenAI

### Web scraping

``` r
library(dplyr)
articles_meta <- textpress::web_scrape_urls(x = "Bidenomics",
                                            input = "search",
                                            cores = 6) 
```

### Basic NLP

``` r
articles <- articles_meta |>  
  mutate(doc_id = row_number())|>
  
  textpress::nlp_split_paragraphs(paragraph_delim = "\\n+") |>
  textpress::nlp_split_sentences(text_hierarchy = c('doc_id', 
                                                    'paragraph_id')) |>
  
  textpress::nlp_build_chunks(text_hierarchy = c('doc_id', 
                                                 'paragraph_id', 
                                                 'sentence_id'),
                              chunk_size = 2,
                              context_size = 1) |>
  
  mutate(id = paste(doc_id, paragraph_id, chunk_id, sep = '.'))
```

| id    | chunk                                                                                                                                                                                                                                                                                                                                                                                       | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
|:-|:-----------------------------|:---------------------------------------|
| 1.1.1 | “If only silence on Bidenomics would actually protect people from Bidenomics. Whether the White House wants to take ownership of Bidenomics, hide from Bidenomics, or rebrand Bidenomics, it won’t change the fact that Americans know Bidenomics isn’t working – it’s costing Americans $11,400 more every year and the Biden Administration and their allies in Congress are responsible. | “If only silence on Bidenomics would actually protect people from Bidenomics. Whether the White House wants to take ownership of Bidenomics, hide from Bidenomics, or rebrand Bidenomics, it won’t change the fact that Americans know Bidenomics isn’t working – it’s costing Americans $11,400 more every year and the Biden Administration and their allies in Congress are responsible. The way to fix Bidenomics is with different policies, not different talking points.                                                  |
| 1.1.2 | The way to fix Bidenomics is with different policies, not different talking points. We are making sure the Biden Administration can’t run away from Bidenomics – no matter what they choose to call Bidenomics.”                                                                                                                                                                            | Whether the White House wants to take ownership of Bidenomics, hide from Bidenomics, or rebrand Bidenomics, it won’t change the fact that Americans know Bidenomics isn’t working – it’s costing Americans $11,400 more every year and the Biden Administration and their allies in Congress are responsible. The way to fix Bidenomics is with different policies, not different talking points. We are making sure the Biden Administration can’t run away from Bidenomics – no matter what they choose to call Bidenomics.”   |
| 1.2.1 | Americans for Prosperity has met with thousands of Americans struggling to afford gas and groceries due to Bidenomics. In early March, AFP launched www.Bidenomics.com – the website Joe Biden doesn’t want you to see – as part of a major campaign to define the true impact of Bidenomics and force lawmakers to own their support of it.                                                | Americans for Prosperity has met with thousands of Americans struggling to afford gas and groceries due to Bidenomics. In early March, AFP launched www.Bidenomics.com – the website Joe Biden doesn’t want you to see – as part of a major campaign to define the true impact of Bidenomics and force lawmakers to own their support of it. The campaign will feature grassroots events across the country, digital and mail outreach, door knocking, and phone calls to hold Joe Biden and his allies in Congress accountable. |

### HuggingFace embeddings

``` r
api_url <- "https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2"
```

``` r
vstore <- articles |>
  rename(text = chunk) |>
  textpress::api_huggingface_embeddings(text_hierarchy = c('doc_id', 
                                                           'paragraph_id',
                                                           'chunk_id'),
                                        verbose = F,
                                        api_token = api_token,
                                        api_url = api_url)
```

### Semantic search

``` r
q <- "What are the core tenets of Bidenomics?"

query <- textpress::api_huggingface_embeddings(
  query = q,
  api_token = api_token,
  api_url = api_url)
```

``` r
rags <- textpress::sem_nearest_neighbors(
  x = query,
  matrix = vstore,
  n = 20) |>
  left_join(articles, by = c("term2" = "id"))
```

#### Relevant chunks

| cos_sim | doc_id | paragraph_id | chunk_id | chunk                                                                                                                                                                                                                        |
|---:|:--|:----|:---|:---------------------------------------------------------|
|   0.748 | 58     | 32           | 1        | The three key pillars of Bidenomics are investments in American infrastructure, clean energy, and business; empowerment of workers in the middle and lower classes; and promoting competition across businesses and sectors. |
|   0.745 | 58     | 7            | 1        | In response to these challenges, Bidenomics focuses on the core goals of public investment, worker empowerment, and promoting competition. Below, we take a closer look at each of these central pillars of Bidenomics.      |
|   0.718 | 46     | 31           | 1        | Bidenomics, at least in the White House’s definition, is as much identified by what it is not as it is by a particular set of policies or ideas.                                                                             |

### Chat completion via OpenAI

``` r
prompt1 <- 'BASED ON contexts below, 
provide a 10 point summary of the core tenets of Bidenomics.  

Start each point with "BIDENOMICS" in all caps.

Move from MACRO to MICRO.

Provide the response in JSON array format. 
JSON array should include TEN key-response pairs. 
A simple, incomplete example below:

[{"Point_number": "1", "Point": "Example summary"}, 
{"Point_number": "2", "Point": "Example summary"}, 
{"Point_number": "3", "Point": "Example summary"}]

Ensure there is no trailing comma after the last element.

DO NOT include the "```json " code block notation in the output.

CONTEXTS:'
```

``` r
rags_json <- rags |> 
  select(term2, chunk_plus_context) |> 
  jsonlite::toJSON()
```

``` r
ten_points <- textpress::api_openai_chat_completions(
  system_message = "You are an economist.",
  user_message = paste(prompt1, rags_json, sep = '\n\n'))
```

#### Core tenents of Bidenomics

``` r
ten_points |> jsonlite::fromJSON() |> knitr::kable()
```

| Point_number | Point                                                                                                                                                                                     |
|:-----|:-----------------------------------------------------------------|
| 1            | BIDENOMICS focuses on investments in American infrastructure, clean energy, and businesses to drive economic growth.                                                                      |
| 2            | BIDENOMICS prioritizes empowerment of workers in the middle and lower classes through education and training programs.                                                                    |
| 3            | BIDENOMICS aims to promote competition across businesses and sectors for increased efficiency and consumer benefits.                                                                      |
| 4            | BIDENOMICS includes efforts to invest heavily in American infrastructure, green energy initiatives, and domestic manufacturing.                                                           |
| 5            | BIDENOMICS involves tax policies that reduce taxes for middle-class workers and raise tax rates for wealthy individuals and large corporations.                                           |
| 6            | BIDENOMICS pursues investment in clean energy, semiconductor manufacturing, and infrastructure development.                                                                               |
| 7            | BIDENOMICS is centered on building the economy from the middle out and the bottom up to address inequality and foster sustainable growth.                                                 |
| 8            | BIDENOMICS seeks to empower workers through investments in registered apprenticeships, career technical education, and advocacy for universal prekindergarten and free community college. |
| 9            | BIDENOMICS supports union involvement and advocates for increased competition in business to reduce costs for consumers and raise wages for workers.                                      |
| 10           | BIDENOMICS is seen as a means to bolster economic gains, policies, and plans under President Joe Biden’s administration.                                                                  |

## Summary
