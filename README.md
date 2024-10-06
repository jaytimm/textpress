[![R build
status](https://github.com/jaytimm/textpress/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/textpress/actions)

textpress

A lightweight, versatile NLP package for R, focused on search-centric
workflows with minimal dependencies and easy data-frame integration.
This package provides key functionalities for:

-   Web Search: Conduct searches based on user-defined queries to find
    relevant URLs.

-   Web Scraping: Extract content from the identified URLs, enabling
    efficient collection of text data from web pages.

-   Text Processing: Clean, tokenize, and preprocess both scraped and
    existing text data to prepare it for analysis.

-   Corpus Search: Conduct keyword, phrase, and pattern-based searches
    on processed corpora, utilizing traditional methods (e.g., KWIC) and
    advanced embeddings.

-   Embedding Generation for Semantic Search: Generate embeddings using
    the HuggingFace API for enhanced semantic search.

Ideal for users who need a basic, unobtrusive NLP toolkit in R.

## Installation

``` r
devtools::install_github("jaytimm/textpress")
```

## Usage

## Web search

``` r
sterm <- 'AI and education'

yresults <- textpress::web_search(search_term = sterm, 
                                  search_engine = "Yahoo News", 
                                  num_pages = 5)

yresults |> sample_n(10) |> knitr::kable()
```

| search_engine | raw_url                                                                                                                                                                                   |
|:-----|:-----------------------------------------------------------------|
| Yahoo News    | <https://gulfbusiness.com/ai-is-transforming-healthcare-heres-how/>                                                                                                                       |
| Yahoo News    | <https://www.denverpost.com/2024/10/06/ai-surveillance-colorado-schools-cameras-security-technology/>                                                                                     |
| Yahoo News    | <https://www.sandiegouniontribune.com/2024/10/03/opinion-carefully-applied-generative-ai-can-elevate-education-for-everyone/>                                                             |
| Yahoo News    | <https://www.digitaljournal.com/pr/news/vehement-media/growth-expert-launches-ai-powered-education-1956765301.html>                                                                       |
| Yahoo News    | <https://natlawreview.com/article/decoding-californias-recent-flurry-ai-laws>                                                                                                             |
| Yahoo News    | <https://campustechnology.com/Articles/2023/04/06/What-the-Past-Can-Teach-Us-About-the-Future-of-AI-and-Education.aspx>                                                                   |
| Yahoo News    | <https://www.etfdailynews.com/2024/09/30/tal-education-group-sees-unusually-high-options-volume-nysetal/>                                                                                 |
| Yahoo News    | <https://www.forbes.com/sites/shalinjyotishi/2024/09/30/labor-unions-and-community-colleges-can-promote-ai-literacy/>                                                                     |
| Yahoo News    | <https://okcfox.com/news/local/oklahoma-lawmakers-explore-potential-of-ai-integration-education-healthcare-criminal-justice-government-jeff-boatman-artificial-intellgence-interim-study> |
| Yahoo News    | <https://ics.uci.edu/2024/10/03/learning-tools-ai-and-the-future-of-writing-instruction/>                                                                                                 |

## Web Scraping

``` r
arts <- yresults$raw_url |> textpress::web_scrape_urls(cores = 4)
```

## Basic NLP: text processing

`nlp_split_paragraphs()` \< `nlp_split_sentences()` \<
`nlp_build_chunks()`

``` r
articles <- arts |>  
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

| id    | chunk                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|:-|:-------------------------------|:--------------------------------------|
| 1.1.1 | ‘TO AI OR NOT TO AI?’ This is one of the most pressing questions that today’s educators and higher education leaders face.                                                                                                                                                                                                                                                                                                                                                   | ‘TO AI OR NOT TO AI?’ This is one of the most pressing questions that today’s educators and higher education leaders face. While there is no doubt that artificial intelligence (AI) will play an increasingly central role in people’s lives, many in the education sector remain skeptical — with some even deeming it a harbinger of educational doom.                                                                                                                                                                                                                         |
| 1.1.2 | While there is no doubt that artificial intelligence (AI) will play an increasingly central role in people’s lives, many in the education sector remain skeptical — with some even deeming it a harbinger of educational doom. In a study conducted by global educational technology or edtech leader Anthology, 30% or three in every 10 university leaders in the Philippines see generative AI as unethical and should be banned from being used in educational settings. | This is one of the most pressing questions that today’s educators and higher education leaders face. While there is no doubt that artificial intelligence (AI) will play an increasingly central role in people’s lives, many in the education sector remain skeptical — with some even deeming it a harbinger of educational doom. In a study conducted by global educational technology or edtech leader Anthology, 30% or three in every 10 university leaders in the Philippines see generative AI as unethical and should be banned from being used in educational settings. |
| 1.2.1 | “There are mixed reactions from educators with regards to AI in the classroom,” Bruce Dahlgren, CEO of Anthology, said in an exclusive statement shared with BusinessWorld. “We recently conducted a survey of university leaders and students in the Philippines about their perceptions of AI.                                                                                                                                                                             | “There are mixed reactions from educators with regards to AI in the classroom,” Bruce Dahlgren, CEO of Anthology, said in an exclusive statement shared with BusinessWorld. “We recently conducted a survey of university leaders and students in the Philippines about their perceptions of AI. It revealed that university leaders have certain reservations around allowing AI in higher education, perceiving it as being unethical.                                                                                                                                          |

## KWIC Search

``` r
sterm2 <- c('\\bhigher education\\b',
            '\\bsecondary education\\b')
            # '\\S+ education\\b',
            # '\\b\\w{4,}\\b education\\b')

kwics <- articles |>
  rename(text = chunk) |>
  textpress::sem_search_corpus(search = sterm2,
                               text_hierarchy = c('doc_id', 
                                                  'paragraph_id', 
                                                  'chunk_id'))

kwics |> select(doc_id:chunk_id, pattern, text) |> 
  sample_n(5) |> knitr::kable()
```

| doc_id | paragraph_id | chunk_id | pattern          | text                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|:-|:--|:--|:---|:------------------------------------------------------------|
| 11     | 5            | 1        | higher education | A handful of Colorado school districts and <b>higher education</b> institutions have implemented AI surveillance technologies in a bid to keep students safe, though a statewide moratorium has prevented the majority from doing so — though that could change next summer, when the prohibition ends.                                                                                                                                                |
| 19     | 3            | 1        | higher education | According to the 2024 EDUCAUSE AI Landscape study, most <b>higher education</b> institutions are working on AI-related strategic planning with goals primarily focused on preparing students for the future workforce (64%) and exploring new methods of teaching and learning (63%). To truly move the needle on educational transformation, educators need a holistic strategy that thoughtfully integrates people, processes, data, and technology. |
| 3      | 10           | 1        | higher education | The integration of AI in <b>higher education</b> is not just changing how we learn - it’s reshaping the value proposition of a college degree. As you navigate this new landscape, remember that the goal remains the same: to invest in an education that prepares you for a successful and fulfilling career.                                                                                                                                        |
| 1      | 2            | 2        | higher education | It revealed that university leaders have certain reservations around allowing AI in <b>higher education</b>, perceiving it as being unethical. Students, on the other hand, were optimistic about the role AI could play in increasing engagement and improving teaching and learning methods.”                                                                                                                                                        |
| 1      | 3            | 1        | higher education | The study conducted across 11 countries including the Philippines involved 5,000 <b>higher education</b> leaders and students. Key takeaways reveal that Filipino students have the highest level of confidence (54%) that AI will help enhance engagement and interactivity among peers.                                                                                                                                                              |

## Semantic search

### HuggingFace embeddings

``` r
api_url <- "https://api-inference.huggingface.co/models/BAAI/bge-base-en-v1.5"

vstore <- articles |>
  rename(text = chunk) |>
  textpress::api_huggingface_embeddings(text_hierarchy = c('doc_id', 
                                                           'paragraph_id',
                                                           'chunk_id'),
                                        verbose = F,
                                        api_url = api_url,
                                        dims = 768, #1024, 768, 384
                                        api_token = api_token)
```

### Embedd query

> “How can AI personalize learning experiences for students?”

``` r
q <- "How can AI personalize learning experiences for students?"

query <- textpress::api_huggingface_embeddings(
  query = q,
  api_url = api_url,
  dims = 768,
  api_token = api_token)
```

``` r
rags <- textpress::sem_nearest_neighbors(
  x = query,
  matrix = vstore,
  n = 20) |>
  left_join(articles, by = c("term2" = "id"))
```

### Relevant chunks

| cos_sim | doc_id | paragraph_id | chunk_id | chunk                                                                                                                                                                                                         |
|---:|:--|:----|:---|:--------------------------------------------------------|
|   0.831 | 13     | 10           | 1        | 1\. Personalized learning: AI can analyze data to understand each student’s learning style, strengths and areas for improvement.                                                                              |
|   0.827 | 6      | 8            | 1        | There’s a better way. This is where AI-assisted learning steps in to create personalized lesson plans.                                                                                                        |
|   0.804 | 19     | 7            | 3        | AI should simplify, not complicate, the student experience. With thoughtful implementation, these intelligent technologies can personalize learning and improve outcomes from start to finish.                |
|   0.794 | 19     | 2            | 1        | Artificial intelligence has permeated nearly every industry, and higher education is no exception. AI-powered solutions promise to revolutionize learning by providing personalized and adaptive experiences. |
|   0.793 | 6      | 15           | 2        | The popular language app showcases how AI-assisted learning can produce personalized lessons that are also fun. It tracks what each student already knows and customizes lessons to their level.              |

## –\> RAG/LLM
