[![](https://www.r-pkg.org/badges/version/textpress)](https://cran.r-project.org/package=textpress)

# textpress

A lightweight, versatile NLP package for R, focused on search-centric
workflows with minimal dependencies and easy data-frame integration.
This package provides key functionalities for:

-   **Web Search**: Perform search engine queries to retrieve relevant
    URLs.

-   **Web Scraping**: Extract URL content, including some relevant
    metadata.

-   **Text Processing & Chunking**: Segment text into meaningful units,
    eg, sentences, paragraphs, and larger chunks. Designed to support
    tasks related to retrieval-augmented generation (RAG).

-   **Corpus Search**: Perform keyword, phrase, and pattern-based
    searches across processed corpora, supporting both traditional
    in-context search techniques (e.g., KWIC, regex matching) and
    advanced semantic searches using embeddings.

-   **Embedding Generation**: Generate embeddings using the HuggingFace
    API for enhanced semantic search.

Ideal for users who need a basic, unobtrusive NLP toolkit in R.

## Installation

Get the released version from CRAN:

``` r
install.packages('textpress')
```

    ## Installing package into '/home/jtimm/R/x86_64-pc-linux-gnu-library/4.4'
    ## (as 'lib' is unspecified)

Or the development version from GitHub with:

``` r
# devtools::install_github("jaytimm/textpress")
remotes::install_github("jaytimm/textpress")
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

| raw_url                                                                                                               |
|:-----------------------------------------------------------------------|
| <https://www.forbes.com/sites/danfitzpatrick/2024/10/12/could-elon-musks-ai-robots-save-a-troubled-education-system/> |
| <https://medicalxpress.com/news/2024-10-dont-ai-chatbots-accurate-safe.html>                                          |
| <https://www.forbes.com/sites/bryanpenprase/2024/10/13/the-future-of-ai-and-india/>                                   |
| <https://www.forbes.com/sites/genacox/2024/10/13/3-ways-to-de-risk-ai-for-hiring-decisions-beyond-plug-and-play/>     |
| <https://www.dallasnews.com/business/2024/10/13/motley-fool-the-ship-hasnt-sailed-on-nvidia/>                         |

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

| id    | chunk                                                                                                                                                              | chunk_plus_context                                                                                                                                                                                                                                                                                                 |
|:-|:------------------------|:--------------------------------------------|
| 1.1.1 | In addition to its corporate applications, artificial intelligence is helping solve broader and more complex problems, especially in education.                    | In addition to its corporate applications, artificial intelligence is helping solve broader and more complex problems, especially in education. Industry leaders and policymakers should develop a shared approach to AI-powered learning and encourage more widespread training in the technology’s fundamentals. |
| 1.1.2 | Industry leaders and policymakers should develop a shared approach to AI-powered learning and encourage more widespread training in the technology’s fundamentals. | In addition to its corporate applications, artificial intelligence is helping solve broader and more complex problems, especially in education. Industry leaders and policymakers should develop a shared approach to AI-powered learning and encourage more widespread training in the technology’s fundamentals. |
| 1.2.1 | NEW YORK – Artificial intelligence has captured the imagination of corporate leaders eager to implement new tech solutions in their industries.                    | NEW YORK – Artificial intelligence has captured the imagination of corporate leaders eager to implement new tech solutions in their industries. But AI could also be applied to broader and more complex problems, especially in education.                                                                        |

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
  mutate(id = paste(doc_id, 
                    paragraph_id, 
                    chunk_id, 
                    sep = '.')) |>
  select(id, pattern, text) |> 
  sample_n(5) |> knitr::kable()
```

| id     | pattern          | text                                                                                                                                                                                                                                                                                                                                                                                                  |
|:--|:---|:-----------------------------------------------------------------|
| 7.13.1 | higher education | “We chose our theme for the conference; we are really hyped about the theme because it really aligns with the mission at our own institution as well as what we feel is the theme for <b>higher education</b> right now, and really trying to take it to the next level and launch our practice to methods that will help our students to soar and succeed,” says Andrea Liles, Rhodes State College. |
| 2.2.1  | higher education | The Indian government’s multifaceted approach includes building an AI ecosystem that leverages resources in <b>higher education</b>, research and industry.                                                                                                                                                                                                                                           |
| 10.7.2 | higher education | Advancements in generative AI make it possible to develop focused, role-specific cybersecurity training for a variety of users in <b>higher education</b>, the report notes.                                                                                                                                                                                                                          |
| 7.11.1 | higher education | The theme for this year’s conference was Rocket Education: Ignite, Launch, Soar as <b>higher education</b> continues to evolve to meet the needs of the students.                                                                                                                                                                                                                                     |
| 10.1.1 | higher education | AI governance, AI-enabled workforce expansion, and AI-supported cybersecurity training are three of the six key technologies and practices anticipated to have a significant impact on the future of cybersecurity and privacy in <b>higher education</b>, according to the latest Cybersecurity and Privacy edition of the Educause Horizon Report.                                                  |

## Semantic search

### HuggingFace embeddings

``` r
api_url <- "https://api-inference.huggingface.co/models/BAAI/bge-base-en-v1.5"

vstore <- articles |>
  rename(text = chunk) |>
  textpress::api_huggingface_embeddings(
    text_hierarchy = c('doc_id', 
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

| id      | cos_sim | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|:--|--:|:------------------------------------------------------------------|
| 13.24.1 |   0.790 | In virtual classrooms, AI tutors welcome students, offering personalized, one-on-one learning experiences. If a student asks a question via text or voice during the lesson, the AI tutor can respond immediately.                                                                                                                                                                                                                                 |
| 4.2.1   |   0.755 | With AI enabled Classwork module generation, educators can get assistance creating a course outline and drafting modules and descriptions based on the subject, student grade level, and class learning objectives. The educator is always in the driver’s seat and can choose to edit, delete, or regenerate modules before adding them to Classwork.                                                                                             |
| 1.6.4   |   0.741 | Others say they simply do not know where to begin. That is where generative AI comes in: it can recommend coursework that matches learners’ levels and interests, and offer real-time feedback as they move through the material. AI-powered solutions can even pair students with mentors who can advise them on higher education and career progression.                                                                                         |
| 1.11.4  |   0.734 | As IBM’s Chief Impact Officer, I will be asking how my organization can ensure that students, teachers, employees, and job-seekers are benefiting from these advances. Although we have taken a step in that direction with IBM SkillsBuild, shaping the industries and jobs of the future requires a host of AI-powered features and programs that can provide learners with personalized educational experiences over the course of their lives. |
| 19.16.2 |   0.726 | In customer support, AI can improve ticket routing to the appropriate department or agent. AI can use past interactions and customer data for tailored responses and recommendations. And AI can evaluate and interpret emotions from customer communications.                                                                                                                                                                                     |

## Summary
