# nlpx

A lightweight, versatile NLP companion in R.

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

## Tokenzation & tokens to df

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                       |
|:--|:---|:----------------------------------------------------------------|
| 5      | 1           | OpenAI on Thursday said that a major outage on its **artificial intelligence** chatbot, ChatGPT, was resolved.                                                                                                                                                                             |
| 8      | 14          | OpenAI recently added DALL-E 3, its most powerful version of an **artificial intelligence** image generator to date, to ChatGPT Plus and Enterprise subscriptions.                                                                                                                         |
| 9      | 1           | ChatGPT, an **artificial intelligence** (AI) chatbot that returns answers to written prompts, has been tested and found wanting by researchers at the University of Florida College of Medicine (UF Health) who looked into how well it could answer typical patient questions on urology. |
| 9      | 18          | Pathologists and clinical laboratory managers will want to monitor how developers improve the performance of chatbots and other applications using **artificial intelligence**.                                                                                                            |
| 11     | 146         | The Texas federal judge has added a requirement that any attorney appearing in his court must attest that “no portion of the filing was drafted by generative **artificial intelligence**,” or if it was, that it was checked “by a human being.”                                          |

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

| text_id | text                                                                                                                                                        |
|:----|:------------------------------------------------------------------|
| 11.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI . |
| 11.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                       |
| 13.69   | OpenAI first rolled out the ability to prompt ChatGPT with your voice and images in September , but it only made the feature available to paying users .    |
| 3.52    | Ask your closest friends and trusted team members to complete the square brackets in this prompt in ChatGPT and send you the result .                       |

## OpenAI embeddings

``` r
vstore <- df_ss |>
  mutate(words = tokenizers::count_words(text)) |>
  filter(words > 20, words < 60) |>
  mutate(batch_id = nlpx::nlp_batch_cumsum(x = words, threshold = 10000)) |>
  nlpx::nlp_fetch_openai_embs(text_id = 'text_id',
                              text = 'text',
                              batch_id = 'batch_id')
```

    ## [1] "Batch 1 of 2"
    ## [1] "Batch 2 of 2"

## Basic retrieval

``` r
query <- nlpx::nlp_fetch_openai_embs(query = 'Fears and risks associated with ChatGPT and the future?')

nlpx::nlp_find_neighbors(x = query, 
                         matrix = vstore, 
                         n = 5) |>
  
  left_join(df_ss, by = c('term2' = 'text_id')) |>
  select(cos_sim:text) |>
  knitr::kable()
```

| cos_sim | doc_id | sentence_id | text                                                                                                                                                              |
|---:|:---|-----:|:----------------------------------------------------------|
|   0.874 | 11     |          59 | An independent review from Common Sense Media, a nonprofit advocacy group, found that ChatGPT could potentially be harmful for younger users.                     |
|   0.871 | 7      |          19 | But for many, it was ChatGPT’s release as a free-to-use dialogue agent in November 2022 that quickly revealed this technology’s power and pitfalls.               |
|   0.863 | 1      |          27 | ChatGPT is becoming more capable at the same time that its underlying technology is destroying much of the web as we’ve known it.                                 |
|   0.859 | 7      |          41 | ChatGPT has a large environmental impact, problematic biases and can mislead its users into thinking that its output comes from a person, she says.               |
|   0.852 | 11     |         116 | “As you may know, the government has been tightening regulations associated with deep synthesis technologies (DST) and generative AI services, including ChatGPT. |
