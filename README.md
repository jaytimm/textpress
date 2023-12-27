# textpress

> A lightweight, versatile NLP companion in R. Provides basic features
> for (1) text processing, (2) corpus search, and (3) web scraping, as
> well as functionality for (4) building text embeddings via OpenAI.
> Ideal for users who need a basic, unobtrusive NLP tool in R.

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

| doc_id | sentence_id | text_id | text                                                                                                                                                                                                                                                                                    |
|:--|---:|:--|:--------------------------------------------------------------|
| 1      |           1 | 1.1     | Since so much of 2023 was filled with news about generative AI, how might chatbots reflect on what was an eventful year?                                                                                                                                                                |
| 1      |           2 | 1.2     | In addition to our usual 2023 recaps and 2024 previews, Digiday asked a few chatbots to provide their own answers.                                                                                                                                                                      |
| 1      |           3 | 1.3     | But instead of anything overly serious or hard-hitting, we took a more light-hearted look at how three of the most popular bots — OpenAI’s ChatGPT, Google’s Bard and Anthropic’s Claude — answered the same questions about the past year, along with a few spiced with holiday cheer. |
| 1      |           4 | 1.4     | Powered by three different large language models, the panelists offer a glimpse at how their style and substance varies.                                                                                                                                                                |
| 1      |           5 | 1.5     | However, they also gave plenty of similar answers that were all equally obvious, generic and guarded — not unlike many executives’ answers when asked similar questions about various aspects of AI throughout 2023.                                                                    |

### Tokenization

``` r
tokens <- df_ss |> textpress::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "Since"      "so"         "much"       "of"         "2023"      
    ##  [6] "was"        "filled"     "with"       "news"       "about"     
    ## [11] "generative" "AI"         ","          "how"        "might"     
    ## [16] "chatbots"   "reflect"    "on"         "what"       "was"       
    ## [21] "an"         "eventful"   "year"       "?"

### Cast tokens to df

``` r
df <- tokens |> textpress::nlp_cast_tokens()
df |> head() |> knitr::kable()
```

| text_id | token |
|:--------|:------|
| 1.1     | Since |
| 1.1     | so    |
| 1.1     | much  |
| 1.1     | of    |
| 1.1     | 2023  |
| 1.1     | was   |

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
| 1      | 18          | Claude: Auntie AI is Siri meets Rosie the Robot — a clever female **artificial intelligence** that becomes part of the family.                                                                                                                                                                                                          |
| 1      | 35          | Claude: Meet Pater—the **artificial intelligence** assistant who gives your family the gift of time this holiday season.                                                                                                                                                                                                                |
| 2      | 3           | Still, considering that many believe that recent events have finally left the “crypto winter” in the dustbin, and given that the New Year is right around the corner, Finbold decided to ask the **artificial intelligence** (AI) of OpenAI’s posterchild – ChatGPT – about which cryptocurrencies it would recommend to savvy traders. |
| 3      | 3           | With 2023 nearly over and 2024 – a year many hope will turn into a proper bull market – right around the corner, Finbold decided to ask the **artificial intelligence** (AI) of OpenAI’s flagship platform – ChatGPT – which stocks a savvy investor might want to buy before the holidays are over.                                    |
| 3      | 22          | Nvidia is the biggest player in the semiconductor industry and a crucial part in the burgeoning **artificial intelligence** sector.                                                                                                                                                                                                     |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token | lemma | upos | xpos |
|:-------|------:|----:|--------:|:---------|:------|:------|:-----|:-----|
| 1.1    |     1 |   5 |       1 | 1        | Since | since | ADP  | IN   |
| 1.1    |     7 |   8 |       2 | 2        | so    | so    | ADV  | RB   |
| 1.1    |    10 |  13 |       3 | 3        | much  | much  | ADJ  | JJ   |
| 1.1    |    15 |  16 |       4 | 4        | of    | of    | ADP  | IN   |
| 1.1    |    18 |  21 |       5 | 5        | 2023  | 2023  | NUM  | CD   |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "Since/IN/1 so/RB/2 much/JJ/3 of/IN/4 2023/CD/5 was/VBD/6 filled/VBN/7 with/IN/8 news/NN/9 about/IN/10 generative/JJ/11 AI/NNP/12 ,/,/13 how/WRB/14 might/MD/15 chatbots/NNS/16 reflect/VBP/17 on/IN/18 what/WP/19 was/VBD/20 an/DT/21 eventful/JJ/22 year/NN/23 ?/./24"

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
| 18     | 15          | This/DT/1 doesn’t/RB/2 mean/VB/3 Gemini/NNP/4 Ultra/NNP/5 is/VBZ/6 a/DT/7 **bad/JJ/8 model/NN/9** or/CC/10 that/IN/11 it/PRP/12 can’t/RB/13 compete/VB/14 with/IN/15 GPT/NN/16 -/,/17 4/CD/18 but/CC/19 shows/VBZ/20 the/DT/21 consequences/NNS/22 of/IN/23 Google/NNP/24 overhyping/VBG/25 its/PRP$/26 own/JJ/27 product/NN/28 ././29 |
| 25     | 227         | The/DT/1 most/RBS/2 **recent/JJ/3 model/NN/4** is/VBZ/5 GPT/RB/6 -/SYM/7 4/CD/8 ././9                                                                                                                                                                                                                                                  |

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

| text_id | text                                                                                                                                                                      |
|:----|:------------------------------------------------------------------|
| 16.9    | However , I discovered that conversing with ChatGPT to fine - tune my prompt ideas transformed the process .                                                              |
| 23.6    | This ChatGPT prompt guide can help generate ideas and create new workflows to help you or your business tackle challenges and projects effectively .                      |
| 25.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI .               |
| 25.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                                     |
| 8.37    | According to an OpenAI website post , ‘ DALL - E 3 is natively integrated with ChatGPT , enabling users to employ ChatGPT as a brainstorming partner and prompt refiner . |

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

| cos_sim | doc_id | sentence_id | text                                                                                                                                                                                                                                                            |
|--:|:--|---:|:-------------------------------------------------------------|
|   0.909 | 11     |           2 | A research team conducted an experiment on ChatGPT that raised concerns about the potential of chatbots and similar generative artificial intelligence tools to reveal sensitive personal information about real people.                                        |
|   0.891 | 21     |          26 | Experts in the field have great concerns over the “fundamental flaw” of a programmed-in, left-leaning bias that ChatGPT uses to produce its answers.                                                                                                            |
|   0.889 | 12     |           1 | Since OpenAI released ChatGPT last year, there have been quite a few occasions where flaws in the AI chatbot could’ve been weaponized or manipulated by bad actors to access sensitive or private data.                                                         |
|   0.881 | 1      |          47 | Unlike the viral hype but concerning issues seen with chatbots like ChatGPT, Claude represents a major step forward in safeguards and value alignment, addressing rising concerns about misinformation and preserving human integrity in generative AI systems. |
|   0.881 | 1      |          49 | ChatGPT: As an AI developed by OpenAI, I don’t experience personal concerns or emotions, but it’s important to recognize the significance of copyright issues in AI applications, particularly in marketing.                                                    |

## Summary
