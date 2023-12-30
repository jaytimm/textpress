# textpress

A lightweight, versatile NLP companion in R. Provides basic features for
(1) text processing, (2) corpus search, and (3) web scraping, as well as
functionality for (4) building text embeddings via OpenAI. Ideal for
users who need a basic, unobtrusive NLP tool in R.

## Installation

``` r
devtools::install_github("jaytimm/textpress")
```

## Usage

## Web scraping

``` r
library(dplyr)
articles <- textpress::nlp_scrape_web(x = 'ChatGPT',
                                      input = 'search',
                                      cores = 5) |>
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

| doc_id | sentence_id | text_id | text                                                                                                                                                         |
|:---|-----:|:---|:----------------------------------------------------------|
| 1      |           1 | 1.1     | Chinese tech powerhouse Baidu recently announced that its artificial intelligence (AI) product, Ernie bot, has exceeded 100 million users.                   |
| 1      |           2 | 1.2     | This success raised Baidu shares 3 percent higher in U.S. trading, maintaining the company’s positive trajectory throughout 2023.                            |
| 1      |           3 | 1.3     | However, the tech giant did not specify whether these figures represented active users or the cumulative count over a particular period.                     |
| 1      |           4 | 1.4     | In comparison with Microsoft-backed OpenAI’s ChatGPT, Baidu’s Ernie bot has demonstrated its versatility by accommodating users in both English and Chinese. |
| 1      |           5 | 1.5     | Unlike ChatGPT, which is not officially available in China, Baidu’s Ernie bot seamlessly employs the Chinese language.                                       |

### Tokenization

``` r
tokens <- df_ss |> textpress::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "Chinese"      "tech"         "powerhouse"   "Baidu"        "recently"    
    ##  [6] "announced"    "that"         "its"          "artificial"   "intelligence"
    ## [11] "("            "AI"           ")"            "product"      ","           
    ## [16] "Ernie"        "bot"          ","            "has"          "exceeded"    
    ## [21] "100"          "million"      "users"        "."

### Cast tokens to df

``` r
df <- tokens |> textpress::nlp_cast_tokens()
df |> head() |> knitr::kable()
```

| text_id | token      |
|:--------|:-----------|
| 1.1     | Chinese    |
| 1.1     | tech       |
| 1.1     | powerhouse |
| 1.1     | Baidu      |
| 1.1     | recently   |
| 1.1     | announced  |

## Search text

``` r
df_ss |>
  textpress::nlp_search_corpus(search = 'artificial intelligence',
                               highlight = c('**', '**'),
                               n = 0,
                               is_inline = F) |>

  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                              |
|:--|:----|:---------------------------------------------------------------|
| 1      | 1           | Chinese tech powerhouse Baidu recently announced that its **artificial intelligence** (AI) product, Ernie bot, has exceeded 100 million users.                                                                                    |
| 2      | 13          | Generative **artificial intelligence**, such as ChatGPT, draws on a large volume of data, some of it personal, and from that information, it generates original content.                                                          |
| 2      | 18          | Experts agree with the AEPD’s advice: do not share personal information with the **artificial intelligence** tool.                                                                                                                |
| 2      | 21          | If, despite these recommendations, a user has already shared their personal data with an **artificial intelligence** system, it’s possible to try and delete it.                                                                  |
| 2      | 32          | In its guidelines on how to manage **artificial intelligence**, the agency explains that anonymization is one of the techniques to minimize the use of data, ensuring that only the data necessary for the given purpose is used. |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token      | lemma      | upos  | xpos |
|:-------|------:|----:|--------:|:---------|:-----------|:-----------|:------|:-----|
| 1.1    |     1 |   7 |       1 | 1        | Chinese    | chinese    | ADJ   | JJ   |
| 1.1    |     9 |  12 |       2 | 2        | tech       | tech       | NOUN  | NN   |
| 1.1    |    14 |  23 |       3 | 3        | powerhouse | powerhouse | NOUN  | NN   |
| 1.1    |    25 |  29 |       4 | 4        | Baidu      | Baidu      | PROPN | NNP  |
| 1.1    |    31 |  38 |       5 | 5        | recently   | recently   | ADV   | RB   |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "Chinese/JJ/1 tech/NN/2 powerhouse/NN/3 Baidu/NNP/4 recently/RB/5 announced/VBD/6 that/IN/7 its/PRP$/8 artificial/JJ/9 intelligence/NN/10 (/-LRB-/11 AI/AFX/12 )/-RRB-/13 product/NN/14 ,/,/15 Ernie/NNP/16 bot/NN/17 ,/,/18 has/VBZ/19 exceeded/VBN/20 100/CD/21 million/CD/22 users/NNS/23 ././24"

### Search for lexico-grammatical pattern

``` r
inline_ss |>
  textpress::nlp_search_corpus(search = 'JJ model',
                               highlight = c('**', '**'),
                               n = 0,
                               is_inline = T) |>

  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                          |
