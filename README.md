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

Ideal for users who need a basic, unobtrusive NLP tool in R.

## Installation

``` r
devtools::install_github("jaytimm/textpress")
```

## Usage

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

| id    | chunk                                                                                                                                                                                                                                                                                                                                                                                                                                                              | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|:-|:----------------------------|:-----------------------------------------|
| 1.1.1 | Arlington, VA – Americans for Prosperity has launched a sustained new eight-figure campaign focused on Bidenomics just in time for President Biden’s State of the Union address this Thursday. Bidenomics.com – the website Joe Biden doesn’t want you to see – will serve as a real-time resource for the truth on Bidenomics, up to date information about the economy, and fact checks of Biden’s latest misleading rhetoric on the economy.                    | Arlington, VA – Americans for Prosperity has launched a sustained new eight-figure campaign focused on Bidenomics just in time for President Biden’s State of the Union address this Thursday. Bidenomics.com – the website Joe Biden doesn’t want you to see – will serve as a real-time resource for the truth on Bidenomics, up to date information about the economy, and fact checks of Biden’s latest misleading rhetoric on the economy.                                                                                                                                                                                                                                                       |
| 1.2.1 | As the Biden Administration tours the country trying to convince people that Bidenomics is working, AFP is throwing significant weight behind its accountability efforts to define the true impact of Bidenomics and force lawmakers to own their support of it. The major campaign will begin with a Beltway ad blitz that includes physical ads at metro stops around the Capitol, mobile billboards and digital targeting in advance of the State of the Union. | As the Biden Administration tours the country trying to convince people that Bidenomics is working, AFP is throwing significant weight behind its accountability efforts to define the true impact of Bidenomics and force lawmakers to own their support of it. The major campaign will begin with a Beltway ad blitz that includes physical ads at metro stops around the Capitol, mobile billboards and digital targeting in advance of the State of the Union. The campaign will run through the fall and also include grassroots events across the country, digital and mail outreach, and door knocking and phone calls to hold key lawmakers accountable and provide Americans with the truth. |
| 1.2.2 | The campaign will run through the fall and also include grassroots events across the country, digital and mail outreach, and door knocking and phone calls to hold key lawmakers accountable and provide Americans with the truth.                                                                                                                                                                                                                                 | The major campaign will begin with a Beltway ad blitz that includes physical ads at metro stops around the Capitol, mobile billboards and digital targeting in advance of the State of the Union. The campaign will run through the fall and also include grassroots events across the country, digital and mail outreach, and door knocking and phone calls to hold key lawmakers accountable and provide Americans with the truth.                                                                                                                                                                                                                                                                  |

### Corpus search

``` r
search_results <- articles |>
  rename(text = chunk) |>
  
  textpress::sem_search_corpus(
    search = "unemployment rate",
    
    text_hierarchy = c('doc_id', 'paragraph_id', 'chunk_id'),
    
    highlight = c("<b>", "</b>"),
    context_size = 0,
    cores = 1,
    is_inline = F)
```

| doc_id | paragraph_id | chunk_id | text                                                                                                                                                                                                                                                                                                      |
|:--|:---|:--|:--------------------------------------------------------------|
| 10     | 7            | 1        | Even though the black <b>unemployment rate</b> is low, it traditionally is much more volatile than the white unemployment rate, said Michael Neal, a senior fellow at the Urban Institute. Because of this, Neal says, a better metric of the economy for Black folks is earnings rather than employment. |
| 61     | 31           | 1        | By many metrics, Bidenomics has been good for workers. <b>Unemployment rate</b>s as of September 2023 are 3.8%, lower than at most times since the 1950s.                                                                                                                                                 |
| 95     | 2            | 1        | The headline numbers of 300,000 jobs created and an <b>unemployment rate</b> under 4% look solid. But the growth is in part-time jobs.                                                                                                                                                                    |

### HuggingFace embeddings

