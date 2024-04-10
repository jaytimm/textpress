[![R build
status](https://github.com/jaytimm/textpress/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/textpress/actions)

# textpress

A lightweight, versatile NLP companion in R. No substantial
dependencies. Data-frame-centric. Transparent & step wise. Easy
integration into LLM-based RAG systems. The package provides features
for (1) basic text processing, (2) corpus search, and (3) web scraping.
Additionally included are utility functions for (4) building text
embeddings via the HuggingFace API, and (5) fetching chat completions
via the OpenAI API. Ideal for users who need a basic, unobtrusive NLP
tool in R.

## Installation

``` r
devtools::install_github("jaytimm/textpress")
```

## Usage

## Web scraping

### Articles & metadata from GoogleNews

``` r
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
meta <- textpress::web_process_gnewsfeed(x = 'Bidenomics')
meta |> select(date, source, title, url) |> 
  arrange(desc(date)) |> 
  head() |> 
  knitr::kable()
```

| date       | source                                      | title                                                                                                        | url                                                                                                                                                 |
|:---|:----------|:------------------------|:--------------------------------|
| 2024-04-10 | Daily Caller                                | ‘Absolutely Disastrous’: Voter Panel On ‘Morning Joe’ Skewers Bidenomics, Says They Long For Trump’s Economy | <https://dailycaller.com/2024/04/10/absolutely-disastrous-voter-panel-morning-joe-skewers-bidenomics-trumps-economy/>                               |
| 2024-04-10 | National Republican Congressional Committee | A great day to talk Bidenomics                                                                               | <https://www.nrcc.org/2024/04/10/a-great-day-to-talk-bidenomics/>                                                                                   |
| 2024-04-10 | Los Angeles Times                           | Why Biden is getting little credit for the economy, especially in California                                 | <https://www.latimes.com/business/story/2024-04-10/why-biden-is-getting-little-credit-for-the-good-economy>                                         |
| 2024-04-10 | The Maine Wire                              | Bidenomics: Inflation Soars as DC Plans More Spending                                                        | <https://www.themainewire.com/2024/04/bidenomics-inflation-soars-as-dc-plans-more-spending/>                                                        |
| 2024-04-09 | Washington Examiner                         | Bidenomics isn’t working                                                                                     | <https://www.washingtonexaminer.com/opinion/editorials/2958113/bidenomics-isnt-working/>                                                            |
| 2024-04-09 | Benzinga                                    | ‘Rich Dad Poor Dad’s’ Robert Kiyosaki Calls ‘Bidenomics’ A Joke, Says ’Inflation Is Eating American Famil    | <https://www.benzinga.com/news/24/04/38153660/rich-dad-poor-dads-robert-kiyosaki-calls-bidenomics-a-joke-says-inflation-is-eating-american-familie> |

### Scrape URLs

``` r
articles <- textpress::web_scrape_urls(
  x = meta$url,
  input = "urls",
  cores = 8) |>
  
  mutate(doc_id = row_number())

articles$text[1] |> textpress::nlp_pretty_text(char_length = 900)
```

    ## President Joe Biden hopes the latest jobs report
    ## will help convince voters that the economy is
    ## thriving under his policies, but a thorough look
    ## at the data released last week by the Bureau of
    ## Labor Statistics shows the economy is far weaker
    ## than he says it is.
    ## 
    ## The headline numbers of 300,000 jobs created and
    ## an unemployment rate under 4% look solid. But the
    ## growth is in part-time jobs. There are more
    ## full-time jobs but only in nonproductive sectors,
    ## such as government and government-subsidized
    ## healthcare.
    ## 
    ## Bidenomics seems only to be working for
    ## part-time, mostly foreign workers. The rest of
    ## the population is out of luck as prices rise and
    ## borrowing costs make American dream essentials,
    ## such as a house and a car, less affordable than
    ## ever.
    ## 
    ## Twelve months ago, 134,287,000 Americans had
    ## full-time jobs. Today, that number has fallen to
    ## 132,940,000. For all Biden’s talk, there are a
    ## million

> Alternatively:

``` r
articles <- textpress::web_scrape_urls(
  x = "Bidenomics",
  input = "search",
  cores = 6) |>
  
  mutate(doc_id = row_number())
```

## Text processing

### Split paragraphs

``` r
tif_paragraphs <- articles |>
  textpress::nlp_split_paragraphs(paragraph_delim = "\\n+")
##  "\t " -- as empty paragraphs remain -- 
```

### Split sentences

``` r
textpress::abbreviations
```

    ##  [1] "\\b[A-Z]\\." "No."         "Inc."        "St."         "U.S.A."     
    ##  [6] "Mr."         "Mrs."        "Ms."         "Dr."         "Prof."      
    ## [11] "Sr."         "Jr."         "Sen."        "U.S."        "Rep."       
    ## [16] "Sen."        "Gov."        "Jan."        "Feb."        "Mar."       
    ## [21] "Apr."        "Aug."        "Sep."        "Oct."        "Nov."       
    ## [26] "Dec."        "Reps."

``` r
tif_sentences <- tif_paragraphs |>
  textpress::nlp_split_sentences(text_hierarchy = c('doc_id', 'paragraph_id'))
```

``` r
tif_sentences |> head() |> knitr::kable()
```

| doc_id | paragraph_id | sentence_id | text                                                                                                                                                                                                                                                                 |
|:--|:---|:---|:------------------------------------------------------------|
| 1      | 1            | 1           | President Joe Biden hopes the latest jobs report will help convince voters that the economy is thriving under his policies, but a thorough look at the data released last week by the Bureau of Labor Statistics shows the economy is far weaker than he says it is. |
| 1      | 2            | 1           | The headline numbers of 300,000 jobs created and an unemployment rate under 4% look solid.                                                                                                                                                                           |
| 1      | 2            | 2           | But the growth is in part-time jobs.                                                                                                                                                                                                                                 |
| 1      | 2            | 3           | There are more full-time jobs but only in nonproductive sectors, such as government and government-subsidized healthcare.                                                                                                                                            |
| 1      | 3            | 1           | Bidenomics seems only to be working for part-time, mostly foreign workers.                                                                                                                                                                                           |
| 1      | 3            | 2           | The rest of the population is out of luck as prices rise and borrowing costs make American dream essentials, such as a house and a car, less affordable than ever.                                                                                                   |

### Tokenization

``` r
tokens <- tif_sentences |> textpress::nlp_tokenize_text()
```

    ## $`1.1.1`
    ##  [1] "President"  "Joe"        "Biden"      "hopes"      "the"       
    ##  [6] "latest"     "jobs"       "report"     "will"       "help"      
    ## [11] "convince"   "voters"     "that"       "the"        "economy"   
    ## [16] "is"         "thriving"   "under"      "his"        "policies"  
    ## [21] ","          "but"        "a"          "thorough"   "look"      
    ## [26] "at"         "the"        "data"       "released"   "last"      
    ## [31] "week"       "by"         "the"        "Bureau"     "of"        
    ## [36] "Labor"      "Statistics" "shows"      "the"        "economy"   
    ## [41] "is"         "far"        "weaker"     "than"       "he"        
    ## [46] "says"       "it"         "is"         "."

### Cast tokens to a data frame

``` r
dtm <- tokens |> 
  textpress::nlp_cast_tokens() |>
  
  tidyr::separate(col = 'id', 
                  into = c('doc_id', 'paragraph_id', 'sentence_id'), 
                  sep = '\\.')

dtm |> slice(1:10) |> knitr::kable()
```

| doc_id | paragraph_id | sentence_id | token     |
|:-------|:-------------|:------------|:----------|
| 1      | 1            | 1           | President |
| 1      | 1            | 1           | Joe       |
| 1      | 1            | 1           | Biden     |
| 1      | 1            | 1           | hopes     |
| 1      | 1            | 1           | the       |
| 1      | 1            | 1           | latest    |
| 1      | 1            | 1           | jobs      |
| 1      | 1            | 1           | report    |
| 1      | 1            | 1           | will      |
| 1      | 1            | 1           | help      |

## Search text

``` r
search_results <- tif_sentences |>
  
  textpress::sem_search_corpus(
    search = "unemployment rate",
    highlight = c("<b>", "</b>"),
    context_size = 1,
    cores = 1,
    is_inline = F
  )
```

``` r
search_results |>
  select(doc_id:text) |>
  sample_n(10) |>
  arrange(doc_id) |>
  knitr::kable(escape = F)
```

| doc_id | paragraph_id | sentence_id | text                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|:-|:--|:--|:---------------------------------------------------------------|
| 12     | 5            | 1           | Take the <b>unemployment rate</b>. It is a ratio of those seeking work to the whole active labor force.                                                                                                                                                                                                                                                                                                                                                                                             |
| 12     | 5            | 6           | Conversely, if unemployment was low or falling, most workers felt reasonably secure. The <b>unemployment rate</b>, back then, was a reasonable indicator of distress or well-being.                                                                                                                                                                                                                                                                                                                 |
| 13     | 28           | 2           | Between February 2020 and February 2024, California’s payroll jobs have increased by 1.7%, half of the national job growth rate. The <b>unemployment rate</b> in California in February was 5.3%, compared with 3.9% for the U.S as a whole, although the state Finance Department’s chief economist, Somjita Mitra, said California’s share of long-term unemployed is comparatively much smaller.                                                                                                 |
| 18     | 59           | 2           | Federal Reserve Economic Data (FRED), Federal Reserve Bank of St. Louis. “<b>Unemployment Rate</b>.”                                                                                                                                                                                                                                                                                                                                                                                                |
| 35     | 4            | 1           | On Friday, Biden flew the Bidenomics banner in Allentown, Pennsylvania, the onetime steel and manufacturing hub that suffered the fallout of deindustrialization, but has seen a revival in recent years, with an <b>unemployment rate</b> the White House says is now at a 30-year low.                                                                                                                                                                                                            |
| 49     | 11           | 3           | In January, the University of Michigan saw the largest two-month jump in its consumer sentiment index since the end of the Gulf War in 1991. News coverage, which throughout 2023 relentlessly forecast a recession, now touts the prospect of a “soft landing” — that is, a successful battle against inflation without an increase in the <b>unemployment rate</b> or a general economic slowdown.                                                                                                |
| 70     | 18           | 2           | What’s more, people’s basic factual sense of both economic conditions and Biden’s role is woeful. The <b>unemployment rate</b> is at historically low levels, and the U.S. economy is growing faster than most other economies on the world, but polls show most people think the reverse is true. The public has very little awareness of Biden’s main accomplishments, which are (when defined in neutral terms) extremely popular.                                                               |
| 71     | 8            | 1           | Meanwhile, the <b>unemployment rate</b> of 3.7% is at a 54-year low, and the unemployment rate has stayed below 4% for the longest stretch in the last 50 years despite the Fed raising interest rates from 0 to 5.5% in a year. The last time this nation saw such good employment news, LBJ was the president and Bonanza was the top show on TV.                                                                                                                                                 |
| 71     | 8            | 1           | Meanwhile, the unemployment rate of 3.7% is at a 54-year low, and the <b>unemployment rate</b> has stayed below 4% for the longest stretch in the last 50 years despite the Fed raising interest rates from 0 to 5.5% in a year. The last time this nation saw such good employment news, LBJ was the president and Bonanza was the top show on TV.                                                                                                                                                 |
| 8      | 16           | 2           | When money is injected into the economy at low cost, businesses can use these dollars to expand and most notably hire more jobs. However, if you look at the recent trends in states like California, where unemployment last month was at 5.1%, and Nevada at 5.3%, the recent jobs report showing unemployment at 3.9% is the beginning of the curve in my view toward a 5% <b>unemployment rate</b> again because you simply can’t keep printing money to make the employment picture look good. |

## Retrieval-augmented generation

### Sentence Window Retrieval

``` r
## chunk_id output is presently concatenated -- 

tif_chunks <- tif_sentences |>
  textpress::nlp_build_chunks(
    text_hierarchy = c('doc_id', 'paragraph_id', 'sentence_id'),
    chunk_size = 2,
    context_size = 1
  )
```

``` r
set.seed(99)
tif_chunks |>
  sample_n(3) |>
  select(-chunk) |>
  knitr::kable(escape = F)
```

| doc_id | paragraph_id | chunk_id | chunk_plus_context                                                                                                                                                                                                                                                                                            |
|:--|:---|:--|:--------------------------------------------------------------|
| 51     | 22           | 51.22.1  | Norway carefully managed the transition. A national library was set up, creating public sector jobs (it uses the mountains bordering the local fjord for naturally climate-controlled book storage). The government helped to re-educate steelworkers for new roles.                                          |
| 69     | 4            | 69.4.3   | Yet inflation is down sharply, from a peak of 8.9% in 2022 to 3.4% now. Many prices that went up are still up, especially for staples such as food and rent. But incoming data shows that consumer worries about inflation are easing, as if they’re finally starting to believe inflation is on the way out. |
| 14     | 3            | 14.3.1   | “Indexes for shelter, motor vehicle insurance, medical care, apparel, and personal care all rose in March,” the U.S. Bureau of Labor Statistics (BLS) noted. In contrast, prices for used cars and trucks, along with new vehicles and recreation, declined.                                                  |

### HuggingFace embeddings

> API call – for lightweight embedding building. DEmo, etc. Easy enough
> to —

``` r
api_url <- "https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2"

vstore <- tif_chunks  |>
  rename(text = chunk) |> ## !!!!
  textpress::api_huggingface_embeddings(#text_hierarchy = c('doc_id', 'paragraph_id', 'sentence_id'),
                                        text_hierarchy = c('chunk_id'),
                                        api_token = api_token,
                                        api_url = api_url)
```

    ##   |                                                                              |                                                                      |   0%  |                                                                              |========                                                              |  11%  |                                                                              |================                                                      |  22%  |                                                                              |=======================                                               |  33%  |                                                                              |===============================                                       |  44%  |                                                                              |=======================================                               |  56%  |                                                                              |===============================================                       |  67%  |                                                                              |======================================================                |  78%  |                                                                              |==============================================================        |  89%  |                                                                              |======================================================================| 100%

``` r
## Error in dimnames(x) <- dn :   length of 'dimnames' [1] not equal to array extent
```

### Semantic search

``` r
q <- "What are the core tenets of Bidenomics?"
```

``` r
query <- textpress::api_huggingface_embeddings(query = q,
                                               api_token = api_token,
                                               api_url = api_url)

rags <- textpress::sem_nearest_neighbors(
  x = query,
  matrix = vstore,
  n = 10
) |>
  left_join(tif_chunks, by = c("term2" = "chunk_id"))

rags |>
  select(cos_sim:chunk) |>
  knitr::kable()
```

| cos_sim | doc_id | paragraph_id | chunk                                                                                                                                                                                                                                                                                                                                                                        |
|--:|:--|:---|:---------------------------------------------------------------|
|   0.748 | 18     | 32           | The three key pillars of Bidenomics are investments in American infrastructure, clean energy, and business; empowerment of workers in the middle and lower classes; and promoting competition across businesses and sectors.                                                                                                                                                 |
|   0.745 | 18     | 7            | In response to these challenges, Bidenomics focuses on the core goals of public investment, worker empowerment, and promoting competition. Below, we take a closer look at each of these central pillars of Bidenomics.                                                                                                                                                      |
|   0.716 | 18     | 33           | Bidenomics refers to the broad set of economic policies and actions instituted under President Joe Biden. Broadly, these include efforts to invest heavily in American infrastructure, green energy initiatives, domestic manufacturing, and related areas.                                                                                                                  |
|   0.710 | 18     | 8            | The first focal point of Bidenomics is on investment in American business and infrastructure. Specifically, it includes investments in clean energy and related industries, a push to increase semiconductor manufacturing in the United States, and funds to update, improve, and build out additional infrastructure across the country.                                   |
|   0.700 | 33     | 4            | Last week, the president gave a speech on “Bidenomics” in hopes that the term will lodge in voters’ minds ahead of the 2024 elections. But what is Bidenomics?                                                                                                                                                                                                               |
|   0.690 | 18     | 2            | Bidenomics refers to the broad economic platform that President Biden campaigned on prior to the 2020 election and on which he remains focused heading into the 2024 election. This platform includes provisions to extend healthcare access, increase taxes for the wealthy, make major investments in green energy and other infrastructure, and support the middle class. |
|   0.678 | 6      | 11           | There are three basic problems with Bidenomics: (1) it is unconstitutional, (2) it is misguided, and (3) it is self-defeating.                                                                                                                                                                                                                                               |
|   0.677 | 35     | 38           | Biden’s team has worked since then to provide a firmer definition – including in multi-part social media posts and photos shared online of the president explaining the theory at a whiteboard – but one aspect of his comment endures: Bidenomics is defined in part by what it is not.                                                                                     |
|   0.671 | 18     | 15           | The final pillar of Bidenomics is the promotion of competition to help small businesses and others to lower costs. These efforts are predicated on the belief that higher rates of competition across sectors will lead to lower customer costs and higher wages for workers.                                                                                                |
|   0.661 | 18     | 6            | The White House describes the goal of Bidenomics as “building the economy from the middle out and the bottom up.” The platform is founded on the belief that elements of U.S. economic policy in recent decades fostered inequality, shocks including the Great Recession, a slow pace of growth, and an exacerbation of climate change.                                     |

### Chat completion via OpenAI

``` r
prompt1 <- 'BASED ON contexts below, provide a 10 point summary of the core tenets of Bidenomics.  

Provide the response in JSON array format. JSON array should include TEN key-response pairs. A simple, incomplete example below:

[{"Point_number": "1", "Point": "Example summary"}, {"Point_number": "2", "Point": "Example summary"}, {"Point_number": "3", "Point": "Example summary"}]

Ensure there is no trailing comma after the last element.

DO NOT include the "```json " code block notation in the output.


CONTEXTS:
'

prompt1 |> textpress::nlp_pretty_text()
```

    ## BASED ON contexts below, provide a 10 point
    ## summary of the core tenets of Bidenomics.
    ## 
    ## Provide the response in JSON array format. JSON
    ## array should include TEN key-response pairs. A
    ## simple, incomplete example below:
    ## 
    ## [{"Point_number": "1", "Point": "Example
    ## summary"}, {"Point_number": "2", "Point":
    ## "Example summary"}, {"Point_number": "3",
    ## "Point": "Example summary"}]
    ## 
    ## Ensure there is no trailing comma after the last
    ## element.
    ## 
    ## DO NOT include the "```json " code block notation
    ## in the output.
    ## 
    ## CONTEXTS:

``` r
rags_json <- rags |> select(term2, chunk_plus_context) |> jsonlite::toJSON()
rags_json |> textpress::nlp_pretty_text(char_length = 1000)
```

    ## [{"term2":"18.32.1","chunk_plus_context":"The
    ## three key pillars of Bidenomics are investments
    ## in American infrastructure, clean energy, and
    ## business; empowerment of workers in the middle
    ## and lower classes; and promoting competition
    ## across businesses and
    ## sectors."},{"term2":"18.7.1","chunk_plus_context":"In
    ## response to these challenges, Bidenomics focuses
    ## on the core goals of public investment, worker
    ## empowerment, and promoting competition. Below, we
    ## take a closer look at each of these central
    ## pillars of
    ## Bidenomics."},{"term2":"18.33.1","chunk_plus_context":"Bidenomics
    ## refers to the broad set of economic policies and
    ## actions instituted under President Joe Biden.
    ## Broadly, these include efforts to invest heavily
    ## in American infrastructure, green energy
    ## initiatives, domestic manufacturing, and related
    ## areas. They also include a set of tax policies
    ## aiming to reduce taxes for middle-class workers
    ## and increase tax rates for wealthy individuals
    ## and large corporations."},{"term2":"18.8.1","chun

``` r
messages = list(
    list(
        "role" = "system",
        "content" = "You are an economist."
        ),
    
    list(
        "role" = "user",
        "content" = paste(prompt1, rags_json, sep = '\n\n')
        )
    )
```

``` r
ten_points <- textpress::api_openai_chat_completions(messages = messages)

ten_points |> jsonlite::fromJSON() |> knitr::kable()
```

| Point_number | Point                                                                                                                                     |
|:------|:----------------------------------------------------------------|
| 1            | Bidenomics focuses on investments in American infrastructure, clean energy, and businesses to drive economic growth.                      |
| 2            | Worker empowerment is a key pillar, aiming to support the middle and lower classes to enhance economic opportunities.                     |
| 3            | Promotion of competition across businesses and sectors is central to Bidenomics to lower costs and increase wages.                        |
| 4            | Public investment is a core goal, supporting areas such as infrastructure, green energy, and domestic manufacturing.                      |
| 5            | Tax policies under Bidenomics seek to reduce taxes for the middle class and increase rates for the wealthy and large corporations.        |
| 6            | Bidenomics is defined by efforts to build the economy from the middle out and the bottom up, addressing past economic inequalities.       |
| 7            | The focus on competition aims to benefit small businesses while lowering costs for consumers.                                             |
| 8            | Bidenomics revolves around increasing investments in clean energy initiatives and semiconductor manufacturing in the U.S.                 |
| 9            | Bidenomics platform includes provisions to extend healthcare access and support the middle class.                                         |
| 10           | Some criticisms suggest Bidenomics is unconstitutional, misguided, and self-defeating, highlighting differing viewpoints on the policies. |

## Summary
