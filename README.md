# textpress

> A lightweight, versatile NLP companion in R. Provides basic features
> for text processing, corpus search, and web scraping, as well as
> functionality for building text embeddings via OpenAI. Ideal for users
> who need a basic, unobtrusive NLP tool in R.

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

| doc_id | sentence_id | text_id | text                                                                                                                                                                                                                                                                                                                                |
|:--|---:|:--|:--------------------------------------------------------------|
| 1      |           1 | 1.1     | Much like 2022 and its numerous calamities that shook the crypto industry brought no shortage of bears and doomsayers, 2023 brought recovery and renewed enthusiasm for investors.                                                                                                                                                  |
| 1      |           2 | 1.2     | Indeed, many cryptocurrencies rose to highs not seen in well over a year, such as Bitcoin (BTC), Ethereum (ETH), and Solana (SOL), while others, like Polygon (MATIC), while benefiting from the rally, are still significantly under even compared with their previous 2023 highs.                                                 |
| 1      |           3 | 1.3     | Still, considering that many believe that recent events have finally left the “crypto winter” in the dustbin, and given that the New Year is right around the corner, Finbold decided to ask the artificial intelligence (AI) of OpenAI’s posterchild – ChatGPT – about which cryptocurrencies it would recommend to savvy traders. |
| 1      |           4 | 1.4     | In its analysis, the AI seemingly remained level-headed, offering cryptocurrencies with a strong track record.                                                                                                                                                                                                                      |
| 1      |           5 | 1.5     | ChatGPT’s first pick for 2024 is the world’s foremost cryptocurrency – Bitcoin (BTC).                                                                                                                                                                                                                                               |

### Tokenization

