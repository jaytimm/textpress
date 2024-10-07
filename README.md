[![R build
status](https://github.com/jaytimm/textpress/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/textpress/actions)

# textpress

A lightweight, versatile NLP package for R, focused on search-centric
workflows with minimal dependencies and easy data-frame integration.
This package provides key functionalities for:

-   **Web Search**: Conduct searches based on user-defined queries to
    find relevant URLs.

-   **Web Scraping**: Extract content from provided URLs, including
    relevant metadata.

-   **Text Processing & Chunking**: Identify and segment text into
    meaningful units such as sentences, paragraphs, and larger chunks,
    facilitating content-aware processing. Designed to support tasks
    related to retrieval-augmented generation (RAG).

-   **Corpus Search**: Perform keyword, phrase, and pattern-based
    searches across processed corpora, supporting both traditional
    in-context search techniques (e.g., KWIC, regex matching) and
    advanced semantic searches using embeddings.

-   **Embedding Generation**: Generate embeddings using the HuggingFace
    API for enhanced semantic search.

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

yresults |> select(2) |>  sample_n(5) |> knitr::kable()
```

| raw_url                                                                                                                                           |
|:-----------------------------------------------------------------------|
| <https://gulfbusiness.com/ai-is-transforming-healthcare-heres-how/>                                                                               |
| <https://natlawreview.com/article/decoding-californias-recent-flurry-ai-laws>                                                                     |
| <https://www.sandiegouniontribune.com/2024/10/03/opinion-carefully-applied-generative-ai-can-elevate-education-for-everyone/>                     |
| <https://www.forbes.com/councils/forbestechcouncil/2024/10/02/how-ai-is-changing-the-role-of-teachers-in-education/>                              |
| <https://www.latimes.com/socal/daily-pilot/opinion/story/2024-10-02/apodaca-with-its-need-for-energy-ai-presents-strong-environmental-challenges> |

## Web Scraping

``` r
arts <- yresults$raw_url |> 
  textpress::web_scrape_urls(cores = 4)
```

## Text Processing & Chunking

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
                              chunk_size = 1,
                              context_size = 1) |>
  
  mutate(id = paste(doc_id, paragraph_id, chunk_id, sep = '.'))
```

| id    | chunk                                                                                                                                                                                                                          | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|:-|:--------------------|:-------------------------------------------------|
| 1.1.1 | ‘TO AI OR NOT TO AI?’                                                                                                                                                                                                          | ‘TO AI OR NOT TO AI?’ This is one of the most pressing questions that today’s educators and higher education leaders face.                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| 1.1.2 | This is one of the most pressing questions that today’s educators and higher education leaders face.                                                                                                                           | ‘TO AI OR NOT TO AI?’ This is one of the most pressing questions that today’s educators and higher education leaders face. While there is no doubt that artificial intelligence (AI) will play an increasingly central role in people’s lives, many in the education sector remain skeptical — with some even deeming it a harbinger of educational doom.                                                                                                                                                                                                                         |
| 1.1.3 | While there is no doubt that artificial intelligence (AI) will play an increasingly central role in people’s lives, many in the education sector remain skeptical — with some even deeming it a harbinger of educational doom. | This is one of the most pressing questions that today’s educators and higher education leaders face. While there is no doubt that artificial intelligence (AI) will play an increasingly central role in people’s lives, many in the education sector remain skeptical — with some even deeming it a harbinger of educational doom. In a study conducted by global educational technology or edtech leader Anthology, 30% or three in every 10 university leaders in the Philippines see generative AI as unethical and should be banned from being used in educational settings. |

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

kwics |> 
  mutate(id = paste(doc_id, paragraph_id, chunk_id, sep = '.')) |>
  select(id, pattern, text) |> 
  sample_n(5) |> knitr::kable()
```

| id      | pattern          | text                                                                                                                                                                                                                                                               |
|:--|:-----|:---------------------------------------------------------------|
| 3.8.2   | higher education | In fact, one McKinsey Global Institute report suggests that AI could help reduce administrative costs in <b>higher education</b> by up to 30% through automation of routine tasks.                                                                                 |
| 31.19.2 | higher education | While confidence in <b>higher education</b> is in decline, public support for community colleges is still strong.                                                                                                                                                  |
| 1.3.1   | higher education | The study conducted across 11 countries including the Philippines involved 5,000 <b>higher education</b> leaders and students.                                                                                                                                     |
| 1.2.3   | higher education | It revealed that university leaders have certain reservations around allowing AI in <b>higher education</b>, perceiving it as being unethical.                                                                                                                     |
| 4.2.1   | Higher Education | In 1998, noted technology critic and historian of automation David Noble published his influential article “Digital Diploma Mills: The Automation of <b>Higher Education</b>,” in which he warned about the negative impacts the internet would have on education. |

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

| id      | cos_sim | chunk                                                                                                                        |
|:----|----:|:-------------------------------------------------------------|
| 13.10.2 |   0.844 | Personalized learning: AI can analyze data to understand each student’s learning style, strengths and areas for improvement. |
| 6.8.2   |   0.836 | This is where AI-assisted learning steps in to create personalized lesson plans.                                             |
| 20.2.2  |   0.835 | AI-powered solutions promise to revolutionize learning by providing personalized and adaptive experiences.                   |
| 20.7.5  |   0.810 | AI should simplify, not complicate, the student experience.                                                                  |
| 6.10.1  |   0.810 | AI is revolutionizing the role of teachers by excelling at delivering personalized learning experiences.                     |

## Summary
