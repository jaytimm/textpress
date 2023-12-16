# nlpx

A lightweight, versatile NLP companion in R. The package integrates
easily with common R tools and provides essential features like text
processing and corpus search, as well as a functionality for building
text embeddings via OpenAI. Ideal for users who need a basic,
unobtrusive NLP tool in R.

## Installation

``` r
devtools::install_github("jaytimm/nlpx")
```

## Some data

``` r
library(dplyr)
mm <- quicknews::qnews_build_rss(x = 'ChatGPT') |>
  quicknews::qnews_parse_rss() |>
  mutate(url = quicknews::qnews_get_rurls(link))

articles <- quicknews::qnews_extract_article(
  x = mm$url[1:25], cores = 3) |>
  left_join(mm)
```

## Split sentences

``` r
df_ss <- articles |>
  mutate(doc_id = row_number()) |>
  nlpx::nlp_split_sentences() 

df_ss |> slice(1:5) |> knitr::kable()
```

| doc_id | sentence_id | text_id | text                                                                                                                                                                                    |
|:---|----:|:---|:-----------------------------------------------------------|
| 1      |           1 | 1.1     | What does life online look like filtered through a bot?                                                                                                                                 |
| 1      |           2 | 1.2     | There is a tension at the heart of ChatGPT that may soon snap.                                                                                                                          |
| 1      |           3 | 1.3     | Does the technology expand our world or constrain it?                                                                                                                                   |
| 1      |           4 | 1.4     | Which is to say, do AI-powered chatbots open new doors to learning and discovery, or do they instead risk siloing off information and leaving us stuck with unreliable access to truth? |
| 1      |           5 | 1.5     | Earlier today, OpenAI, the maker of ChatGPT, announced a partnership with the media conglomerate Axel Springer that seems to get us closer to an answer.                                |

## Tokenization

``` r
df <- df_ss |>
  nlpx::nlp_tokenize_text() |>
  nlpx::nlp_cast_tokens()

df |> head() |> knitr::kable()
```

| text_id | token  |
|:--------|:-------|
| 1.1     | What   |
| 1.1     | does   |
| 1.1     | life   |
| 1.1     | online |
| 1.1     | look   |
| 1.1     | like   |

## Search text

``` r
df_ss |>
  nlpx::nlp_search_corpus(search = 'artificial intelligence', 
                          highlight = c('**', '**'),
                          n = 0) |>
  
  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                              |
|:--|:----|:----------------------------------------------------------------|
| 5      | 1           | OpenAI on Thursday said that a major outage on its **artificial intelligence** chatbot, ChatGPT, was resolved.                                                                                                                                    |
| 9      | 146         | The Texas federal judge has added a requirement that any attorney appearing in his court must attest that “no portion of the filing was drafted by generative **artificial intelligence**,” or if it was, that it was checked “by a human being.” |
| 9      | 223         | ChatGPT is a general-purpose chatbot that uses **artificial intelligence** to generate text after a user enters a prompt, developed by tech startup OpenAI.                                                                                       |
| 10     | 14          | OpenAI recently added DALL-E 3, its most powerful version of an **artificial intelligence** image generator to date, to ChatGPT Plus and Enterprise subscriptions.                                                                                |
| 11     | 2           | Their findings, published in the journal Telematics and Informatics, suggest the potential for geographic biases existing in current generative **artificial intelligence** (AI) models.                                                          |

## Search df

``` r
df |>
  nlpx::nlp_search_df(search_col = 'token', 
                      id_col = 'text_id',
                      include = c('ChatGPT', 'prompt'),
                      logic = 'and',
                      exclude = NULL) |>
  
  group_by(text_id) |>
  summarize(text = paste0(token, collapse = ' ')) |>
  slice(1:5) |>
  knitr::kable()
```

| text_id | text                                                                                                                                                                                                                                                             |
|:---|:-------------------------------------------------------------------|
| 11.9    | Utilizing a list of the 3,108 counties in the contiguous United States , the research group asked the ChatGPT interface to answer a prompt asking about the environmental justice issues in each county .                                                        |
| 13.69   | OpenAI first rolled out the ability to prompt ChatGPT with your voice and images in September , but it only made the feature available to paying users .                                                                                                         |
| 2.15    | Give your notes to ChatGPT and prompt it to draft a meeting agenda or develop discussion points relevant to your unique goals for the meeting .                                                                                                                  |
| 2.19    | If you are struggling to create copy for your marketing outreach , video scripts , or email campaigns , simply give your ChatGPT custom instructions , then prompt it to create the marketing materials you need .                                               |
| 2.21    | Being specific and selective with the way you word your prompt ensures it produces marketing material that is consistent with your brand voice , so that it is not overly formal , or has way too many flamboyant adjectives ( a tell - tale sign of ChatGPT ) . |

## Search inline

## OpenAI embeddings

``` r
vstore <- df_ss |>
  mutate(words = tokenizers::count_words(text)) |>
  filter(words > 20, words < 60) |>
  mutate(batch_id = nlpx::nlp_batch_cumsum(x = words,
                                           threshold = 10000)) |>
  
  nlpx::nlp_fetch_openai_embs(text_id = 'text_id',
                              text = 'text',
                              batch_id = 'batch_id')
```

    ## [1] "Batch 1 of 2"
    ## [1] "Batch 2 of 2"

## Basic semantic search

``` r
q <- 'What are some concerns about the impact of advanced AI models like ChatGPT?'
```

``` r
query <- nlpx::nlp_fetch_openai_embs(query = q)

nlpx::nlp_find_neighbors(x = query, 
                         matrix = vstore, 
                         n = 5) |>
  
  left_join(df_ss, by = c('term2' = 'text_id')) |>
  select(cos_sim:text) |>
  knitr::kable()
```

| cos_sim | doc_id | sentence_id | text                                                                                                                                                                                       |
|---:|:---|----:|:-----------------------------------------------------------|
|   0.904 | 11     |          14 | With generative AI emerging as a new gateway tool for gaining information, the testing of potential biases in modeling outputs is an important part of improving programs such as ChatGPT. |
|   0.879 | 9      |         288 | But OpenAI is involved in at least one lawsuit that has implications for AI systems trained on publicly available data, which would touch on ChatGPT.                                      |
|   0.876 | 4      |          19 | But for many, it was ChatGPT’s release as a free-to-use dialogue agent in November 2022 that quickly revealed this technology’s power and pitfalls.                                        |
|   0.876 | 4      |          30 | Undisclosed AI-made content has begun to percolate through the Internet and some scientists have admitted using ChatGPT to generate articles without declaring it.                         |
|   0.876 | 12     |           4 | Google has been accused of lagging behind OpenAI’s ChatGPT, widely regarded as the most popular and powerful in the AI space.                                                              |