|:---|:----|:---------------------------------------------------------------|
| 1      | 16          | In/IN/1 comparison/NN/2 ,/,/3 OpenAI’s/NNP/4 ChatGPT/NNP/5 charges/VBZ/6 users/NNS/7 //8 20/CD/9 per/IN/10 month/NN/11 to/TO/12 access/VB/13 its/PRP$/14 latest/JJS/15 **available/JJ/16 model/NN/17** ././18 |

## Search df

``` r
df |>
  textpress::nlp_search_df(search_col = 'token',
                           id_col = 'text_id',
                           include = c('ChatGPT', 'prompt'),
                           logic = 'and',
                           exclude = NULL) |>

  group_by(text_id) |>
  summarize(text = paste0(token, collapse = ' ')) |>
  slice(1:5) |>
  knitr::kable()
```

| text_id | text                                                                                                                                                                                                                       |
|:---|:-------------------------------------------------------------------|
| 13.1    | In the realm of artificial intelligence , where language models like ChatGPT reign supreme , the significance of a simple yet potent tool often goes unnoticed — the prompt .                                              |
| 13.3    | The art of crafting an effective prompt stands as the catalyst that unlocks the immense potential of ChatGPT , allowing it to transcend mere algorithms and unveil its true prowess in generating text - based solutions . |
| 13.32   | Understanding this evolution offers insights into the ever - expanding capabilities and potential applications of prompt - driven AI language models like ChatGPT .                                                        |
| 13.81   | By honing the art of prompt creation , individuals can unlock the full potential of AI models like ChatGPT , guiding them toward generating responses that align precisely with their objectives .                         |

## OpenAI embeddings

``` r
vstore <- df_ss |>
  mutate(words = tokenizers::count_words(text)) |>
  filter(words > 20, words < 60) |>
  mutate(batch_id = textpress::nlp_batch_cumsum(x = words,
                                           threshold = 10000)) |>

  textpress::nlp_fetch_openai_embs(text_id = 'text_id',
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
query <- textpress::nlp_fetch_openai_embs(query = q)

textpress::nlp_find_neighbors(x = query,
                              matrix = vstore,
                              n = 5) |>

  left_join(df_ss, by = c('term2' = 'text_id')) |>
  select(cos_sim:text) |>
  knitr::kable()
```

| cos_sim | doc_id | sentence_id | text                                                                                                                                                                                                                                            |
|---:|:--|----:|:-------------------------------------------------------------|
|   0.915 | 18     |          17 | This indicates that while AI, including ChatGPT, has a growing role in medical research, researchers must be mindful of potential issues and drawbacks.                                                                                         |
|   0.911 | 13     |         102 | Enhancements in AI Models: Discussing potential improvements in AI models like ChatGPT, anticipating increased sophistication, efficiency, and adaptability in generating responses based on diverse prompts.                                   |
|   0.909 | 7      |           2 | A research team conducted an experiment on ChatGPT that raised concerns about the potential of chatbots and similar generative artificial intelligence tools to reveal sensitive personal information about real people.                        |
|   0.892 | 13     |         114 | By forecasting advancements and potential impacts across industries, it envisions a collaborative future where AI models like ChatGPT complement human intelligence, driving innovation, efficiency, and transformation across diverse sectors. |
|   0.889 | 11     |          11 | OpenAI, renowned for its commitment to advancing artificial intelligence in a responsible and ethical manner, has positioned ChatGPT as a tool for developers to integrate conversational AI into various applications.                         |

## Summary