``` r
api_url <- "https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2"

vstore <- articles |>
  rename(text = chunk) |>
  textpress::api_huggingface_embeddings(text_hierarchy = c('doc_id', 
                                                           'paragraph_id',
                                                           'chunk_id'),
                                        api_token = api_token,
                                        api_url = api_url)
```

    ##   |                                                                              |                                                                      |   0%  |                                                                              |========                                                              |  11%  |                                                                              |================                                                      |  22%  |                                                                              |=======================                                               |  33%  |                                                                              |===============================                                       |  44%  |                                                                              |=======================================                               |  56%  |                                                                              |===============================================                       |  67%  |                                                                              |======================================================                |  78%  |                                                                              |==============================================================        |  89%  |                                                                              |======================================================================| 100%

### Semantic search

``` r
q <- "What are the core tenets of Bidenomics?"

query <- textpress::api_huggingface_embeddings(query = q,
                                               api_token = api_token,
                                               api_url = api_url)

rags <- textpress::sem_nearest_neighbors(x = query,
                                         matrix = vstore,
                                         n = 20) |>
  left_join(articles, by = c("term2" = "id"))
```

| cos_sim | doc_id | paragraph_id | chunk_id | chunk                                                                                                                                                                                                                                                                                                                                      |
|--:|:--|:---|:--|:------------------------------------------------------------|
|   0.748 | 61     | 32           | 1        | The three key pillars of Bidenomics are investments in American infrastructure, clean energy, and business; empowerment of workers in the middle and lower classes; and promoting competition across businesses and sectors.                                                                                                               |
|   0.745 | 61     | 7            | 1        | In response to these challenges, Bidenomics focuses on the core goals of public investment, worker empowerment, and promoting competition. Below, we take a closer look at each of these central pillars of Bidenomics.                                                                                                                    |
|   0.716 | 61     | 33           | 1        | Bidenomics refers to the broad set of economic policies and actions instituted under President Joe Biden. Broadly, these include efforts to invest heavily in American infrastructure, green energy initiatives, domestic manufacturing, and related areas.                                                                                |
|   0.710 | 61     | 8            | 1        | The first focal point of Bidenomics is on investment in American business and infrastructure. Specifically, it includes investments in clean energy and related industries, a push to increase semiconductor manufacturing in the United States, and funds to update, improve, and build out additional infrastructure across the country. |
|   0.700 | 6      | 4            | 1        | Last week, the president gave a speech on “Bidenomics” in hopes that the term will lodge in voters’ minds ahead of the 2024 elections. But what is Bidenomics?                                                                                                                                                                             |

### Chat completion via OpenAI

``` r
prompt1 <- 'BASED ON contexts below, 
provide a 10 point summary of the core tenets of Bidenomics.  

Start each point with "BIDENOMICS" in all caps.

Provide the response in JSON array format. JSON array should include TEN key-response pairs. 
A simple, incomplete example below:

[{"Point_number": "1", "Point": "Example summary"}, 
{"Point_number": "2", "Point": "Example summary"}, 
{"Point_number": "3", "Point": "Example summary"}]

Ensure there is no trailing comma after the last element.

DO NOT include the "```json " code block notation in the output.


CONTEXTS:
'
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

ten_points |> jsonlite::fromJSON() |> knitr::kable()
```

| Point_number | Point                                                                                                                                                   |
|:------|:----------------------------------------------------------------|
| 1            | BIDENOMICS focuses on investments in American infrastructure, clean energy, and business.                                                               |
| 2            | BIDENOMICS emphasizes the empowerment of workers in the middle and lower classes.                                                                       |
| 3            | BIDENOMICS promotes competition across businesses and sectors.                                                                                          |
| 4            | BIDENOMICS includes efforts to invest in domestic manufacturing and green energy initiatives.                                                           |
| 5            | BIDENOMICS aims to reduce taxes for middle-class workers and increase tax rates for wealthy individuals and large corporations.                         |
| 6            | BIDENOMICS advocates for union involvement and urges increased competition in business.                                                                 |
| 7            | BIDENOMICS seeks to lower customer costs and increase wages for workers by promoting competition.                                                       |
| 8            | BIDENOMICS is based on the approach of building the economy from the middle out and the bottom up.                                                      |
| 9            | BIDENOMICS prioritizes investments in worker empowerment and education, including apprenticeships and career technical programs.                        |
| 10           | BIDENOMICS contrasts with trickle-down economics by focusing on public investment, empowering middle-class workers, and promoting business competition. |

## Summary
