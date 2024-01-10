# textpress

A lightweight, versatile NLP companion in R. Provides basic features for
(1) text processing, (2) corpus search, and (3) web scraping.
Additionally, the package provides (4) utility functions for building
basic Retrieval-Augmented Generation (RAG) systems, as well as
functionality for (5) building text embeddings via OpenAI. Ideal for
users who need a basic, unobtrusive NLP tool in R.

## Installation

``` r
devtools::install_github("jaytimm/textpress")
```

## Usage

## Web scraping

``` r
library(dplyr)
articles <- textpress::web_scrape_urls(x = 'ChatGPT',
                                       input = 'search',
                                       cores = 12) |>
  select(url, date:title, text) |>
  filter(!is.na(text)) |>
  slice(5:30)
```

## Text processing

### Split sentences

``` r
df_ss <- articles |>
  mutate(doc_id = row_number()) |>
  textpress::nlp_split_sentences()

df_ss |> slice(1:5) |> knitr::kable()
```

| doc_id | sentence_id | text_id | text                                                                                                                                                                              |
|:---|----:|:---|:-----------------------------------------------------------|
| 1      |           1 | 1.1     | Hey Android users, are you tired of Google’s neglect of Google Assistant?                                                                                                         |
| 1      |           2 | 1.2     | Well, one of Google’s biggest rivals, OpenAI’s ChatGPT, is apparently coming for the premium phone space occupied by Google’s voice assistant.                                    |
| 1      |           3 | 1.3     | Mishaal Rahman at Android Authority found that the ChatGPT app is working on support for Android’s voice assistant APIs and a system-wide overlay UI.                             |
| 1      |           4 | 1.4     | If the company rolls out this feature, users could set the ChatGPT app as the system-wide assistant app, allowing it to pop up anywhere in Android and respond to user questions. |
| 1      |           5 | 1.5     | ChatGPT started as a text-only generative AI but received voice and image input capabilities in September.                                                                        |

### Tokenization

``` r
tokens <- df_ss |> textpress::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "Hey"       "Android"   "users"     ","         "are"       "you"      
    ##  [7] "tired"     "of"        "Google's"  "neglect"   "of"        "Google"   
    ## [13] "Assistant" "?"

### Cast tokens to df

``` r
df <- tokens |> textpress::nlp_cast_tokens()
df |> head() |> knitr::kable()
```

| text_id | token   |
|:--------|:--------|
| 1.1     | Hey     |
| 1.1     | Android |
| 1.1     | users   |
| 1.1     | ,       |
| 1.1     | are     |
| 1.1     | you     |

## Search text

``` r
df_ss |>
  textpress::search_corpus(search = 'artificial intelligence',
                           highlight = c('<b>', '</b>'),
                           n = 0,
                           ## cores = 5,
                           is_inline = F) |>

  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                   |
|:---|:-----|:--------------------------------------------------------------|
| 4      | 2           | We explore the brief history of the generative <b>artificial intelligence</b> (AI) platform, reflect on its origins and its power to disrupt and transform operations. |
| 5      | 1           | Free TV company, Telly, debuted its new <b>artificial intelligence</b> voice assistant, “Hey Telly,” at CES 2024.                                                      |
| 7      | 4           | As someone studying <b>artificial intelligence</b> in education, I was curious: Could ChatGPT help?                                                                    |
| 17     | 1           | <b>Artificial Intelligence</b> (AI) has been making waves in many industries, and healthcare is no exception.                                                          |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token   | lemma   | upos  | xpos |
|:-------|------:|----:|--------:|:---------|:--------|:--------|:------|:-----|
| 1.1    |     1 |   3 |       1 | 1        | Hey     | hey     | INTJ  | UH   |
| 1.1    |     5 |  11 |       2 | 2        | Android | Android | PROPN | NNP  |
| 1.1    |    13 |  17 |       3 | 3        | users   | user    | NOUN  | NNS  |
| 1.1    |    19 |  19 |       4 | 4        | ,       | ,       | PUNCT | ,    |
| 1.1    |    21 |  23 |       5 | 5        | are     | be      | AUX   | VBP  |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "Hey/UH/1 Android/NNP/2 users/NNS/3 ,/,/4 are/VBP/5 you/PRP/6 tired/JJ/7 of/IN/8 Google's/NNPS/9 neglect/NN/10 of/IN/11 Google/NNP/12 Assistant/NNP/13 ?/./14"

### Search for lexico-grammatical pattern

