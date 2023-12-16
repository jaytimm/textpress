# nlpx

> A lightweight, versatile NLP companion in R. The package integrates
> easily with common R tools and provides basic features for text
> processing and corpus search, as well as functionality for building
> text embeddings via OpenAI. Ideal for users who need a basic,
> unobtrusive NLP tool in R.

## Installation

``` r
devtools::install_github("jaytimm/nlpx")
```

## Some data

``` r
library(dplyr)
articles <- quicknews::qnews_get_news('ChatGPT',  cores = 5) |>
  slice(1:25)
```

## Text processing

### Split sentences

``` r
df_ss <- articles |>
  mutate(doc_id = row_number()) |>
  nlpx::nlp_split_sentences() 

df_ss |> slice(1:5) |> knitr::kable()
```

| doc_id | sentence_id | text_id | text                                                                                                                                                                 |
|:---|-----:|:---|:----------------------------------------------------------|
| 1      |           1 | 1.1     | Discover how ChatGPT can elevate your research paper quality.                                                                                                        |
| 1      |           2 | 1.2     | Explore five effective methods to leverage this powerful tool for more insightful and polished academic work.                                                        |
| 1      |           3 | 1.3     | In the ever-evolving landscape of academia, the pursuit of excellence in research and writing is a constant endeavor.                                                |
| 1      |           4 | 1.4     | Research papers serve as a cornerstone of scholarly communication, and the quality of these papers can significantly impact one’s academic and professional journey. |
| 1      |           5 | 1.5     | Enter ChatGPT, a remarkable tool that has revolutionized the way research papers are written.                                                                        |

### Tokenization

