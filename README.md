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

A simple RAG workflow:

-   Web Scraping \> Chunk Building \> HuggingFace Embeddings \> Semantic
    Search \> Chat Completion via OpenAI

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

| id    | chunk                                                                                                                                                                                                                                                                                                                                                 | chunk_plus_context                                                                                                                                                                                                                                                                                                                                    |
|:-|:----------------------------------|:----------------------------------|
| 1.1.1 | The White House and its progressive economists have been celebrating – what they claim – is a remarkable “economic recovery.” However, the vast majority of Americans are not joining in the jubilee.                                                                                                                                                 | The White House and its progressive economists have been celebrating – what they claim – is a remarkable “economic recovery.” However, the vast majority of Americans are not joining in the jubilee. There is a clear disconnect between the supposed economic upturn and the affordability crisis you face every day.                               |
| 1.1.2 | There is a clear disconnect between the supposed economic upturn and the affordability crisis you face every day.                                                                                                                                                                                                                                     | However, the vast majority of Americans are not joining in the jubilee. There is a clear disconnect between the supposed economic upturn and the affordability crisis you face every day.                                                                                                                                                             |
| 1.2.1 | Hard-working Americans do not feel “better off” under the Biden Administration because they are not better off. All you have to do is look at the out-of-reach price tag to own a home, your shrinking retirement account, the cost of one tank of gas, or your weekly grocery bill to know that Bidenomics has made the American Dream unattainable. | Hard-working Americans do not feel “better off” under the Biden Administration because they are not better off. All you have to do is look at the out-of-reach price tag to own a home, your shrinking retirement account, the cost of one tank of gas, or your weekly grocery bill to know that Bidenomics has made the American Dream unattainable. |

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

#### Prompt

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

    ## Attempt 1 : Invalid JSON received. Regenerating...

#### Core tenents of Bidenomics

| Point_number | Point                                                                                                                                                    |
|:------|:----------------------------------------------------------------|
| 1            | BIDENOMICS focuses on investments in American infrastructure, clean energy, and business to drive economic growth.                                       |
| 2            | BIDENOMICS aims to empower workers in the middle and lower classes through initiatives such as registered apprenticeships and universal prekindergarten. |
| 3            | BIDENOMICS promotes competition across businesses and sectors to lower costs for consumers and increase wages for workers.                               |
| 4            | BIDENOMICS is characterized by a set of economic policies and actions instituted under President Joe Biden.                                              |
| 5            | BIDENOMICS includes efforts to increase investments in American infrastructure, green energy, and domestic manufacturing.                                |
| 6            | BIDENOMICS involves tax policies that aim to reduce taxes for middle-class workers and raise tax rates for wealthy individuals and large corporations.   |
| 7            | BIDENOMICS envisions building the economy from the middle out and the bottom up to address inequality and foster economic growth.                        |
| 8            | BIDENOMICS prioritizes promoting competition to help small businesses and reduce costs for consumers.                                                    |
| 9            | BIDENOMICS advocates for increased union involvement and supports measures to enhance worker education and training.                                     |
| 10           | BIDENOMICS is a central theme in President Biden’s economic vision and administration, emphasizing economic gains and policies.                          |

## Summary