``` r
tokens <- df_ss |> textpress::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "Much"       "like"       "2022"       "and"        "its"       
    ##  [6] "numerous"   "calamities" "that"       "shook"      "the"       
    ## [11] "crypto"     "industry"   "brought"    "no"         "shortage"  
    ## [16] "of"         "bears"      "and"        "doomsayers" ","         
    ## [21] "2023"       "brought"    "recovery"   "and"        "renewed"   
    ## [26] "enthusiasm" "for"        "investors"  "."

### Cast tokens to df

``` r
df <- tokens |> textpress::nlp_cast_tokens()
df |> head() |> knitr::kable()
```

| text_id | token    |
|:--------|:---------|
| 1.1     | Much     |
| 1.1     | like     |
| 1.1     | 2022     |
| 1.1     | and      |
| 1.1     | its      |
| 1.1     | numerous |

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                                    |
|:--|:---|:-----------------------------------------------------------------|
| 1      | 3           | Still, considering that many believe that recent events have finally left the “crypto winter” in the dustbin, and given that the New Year is right around the corner, Finbold decided to ask the **artificial intelligence** (AI) of OpenAI’s posterchild – ChatGPT – about which cryptocurrencies it would recommend to savvy traders. |
| 2      | 3           | With 2023 nearly over and 2024 – a year many hope will turn into a proper bull market – right around the corner, Finbold decided to ask the **artificial intelligence** (AI) of OpenAI’s flagship platform – ChatGPT – which stocks a savvy investor might want to buy before the holidays are over.                                    |
| 2      | 22          | Nvidia is the biggest player in the semiconductor industry and a crucial part in the burgeoning **artificial intelligence** sector.                                                                                                                                                                                                     |
| 3      | 1           | The **Artificial Intelligence** (AI) run has propelled competition among developers and businesses in 2023.                                                                                                                                                                                                                             |
| 4      | 2           | Google’s (NASDAQ: GOOGL) offering – Bard – while not as famous as the other **artificial intelligence** (AI), has also garnered a significant fanbase.                                                                                                                                                                                  |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token | lemma | upos  | xpos |
|:-------|------:|----:|--------:|:---------|:------|:------|:------|:-----|
| 1.1    |     1 |   4 |       1 | 1        | Much  | much  | ADJ   | JJ   |
| 1.1    |     6 |   9 |       2 | 2        | like  | like  | ADP   | IN   |
| 1.1    |    11 |  14 |       3 | 3        | 2022  | 2022  | NUM   | CD   |
| 1.1    |    16 |  18 |       4 | 4        | and   | and   | CCONJ | CC   |
| 1.1    |    20 |  22 |       5 | 5        | its   | its   | PRON  | PRP$ |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "Much/JJ/1 like/IN/2 2022/CD/3 and/CC/4 its/PRP$/5 numerous/JJ/6 calamities/NNS/7 that/WDT/8 shook/VBP/9 the/DT/10 crypto/NN/11 industry/NN/12 brought/VBD/13 no/DT/14 shortage/NN/15 of/IN/16 bears/NNS/17 and/CC/18 doomsayers/NNS/19 ,/,/20 2023/CD/21 brought/NN/22 recovery/NN/23 and/CC/24 renewed/VBD/25 enthusiasm/NN/26 for/IN/27 investors/NNS/28 ././29"

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                                   |
|:--|:---|:-----------------------------------------------------------------|
| 16     | 15          | This/DT/1 doesn’t/RB/2 mean/VB/3 Gemini/NNP/4 Ultra/NNP/5 is/VBZ/6 a/DT/7 **bad/JJ/8 model/NN/9** or/CC/10 that/IN/11 it/PRP/12 can’t/RB/13 compete/VB/14 with/IN/15 GPT/NN/16 -/,/17 4/CD/18 but/CC/19 shows/VBZ/20 the/DT/21 consequences/NNS/22 of/IN/23 Google/NNP/24 overhyping/VBG/25 its/PRP$/26 own/JJ/27 product/NN/28 ././29 |
| 23     | 227         | The/DT/1 most/RBS/2 **recent/JJ/3 model/NN/4** is/VBZ/5 GPT/RB/6 -/SYM/7 4/CD/8 ././9                                                                                                                                                                                                                                                  |

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

| text_id | text                                                                                                                                                        |
|:----|:------------------------------------------------------------------|
| 12.9    | However , I discovered that conversing with ChatGPT to fine - tune my prompt ideas transformed the process .                                                |
| 21.6    | This ChatGPT prompt guide can help generate ideas and create new workflows to help you or your business tackle challenges and projects effectively .        |
| 23.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI . |
| 23.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                       |

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

    ## [1] "Batch 1 of 2"
    ## [1] "Batch 2 of 2"

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

| cos_sim | doc_id | sentence_id | text                                                                                                                                                                                                    |
|---:|:---|----:|:------------------------------------------------------------|
|   0.891 | 19     |          26 | Experts in the field have great concerns over the “fundamental flaw” of a programmed-in, left-leaning bias that ChatGPT uses to produce its answers.                                                    |
|   0.889 | 26     |          38 | Some AI experts have called for models behind AI like ChatGPT to be open sourced so the public knows how exactly they are trained.                                                                      |
|   0.889 | 7      |           1 | Since OpenAI released ChatGPT last year, there have been quite a few occasions where flaws in the AI chatbot could’ve been weaponized or manipulated by bad actors to access sensitive or private data. |
|   0.880 | 23     |         288 | But OpenAI is involved in at least one lawsuit that has implications for AI systems trained on publicly available data, which would touch on ChatGPT.                                                   |
|   0.876 | 6      |           1 | ChatGPT is being asked to handle all kinds of weird tasks, from determining whether written text was created by an AI, to answering homework questions, and much more.                                  |

``` r
### Word-level

# mesht <- pubmedtk::data_mesh_thesuarus()
# embs <- pubmedtk::data_mesh_embeddings()
# 
# textpress::nlp_find_neighbors(x = 'Artificial Intelligence',
#                          matrix = embs,
#                          n = 10) |>
#   knitr::kable()
```

## Summary
