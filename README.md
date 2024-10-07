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

| raw_url                                                                                                                                                                                                                                                                                          |
|:-----------------------------------------------------------------------|
| <https://www.forbes.com/councils/forbesbusinesscouncil/2024/10/01/the-role-of-ai-in-shaping-the-future-of-education/>                                                                                                                                                                            |
| <https://cbsaustin.com/news/local/ut-symposium-explores-ethical-ai-innovation-in-year-of-ai-initiative>                                                                                                                                                                                          |
| <https://www.zdnet.com/article/pearson-launches-new-ai-certification-with-focus-on-practical-use-in-the-workplace/>                                                                                                                                                                              |
| <https://www.bworldonline.com/technology/2024/10/03/625403/ai-in-higher-education-bridging-students-and-educators-views/>                                                                                                                                                                        |
| <https://www.windowscentral.com/software-apps/california-governor-vetos-ai-safety-bill-because-it-establishes-a-regulatory-framework-that-could-give-the-public-a-false-sense-of-security-and-applies-stringent-standards-to-even-the-most-basic-functions-so-long-as-a-large-system-deploys-it> |

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

| id     | pattern             | text                                                                                                                                                                                                                                                                                        |
|:--|:-----|:---------------------------------------------------------------|
| 20.3.1 | higher education    | According to the 2024 EDUCAUSE AI Landscape study, most <b>higher education</b> institutions are working on AI-related strategic planning with goals primarily focused on preparing students for the future workforce (64%) and exploring new methods of teaching and learning (63%).       |
| 5.10.1 | higher education    | Much has been made of plagiarism concerns around the use of ChatGPT in education, and there’s no doubt that generative AI technology will impact the role of writing both in <b>higher education</b> and in society in general.                                                             |
| 15.4.2 | secondary education | “It underscores the urgent need to address the looming AI knowledge gap in schools—for both students and teachers—to raise parental awareness and increase their involvement in AI conversations, and push for stronger AI integration in American primary and <b>secondary education</b>.” |
| 20.2.1 | higher education    | Artificial intelligence has permeated nearly every industry, and <b>higher education</b> is no exception.                                                                                                                                                                                   |
| 1.7.1  | Higher education    | <b>Higher education</b> is facing serious challenges.                                                                                                                                                                                                                                       |

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

| id      | cos_sim | chunk_plus_context                                                                                                                                                                                                                                                                                                       |
|:--|--:|:-----------------------------------------------------------------|
| 13.10.2 |   0.844 | 1\. Personalized learning: AI can analyze data to understand each student’s learning style, strengths and areas for improvement. For example, an AI-driven platform could identify that a particular student struggles with reading comprehension and then provide tailored exercises that improve the student’s skills. |
| 6.8.2   |   0.836 | There’s a better way. This is where AI-assisted learning steps in to create personalized lesson plans. In our schools, we’ve transformed the traditional teacher’s role into that of a “guide.”                                                                                                                          |
| 20.2.2  |   0.835 | Artificial intelligence has permeated nearly every industry, and higher education is no exception. AI-powered solutions promise to revolutionize learning by providing personalized and adaptive experiences.                                                                                                            |
| 20.7.5  |   0.810 | Consider how new tools integrate with existing platforms and map to the entire learner lifecycle. AI should simplify, not complicate, the student experience. With thoughtful implementation, these intelligent technologies can personalize learning and improve outcomes from start to finish.                         |
| 6.10.1  |   0.810 | AI is revolutionizing the role of teachers by excelling at delivering personalized learning experiences. These advanced AI programs can swiftly and accurately pinpoint what a student knows and doesn’t know in each subject, allowing lessons to be designed around their unique aptitudes without any judgment.       |

## Summary
