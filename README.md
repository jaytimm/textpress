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

| doc_id | paragraph_id | chunk_id | text                                                                                                                                                                                                                                                                                                                                                                                                |
|:--|:---|:--|:---------------------------------------------------------------|
| 58     | 15           | 2        | The fact is, employment still hasn’t returned to its pre-pandemic trend, and the <b>unemployment rate</b> is artificially low.                                                                                                                                                                                                                                                                      |
| 62     | 28           | 1        | Between February 2020 and February 2024, California’s payroll jobs have increased by 1.7%, half of the national job growth rate. The <b>unemployment rate</b> in California in February was 5.3%, compared with 3.9% for the U.S as a whole, although the state Finance Department’s chief economist, Somjita Mitra, said California’s share of long-term unemployed is comparatively much smaller. |
| 90     | 5            | 3        | Conversely, if unemployment was low or falling, most workers felt reasonably secure. The <b>unemployment rate</b>, back then, was a reasonable indicator of distress or well-being.                                                                                                                                                                                                                 |

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

    ##   |                                                                              |                                                                      |   0%  |                                                                              |=======                                                               |  10%  |                                                                              |==============                                                        |  20%  |                                                                              |=====================                                                 |  30%  |                                                                              |============================                                          |  40%  |                                                                              |===================================                                   |  50%  |                                                                              |==========================================                            |  60%  |                                                                              |=================================================                     |  70%  |                                                                              |========================================================              |  80%  |                                                                              |===============================================================       |  90%  |                                                                              |======================================================================| 100%

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

| cos_sim | doc_id | paragraph_id | chunk_id | chunk                                                                                                                                                                                                                                                       |
|--:|:--|:---|:---|:----------------------------------------------------------|
|   0.748 | 60     | 32           | 1        | The three key pillars of Bidenomics are investments in American infrastructure, clean energy, and business; empowerment of workers in the middle and lower classes; and promoting competition across businesses and sectors.                                |
|   0.745 | 60     | 7            | 1        | In response to these challenges, Bidenomics focuses on the core goals of public investment, worker empowerment, and promoting competition. Below, we take a closer look at each of these central pillars of Bidenomics.                                     |
|   0.716 | 60     | 33           | 1        | Bidenomics refers to the broad set of economic policies and actions instituted under President Joe Biden. Broadly, these include efforts to invest heavily in American infrastructure, green energy initiatives, domestic manufacturing, and related areas. |

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

| Point_number | Point                                                                                                                                        |
|:------|:----------------------------------------------------------------|
| 1            | BIDENOMICS focuses on public investment, worker empowerment, and promoting competition.                                                      |
| 2            | BIDENOMICS emphasizes investments in American infrastructure, clean energy, and businesses.                                                  |
| 3            | BIDENOMICS aims to reduce taxes for middle-class workers and increase tax rates for the wealthy and large corporations.                      |
| 4            | BIDENOMICS includes efforts to support domestic manufacturing and increase semiconductor production in the United States.                    |
| 5            | BIDENOMICS promotes updating, improving, and building additional infrastructure across the country.                                          |
| 6            | BIDENOMICS plans to invest in registered apprenticeships, career technical education, universal prekindergarten, and free community college. |
| 7            | BIDENOMICS believes in promoting competition to lower costs for small businesses and consumers while increasing wages for workers.           |
| 8            | BIDENOMICS is about building the economy from the middle out and the bottom up to address inequality and foster growth.                      |
| 9            | BIDENOMICS supports union involvement and urges increased competition in business.                                                           |
| 10           | BIDENOMICS is President Joe Biden’s economic vision focused on economic gains, policies, and plans.                                          |

## Summary
