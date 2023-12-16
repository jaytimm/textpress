# nlpx

> A lightweight, versatile NLP companion in R. The package integrates
> easily with common R tools and provides basic features for text
> processing and corpus search, as well as functionality for building
> text embeddings via OpenAI.

> Ideal for users who need a basic, unobtrusive NLP tool in R.

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

## Text processing

### Split sentences

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

### Tokenization

``` r
tokens <- df_ss |> nlpx::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "What"     "does"     "life"     "online"   "look"     "like"    
    ##  [7] "filtered" "through"  "a"        "bot"      "?"

### Cast tokens to df

``` r
df <- tokens |> nlpx::nlp_cast_tokens()
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
| 9      | 44          | That should (hopefully) help you get more accurate, up-to-date data right when you need it, rather than solely relying on the **artificial intelligence** (AI) chatbot’s rather outdated training data.                                           |
| 9      | 51          | Most American adults do not trust **artificial intelligence** (AI) tools like ChatGPT and worry about their potential misuse, a new survey has found.                                                                                             |
| 10     | 146         | The Texas federal judge has added a requirement that any attorney appearing in his court must attest that “no portion of the filing was drafted by generative **artificial intelligence**,” or if it was, that it was checked “by a human being.” |
| 10     | 223         | ChatGPT is a general-purpose chatbot that uses **artificial intelligence** to generate text after a user enters a prompt, developed by tech startup OpenAI.                                                                                       |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token  | lemma  | upos | xpos |
|:-------|------:|----:|--------:|:---------|:-------|:-------|:-----|:-----|
| 1.1    |     1 |   4 |       1 | 1        | What   | what   | PRON | WP   |
| 1.1    |     6 |   9 |       2 | 2        | does   | do     | AUX  | VBZ  |
| 1.1    |    11 |  14 |       3 | 3        | life   | life   | NOUN | NN   |
| 1.1    |    16 |  21 |       4 | 4        | online | online | ADV  | RB   |
| 1.1    |    23 |  26 |       5 | 5        | look   | look   | VERB | VB   |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] |> strwrap(width = 40)
```

    ## [1] "What/WP/1 does/VBZ/2 life/NN/3"     "online/RB/4 look/VB/5 like/IN/6"   
    ## [3] "filtered/VBN/7 through/IN/8 a/DT/9" "bot/NN/10 ?/./11"

### Search for lexico-grammatical pattern

``` r
inline_ss |>
  nlpx::nlp_search_corpus(search = 'JJ model', 
                          highlight = c('**', '**'),
                          n = 0,
                          is_inline = T) |>
  
  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|:-|:--|:-------------------------------------------------------------------|
| 1      | 19          | OpenAI’s/VBZ/1 most/RBS/2 **powerful/JJ/3 model/NN/4 **does/VBZ/5 not/RB/6 currently/RB/7 provide/VB/8 information/NN/9 about/IN/10 any/DT/11 event/NN/12 more/RBR/13 recent/JJ/14 than/IN/15 April/NNP/16 2023/CD/17 ././18                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| 10     | 227         | The/DT/1 most/RBS/2 **recent/JJ/3 model/NN/4 **is/VBZ/5 GPT/RB/6 -/SYM/7 4/CD/8 ././9                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| 12     | 6           | Insider/RBR/1 also/RB/2 reports/VBZ/3 that/DT/4 ,/,/5 with/IN/6 a/DT/7 score/NN/8 of/IN/9 90.0/CD/10 %/NN/11 ,/,/12 Gemini/NNP/13 Ultra/NNP/14 is/VBZ/15 the/DT/16 **first/JJ/17 model/NN/18 **to/TO/19 outperform/VB/20 human/JJ/21 experts/NNS/22 on/IN/23 MMLU/NNP/24 (/-LRB-/25 massive/JJ/26 multitask/NN/27 language/NN/28 understanding/NN/29 )/-RRB-/30 ,/,/31 which/WDT/32 uses/VBZ/33 a/DT/34 combination/NN/35 of/IN/36 57/CD/37 subjects/NNS/38 such/JJ/39 as/IN/40 math/NN/41 ,/,/42 physics/NNS/43 ,/,/44 history/NN/45 ,/,/46 law/NN/47 ,/,/48 medicine/NN/49 and/CC/50 ethics/NNS/51 for/IN/52 testing/NN/53 both/CC/54 world/NN/55 knowledge/NN/56 and/CC/57 problem/NN/58 -/HYPH/59 solving/NN/60 abilities/NNS/61 ././62 |
| 14     | 67          | More/RBR/1 recently/RB/2 ,/,/3 it’s/VBZ/4 been/VBN/5 shifted/VBN/6 to/IN/7 PaLM/NNP/8 2/CD/9 ,/,/10 a/DT/11 more/RBR/12 **powerful/JJ/13 model/NN/14 **,/,/15 which/WDT/16 Google/NNP/17 says/VBZ/18 is/VBZ/19 faster/JJR/20 and/CC/21 more/RBR/22 efficient/JJ/23 than/IN/24 LaMDA/NNP/25 ././26                                                                                                                                                                                                                                                                                                                                                                                                                                           |

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

| text_id | text                                                                                                                                                                                                      |
|:---|:-------------------------------------------------------------------|
| 10.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI .                                               |
| 10.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                                                                     |
| 13.69   | OpenAI first rolled out the ability to prompt ChatGPT with your voice and images in September , but it only made the feature available to paying users .                                                  |
| 15.9    | Utilizing a list of the 3,108 counties in the contiguous United States , the research group asked the ChatGPT interface to answer a prompt asking about the environmental justice issues in each county . |
| 2.52    | Ask your closest friends and trusted team members to complete the square brackets in this prompt in ChatGPT and send you the result .                                                                     |

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
q <- 'What are some concerns about the impact of
advanced AI models like ChatGPT?'
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
|   0.905 | 15     |          14 | With generative AI emerging as a new gateway tool for gaining information, the testing of potential biases in modeling outputs is an important part of improving programs such as ChatGPT. |
|   0.880 | 10     |         288 | But OpenAI is involved in at least one lawsuit that has implications for AI systems trained on publicly available data, which would touch on ChatGPT.                                      |
|   0.877 | 9      |          51 | Most American adults do not trust artificial intelligence (AI) tools like ChatGPT and worry about their potential misuse, a new survey has found.                                          |
|   0.876 | 4      |          19 | But for many, it was ChatGPT’s release as a free-to-use dialogue agent in November 2022 that quickly revealed this technology’s power and pitfalls.                                        |
|   0.876 | 10     |         116 | “As you may know, the government has been tightening regulations associated with deep synthesis technologies (DST) and generative AI services, including ChatGPT.                          |

## Summary