``` r
inline_ss |>
  textpress::search_corpus(search = 'JJ and JJ',
                           highlight = c('<b>', '</b>'),
                           n = 0,
                           is_inline = T) |>

  select(doc_id:text) |>
  filter(tokenizers::count_words(text) < 75) |>
  slice(1:4) |>
  ## DT::datatable(escape = F)
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                             |
|:--|:---|:----------------------------------------------------------------|
| 10     | 10          | Still/RB/1 ,/,/2 these/DT/3 tools/NNS/4 are/VBP/5 pretty/RB/6 much/RB/7 <b>competitive/JJ/8 and/CC/9 helpful/JJ/10</b> ,/,/11 sometimes/RB/12 more/JJR/13 than/IN/14 CHatGPT/NNP/15 ././16                                                                                                       |
| 10     | 103         | To/IN/1 me/PRP/2 ,/,/3 it/PRP/4 sounds/VBZ/5 quite/RB/6 <b>realistic/JJ/7 and/CC/8 human/JJ/9</b> -/HYPH/10 like/UH/11 ././12                                                                                                                                                                    |
| 10     | 2           | Even/RB/1 if/IN/2 it/PRP/3 was/VBD/4 available/JJ/5 in/IN/6 early/JJ/7 2022/CD/8 ,/,/9 this/DT/10 year/NN/11 ,/,/12 people/NNS/13 get/VBP/14 used/VBN/15 to/IN/16 this/DT/17 tool/NN/18 in/IN/19 both/CC/20 their/PRP$/21 <b>professional/JJ/22 and/CC/23 personal/JJ/24</b> lives/NNS/25 ././26 |
| 10     | 3           | Even/RB/1 many/JJ/2 of/IN/3 us/PRP/4 are/VBP/5 replacing/VBG/6 Google/NNP/7 with/IN/8 this/DT/9 <b>quick/JJ/10 and/CC/11 reliable/JJ/12</b> AI/NNP/13 chatting/VBG/14 tool/NN/15 ././16                                                                                                          |

## Search df

``` r
df |>
  textpress::search_df(search_col = 'token',
                       id_col = 'text_id',
                       include = c('ChatGPT', 'education'),
                       logic = 'and',
                       exclude = NULL) |>

  group_by(text_id) |>
  summarize(text = paste0(token, collapse = ' ')) |>
  slice(1:5) |>
  knitr::kable()
```

| text_id | text                                                                                                                                             |
|:----|:------------------------------------------------------------------|
| 13.24   | Embrace the future of education by leveraging the capabilities of ChatGPT to unlock your full academic potential .                               |
| 7.4     | As someone studying artificial intelligence in education , I was curious : Could ChatGPT help ?                                                  |
| 7.41    | My exploration of the exponential decay equation with ChatGPT symbolizes the broader challenges and opportunities presented by AI in education . |

## OpenAI embeddings

``` r
vstore <- df_ss |>
  mutate(words = tokenizers::count_words(text)) |>
  filter(words > 20, words < 60) |>
  mutate(batch_id = textpress::rag_batch_cumsum(x = words,
                                                threshold = 10000)) |>

  textpress::rag_fetch_openai_embs(text_id = 'text_id',
                                   text = 'text',
                                   batch_id = 'batch_id')
```

    ## [1] "Batch 1 of 1"

## Semantic search

``` r
q <- 'What are some concerns about the impact of
advanced AI models like ChatGPT?'
```

``` r
query <- textpress::rag_fetch_openai_embs(query = q)

textpress::search_semantics(x = query,
                            matrix = vstore,
                            n = 5) |>

  left_join(df_ss, by = c('term2' = 'text_id')) |>
  select(cos_sim:text) |>
  knitr::kable()
```

| cos_sim | doc_id | sentence_id | text                                                                                                                                                                                                                                |
|---:|:--|----:|:------------------------------------------------------------|
|   0.879 | 7      |          21 | My interaction with ChatGPT underscores the necessity for students to be equipped with the ability to challenge and question the information provided by AI.                                                                        |
|   0.872 | 18     |           6 | The type of algorithm behind the popular ChatGPT, large language models have taken the world by storm with their ability to understand language, audio, and image inputs, while doling out useful—if not always accurate—responses. |
|   0.867 | 26     |          10 | ChatGPT is a text-generating AI chatbot developed by OpenAI, a company that has launched into the stratosphere of buzzy tech startups over the past year.                                                                           |
|   0.864 | 22     |           1 | Since ChatGPT was first made public, the conversational chatbot has been harnessed by millions to streamline work processes, grade essays, and even create sub-bar comedy material.                                                 |
|   0.862 | 23     |           6 | The AI marketplace, which will be the first of its kind, will allow ChatGPT Plus and Enterprise customers to build, publish, and profit from their own custom GPT (Generative Pre-Trained Transformers) models.                     |

## Summary