``` r
tokens <- df_ss |> nlpx::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "Discover" "how"      "ChatGPT"  "can"      "elevate"  "your"    
    ##  [7] "research" "paper"    "quality"  "."

### Cast tokens to df

``` r
df <- tokens |> nlpx::nlp_cast_tokens()
df |> head() |> knitr::kable()
```

| text_id | token    |
|:--------|:---------|
| 1.1     | Discover |
| 1.1     | how      |
| 1.1     | ChatGPT  |
| 1.1     | can      |
| 1.1     | elevate  |
| 1.1     | your     |

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                 |
|:--|:----|:---------------------------------------------------------------|
| 2      | 1           | **Artificial intelligence** went mainstream in 2023 — it was a long time coming yet has a long way to go for the technology to match people’s science fiction fantasies of human-like machines.                                      |
| 9      | 2           | The momentous first release of ChatGPT on Nov. 30, 2023 was based on GPT 3.5, the nonzero number firmly establishing the skyward trajectory of **artificial intelligence**.                                                          |
| 13     | 5           | According to Google, MedLM is the future of its generative AI in healthcare, focusing on enabling users for safe and responsible use of **Artificial Intelligence**.                                                                 |
| 15     | 1           | In the ever-evolving landscape of cybersecurity threats, a new contender has emerged, leveraging the cutting-edge advancements in **artificial intelligence**: ChatGPT-driven phishing schemes.                                      |
| 17     | 3           | The strange trend has emerged as Microsoft-backed OpenAI faces stiff competition from other firms pursuing generative **artificial intelligence** products, including Google, which recently released its own “Gemini” chatbot tool. |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token    | lemma    | upos  | xpos |
|:-------|------:|----:|--------:|:---------|:---------|:---------|:------|:-----|
| 1.1    |     1 |   8 |       1 | 1        | Discover | discover | PROPN | NNP  |
| 1.1    |    10 |  12 |       2 | 2        | how      | how      | ADV   | WRB  |
| 1.1    |    14 |  20 |       3 | 3        | ChatGPT  | ChatGPT  | PART  | RB   |
| 1.1    |    22 |  24 |       4 | 4        | can      | can      | AUX   | MD   |
| 1.1    |    26 |  32 |       5 | 5        | elevate  | elevate  | VERB  | VB   |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "Discover/NNP/1 how/WRB/2 ChatGPT/RB/3 can/MD/4 elevate/VB/5 your/PRP$/6 research/NN/7 paper/NN/8 quality/NN/9 ././10"

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                               |
|:--|:---|:-----------------------------------------------------------------|
| 13     | 15          | Gemini/NNP/1 is/VBZ/2 a/DT/3 “/\`\`/4 multi/AFX/5 -/HYPH/6 **modal/JJ/7 model/NN/8 **,/,/9”/’’/10 which/WDT/11 means/VBZ/12 it/PRP/13 works/VBZ/14 directly/RB/15 with/IN/16 multiple/JJ/17 modes/NNS/18 of/IN/19 input/NN/20 and/CC/21 output/NN/22 ;/,/23 supporting/VBG/24 text/NN/25 input/NN/26 and/CC/27 output/NN/28 ././29 |
| 13     | 17          | With/IN/1 gemini/NNP/2 ,/,/3 a/DT/4 new/JJ/5 term/NN/6 also/RB/7 comes/VBZ/8 into/IN/9 existence/NN/10 ,/,/11 i.e/FW/12 ././13 ,/,/14 LMM/NNP/15 (/-LRB-/16 large/JJ/17 **multimodal/JJ/18 model/NN/19 **)/-RRB-/20 and/CC/21 not/RB/22 to/TO/23 be/VB/24 confused/VBN/25 with/IN/26 LLM/NNP/27 ././28                             |
| 13     | 19          | However/RB/1 ,/,/2 it/PRP/3 is/VBZ/4 not/RB/5 a/DT/6 fully/RB/7 **multimodal/JJ/8 model/NN/9 **in/IN/10 the/DT/11 way/NN/12 Gemini/NNP/13 promises/VBZ/14 to/TO/15 be/VB/16 ././17                                                                                                                                                 |
| 13     | 9           | The/DT/1 **first/JJ/2 model/NN/3 **is/VBZ/4 designed/VBN/5 for/IN/6 complex/JJ/7 tasks/NNS/8 ,/,/9 while/IN/10 the/DT/11 second/JJ/12 model/NN/13 can/MD/14 fine/JJ/15 -/HYPH/16 tune/NN/17 and/CC/18 be/VB/19 best/JJS/20 for/IN/21 scaling/VBG/22 across/IN/23 tasks/NNS/24 ././25                                               |
| 13     | 9           | The/DT/1 first/JJ/2 model/NN/3 is/VBZ/4 designed/VBN/5 for/IN/6 complex/JJ/7 tasks/NNS/8 ,/,/9 while/IN/10 the/DT/11 **second/JJ/12 model/NN/13 **can/MD/14 fine/JJ/15 -/HYPH/16 tune/NN/17 and/CC/18 be/VB/19 best/JJS/20 for/IN/21 scaling/VBG/22 across/IN/23 tasks/NNS/24 ././25                                               |

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

| text_id | text                                                                                                                                                                                                                                                                                                                                      |
|:--|:--------------------------------------------------------------------|
| 1.12    | Example prompt for ChatGPT : “ I’m interested in renewable energy technologies .                                                                                                                                                                                                                                                          |
| 1.20    | Example prompt for ChatGPT : “ Given a dataset on global climate change trends over the past 50 years , including temperature changes , carbon dioxide levels , and ice cap melting rates , suggest the most effective types of visualizations for these data and provide a brief narrative highlighting the key trends and anomalies . ” |
| 1.25    | Example prompt for ChatGPT : “ ChatGPT , I need to generate citations for my research paper in APA format .                                                                                                                                                                                                                               |
| 1.32    | Example prompt for ChatGPT : “ ChatGPT , I am conducting a study on the impact of digitalization in small businesses post - COVID - 19 .                                                                                                                                                                                                  |
| 1.42    | Example prompt for ChatGPT : “ ChatGPT , I have a draft of my research paper on ‘ Renewable Energy Sources . ’                                                                                                                                                                                                                            |

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

| cos_sim | doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                        |
|--:|:--|---:|:--------------------------------------------------------------|
|   0.905 | 20     |          16 | With generative AI emerging as a new gateway tool for gaining information, the testing of potential biases in modeling outputs is an important part of improving programs such as ChatGPT.                                                                                                                  |
|   0.881 | 9      |          14 | ChatGPT and AI are embedding themselves in systems everywhere so fast that it’s scaring some of the smartest minds on the planet.                                                                                                                                                                           |
|   0.881 | 17     |           2 | Social media platforms such as X, Reddit and even OpenAI’s developer forum are riddled with accounts that ChatGPT – a “large-language model” trained on massive troves of internet data — is resisting labor-intensive prompts, such as requests to help the user write code and transcribe blocks of text. |
|   0.880 | 19     |         288 | But OpenAI is involved in at least one lawsuit that has implications for AI systems trained on publicly available data, which would touch on ChatGPT.                                                                                                                                                       |
|   0.880 | 10     |          15 | Is ChatGPT really getting lazier — or is it yet another instance of humans anthropomorphizing an algorithm and reading too much into its uncanny outputs?                                                                                                                                                   |

## Summary
