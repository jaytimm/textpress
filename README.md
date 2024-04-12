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
| 1.3.1 | In addition to real time fact-checking through Bidenomics.com, the eight-figure effort this year will spotlight the harmful impact of Biden’s costly economic mistakes and the truth about the White House spin on the economy through a new round of ads on digital and connected TV airing across 5 key Senate states, 26 key Congressional districts, and Washington, D.C.                                                                                      | In addition to real time fact-checking through Bidenomics.com, the eight-figure effort this year will spotlight the harmful impact of Biden’s costly economic mistakes and the truth about the White House spin on the economy through a new round of ads on digital and connected TV airing across 5 key Senate states, 26 key Congressional districts, and Washington, D.C.                                                                                                                                                                                                                                                                                                                         |
| 1.4.1 | Under the Biden Administration, Americans are paying more and getting less. In the last four years, reckless spending has driven the national debt past $34 trillion – more than $258,000 of debt per household – and Americans’ purchasing power has declined as families have seen the prices of goods and services rise much faster than their income.                                                                                                          | Under the Biden Administration, Americans are paying more and getting less. In the last four years, reckless spending has driven the national debt past $34 trillion – more than $258,000 of debt per household – and Americans’ purchasing power has declined as families have seen the prices of goods and services rise much faster than their income. Prices are now 17.9% higher and the average household is paying $11,400 more each year just to maintain the same quality of life as when President Biden took office.                                                                                                                                                                       |
| 1.4.2 | Prices are now 17.9% higher and the average household is paying $11,400 more each year just to maintain the same quality of life as when President Biden took office.                                                                                                                                                                                                                                                                                              | In the last four years, reckless spending has driven the national debt past $34 trillion – more than $258,000 of debt per household – and Americans’ purchasing power has declined as families have seen the prices of goods and services rise much faster than their income. Prices are now 17.9% higher and the average household is paying $11,400 more each year just to maintain the same quality of life as when President Biden took office.                                                                                                                                                                                                                                                   |

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

| doc_id | paragraph_id | chunk_id | text                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|:-|:--|:--|:----------------------------------------------------------------|
| 19     | 4            | 1        | Some economic experts like former Dallas Fed President Richard Fisher blamed high employment and wages for inflation. Minneapolis Fed President Neel Kashkari similarly insisted that as long as the <b>unemployment rate</b> remains at record lows, “we are not done yet, we need to bring the labor market back into balance.”                                                                                                                                                                   |
| 28     | 2            | 2        | The <b>unemployment rate</b> was 3.4 percent. Gas prices had dropped by $1.60 per gallon.                                                                                                                                                                                                                                                                                                                                                                                                           |
| 49     | 4            | 1        | On Friday, Biden flew the Bidenomics banner in Allentown, Pennsylvania, the onetime steel and manufacturing hub that suffered the fallout of deindustrialization, but has seen a revival in recent years, with an <b>unemployment rate</b> the White House says is now at a 30-year low.                                                                                                                                                                                                            |
| 54     | 16           | 1        | When money is injected into the economy at low cost, businesses can use these dollars to expand and most notably hire more jobs. However, if you look at the recent trends in states like California, where unemployment last month was at 5.1%, and Nevada at 5.3%, the recent jobs report showing unemployment at 3.9% is the beginning of the curve in my view toward a 5% <b>unemployment rate</b> again because you simply can’t keep printing money to make the employment picture look good. |
| 62     | 28           | 1        | Between February 2020 and February 2024, California’s payroll jobs have increased by 1.7%, half of the national job growth rate. The <b>unemployment rate</b> in California in February was 5.3%, compared with 3.9% for the U.S as a whole, although the state Finance Department’s chief economist, Somjita Mitra, said California’s share of long-term unemployed is comparatively much smaller.                                                                                                 |

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
```

``` r
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
|   0.748 | 60     | 32           | 1        | The three key pillars of Bidenomics are investments in American infrastructure, clean energy, and business; empowerment of workers in the middle and lower classes; and promoting competition across businesses and sectors.                                                                                                               |
|   0.745 | 60     | 7            | 1        | In response to these challenges, Bidenomics focuses on the core goals of public investment, worker empowerment, and promoting competition. Below, we take a closer look at each of these central pillars of Bidenomics.                                                                                                                    |
|   0.716 | 60     | 33           | 1        | Bidenomics refers to the broad set of economic policies and actions instituted under President Joe Biden. Broadly, these include efforts to invest heavily in American infrastructure, green energy initiatives, domestic manufacturing, and related areas.                                                                                |
|   0.710 | 60     | 8            | 1        | The first focal point of Bidenomics is on investment in American business and infrastructure. Specifically, it includes investments in clean energy and related industries, a push to increase semiconductor manufacturing in the United States, and funds to update, improve, and build out additional infrastructure across the country. |
|   0.700 | 5      | 4            | 1        | Last week, the president gave a speech on “Bidenomics” in hopes that the term will lodge in voters’ minds ahead of the 2024 elections. But what is Bidenomics?                                                                                                                                                                             |

### Chat completion via OpenAI

``` r
prompt1 <- 'BASED ON contexts below, provide a 10 point summary of the core tenets of Bidenomics.  

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

| Point_number | Point                                                                                                                                                                                    |
|:-----|:-----------------------------------------------------------------|
| 1            | Bidenomics focuses on public investment, worker empowerment, and promoting competition as central pillars of economic policy.                                                            |
| 2            | The key pillars of Bidenomics are investments in American infrastructure, clean energy, and business; empowerment of workers; and fostering competition.                                 |
| 3            | Investments in American business and infrastructure, including clean energy and semiconductor manufacturing, are central to Bidenomics.                                                  |
| 4            | Bidenomics involves efforts to invest in American infrastructure, green energy initiatives, and domestic manufacturing while also implementing tax policies to benefit the middle class. |
| 5            | Bidenomics aims to promote competition to lower costs, particularly benefiting small businesses and leading to increased wages for workers.                                              |
| 6            | The goal of Bidenomics is to build the economy from the middle out and the bottom up, addressing issues of inequality and slow economic growth.                                          |
| 7            | Worker empowerment and education, including investment in apprenticeships and technical education, are emphasized in Bidenomics.                                                         |
| 8            | Bidenomics supports reducing taxes for the middle class while increasing tax rates for the wealthy and large corporations.                                                               |
| 9            | Bidenomics advocates for union involvement, increased competition in business, and lower customer costs in support of higher wages for workers.                                          |
| 10           | The term Bidenomics refers to President Biden’s economic vision, policies, and plans, emphasizing economic gains, worker rights, and climate engagement.                                 |

## Summary
