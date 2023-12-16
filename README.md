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
articles <- quicknews::quicknews('ChatGPT',  cores = 5) |>
  filter(!is.na(text)) |>
  slice(5:30)
```

## Text processing

### Split sentences

``` r
df_ss <- articles |>
  mutate(doc_id = row_number()) |>
  nlpx::nlp_split_sentences() 

df_ss |> slice(1:5) |> knitr::kable()
```

| doc_id | sentence_id | text_id | text                                                                                                         |
|:----|------:|:----|:------------------------------------------------------|
| 1      |           1 | 1.1     | If you buy through a BGR link, we may earn an affiliate commission, helping support our expert product labs. |
| 1      |           2 | 1.2     | I’ve wanted to get on ChatGPT Plus for months but kept postponing the upgrade until DevDay came along.       |
| 1      |           3 | 1.3     | OpenAI’s big developer event brought custom GPTs, among other things, and I knew I wanted to try them out.   |
| 1      |           4 | 1.4     | However, making and using custom GPTs was restricted to the ChatGPT Plus subscription.                       |
| 1      |           5 | 1.5     | And I knew I had to get on.                                                                                  |

### Tokenization

``` r
tokens <- df_ss |> nlpx::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "If"         "you"        "buy"        "through"    "a"         
    ##  [6] "BGR"        "link"       ","          "we"         "may"       
    ## [11] "earn"       "an"         "affiliate"  "commission" ","         
    ## [16] "helping"    "support"    "our"        "expert"     "product"   
    ## [21] "labs"       "."

### Cast tokens to df

``` r
df <- tokens |> nlpx::nlp_cast_tokens()
df |> head() |> knitr::kable()
```

| text_id | token   |
|:--------|:--------|
| 1.1     | If      |
| 1.1     | you     |
| 1.1     | buy     |
| 1.1     | through |
| 1.1     | a       |
| 1.1     | BGR     |

## Search text

``` r
df_ss |>
  nlpx::nlp_search_corpus(search = 'artificial intelligence', 
                          highlight = c('**', '**'),
                          n = 0, 
                          is_inline = F) |>
  
  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                              |
|:--|:----|:----------------------------------------------------------------|
| 4      | 2           | The momentous first release of ChatGPT on Nov. 30, 2023 was based on GPT 3.5, the nonzero number firmly establishing the skyward trajectory of **artificial intelligence**.                                                                       |
| 8      | 5           | According to Google, MedLM is the future of its generative AI in healthcare, focusing on enabling users for safe and responsible use of **Artificial Intelligence**.                                                                              |
| 10     | 1           | In the ever-evolving landscape of cybersecurity threats, a new contender has emerged, leveraging the cutting-edge advancements in **artificial intelligence**: ChatGPT-driven phishing schemes.                                                   |
| 12     | 3           | The strange trend has emerged as Microsoft-backed OpenAI faces stiff competition from other firms pursuing generative **artificial intelligence** products, including Google, which recently released its own “Gemini” chatbot tool.              |
| 14     | 146         | The Texas federal judge has added a requirement that any attorney appearing in his court must attest that “no portion of the filing was drafted by generative **artificial intelligence**,” or if it was, that it was checked “by a human being.” |

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
| 1.1    |     1 |   2 |       1 | 1        | If      | if      | SCONJ | IN   |
| 1.1    |     4 |   6 |       2 | 2        | you     | you     | PRON  | PRP  |
| 1.1    |     8 |  10 |       3 | 3        | buy     | buy     | VERB  | VBP  |
| 1.1    |    12 |  18 |       4 | 4        | through | through | ADP   | IN   |
| 1.1    |    20 |  20 |       5 | 5        | a       | a       | DET   | DT   |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "If/IN/1 you/PRP/2 buy/VBP/3 through/IN/4 a/DT/5 BGR/NNP/6 link/NN/7 ,/,/8 we/PRP/9 may/MD/10 earn/VB/11 an/DT/12 affiliate/JJ/13 commission/NN/14 ,/,/15 helping/VBG/16 support/VB/17 our/PRP$/18 expert/NN/19 product/NN/20 labs/NNS/21 ././22"

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                        |
|:--|:---|:----------------------------------------------------------------|
| 13     | 67          | More/RBR/1 recently/RB/2 ,/,/3 it’s/VBZ/4 been/VBN/5 shifted/VBN/6 to/IN/7 PaLM/NNP/8 2/CD/9 ,/,/10 a/DT/11 more/RBR/12 **powerful/JJ/13 model/NN/14** ,/,/15 which/WDT/16 Google/NNP/17 says/VBZ/18 is/VBZ/19 faster/JJR/20 and/CC/21 more/RBR/22 efficient/JJ/23 than/IN/24 LaMDA/NNP/25 ././26           |
| 14     | 227         | The/DT/1 most/RBS/2 **recent/JJ/3 model/NN/4** is/VBZ/5 GPT/RB/6 -/SYM/7 4/CD/8 ././9                                                                                                                                                                                                                       |
| 16     | 10          | Accordingly/RB/1 ,/,/2 a/DT/3 new/JJ/4 acronym/NN/5 is/VBZ/6 emerging/VBG/7 :/:/8 LMM/NNP/9 (/-LRB-/10 large/JJ/11 **multimodal/JJ/12 model/NN/13** )/-RRB-/14 ,/,/15 not/RB/16 to/TO/17 be/VB/18 confused/VBN/19 with/IN/20 LLM/NNP/21 ././22                                                              |
| 16     | 12          | However/RB/1 ,/,/2 it/PRP/3 is/VBZ/4 not/RB/5 a/DT/6 fully/RB/7 **multimodal/JJ/8 model/NN/9** in/IN/10 the/DT/11 way/NN/12 that/WRB/13 Gemini/NNP/14 promises/VBZ/15 to/TO/16 be/VB/17 ././18                                                                                                              |
| 16     | 14          | ChatGPT/RB/1 -/,/2 4/GW/3 also/RB/4 converts/VBZ/5 text/NN/6 to/TO/7 speech/VB/8 on/IN/9 output/NN/10 using/VBG/11 a/DT/12 **different/JJ/13 model/NN/14** ,/,/15 meaning/VBG/16 that/IN/17 GPT/NNP/18 -/HYPH/19 4V/NNP/20 itself/PRP/21 is/VBZ/22 working/VBG/23 purely/RB/24 with/IN/25 text/NN/26 ././27 |

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
| 14.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI .                                               |
| 14.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                                                                     |
| 15.11   | Utilizing a list of the 3,108 counties in the contiguous United States , the research group asked the ChatGPT interface to answer a prompt asking about the environmental justice issues in each county . |

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

### Retrieval

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
|   0.905 | 15     |          16 | With generative AI emerging as a new gateway tool for gaining information, the testing of potential biases in modeling outputs is an important part of improving programs such as ChatGPT.                                                                                                                  |
|   0.881 | 4      |          14 | ChatGPT and AI are embedding themselves in systems everywhere so fast that it’s scaring some of the smartest minds on the planet.                                                                                                                                                                           |
|   0.881 | 12     |           2 | Social media platforms such as X, Reddit and even OpenAI’s developer forum are riddled with accounts that ChatGPT – a “large-language model” trained on massive troves of internet data — is resisting labor-intensive prompts, such as requests to help the user write code and transcribe blocks of text. |
|   0.880 | 14     |         288 | But OpenAI is involved in at least one lawsuit that has implications for AI systems trained on publicly available data, which would touch on ChatGPT.                                                                                                                                                       |
|   0.880 | 5      |          15 | Is ChatGPT really getting lazier — or is it yet another instance of humans anthropomorphizing an algorithm and reading too much into its uncanny outputs?                                                                                                                                                   |

### Lexical semantics

``` r
mesht <- pubmedtk::data_mesh_thesuarus()
embs <- pubmedtk::data_mesh_embeddings()

nlpx::nlp_find_neighbors(x = 'Artificial Intelligence',
                         matrix = embs,
                         n = 10) |>
  knitr::kable()
```

| rank | term1                   | term2                                | cos_sim |
|-----:|:----------------------|:----------------------------------|--------:|
|    1 | Artificial Intelligence | Artificial Intelligence              |   1.000 |
|    2 | Artificial Intelligence | Machine Learning                     |   0.712 |
|    3 | Artificial Intelligence | Language Arts                        |   0.657 |
|    4 | Artificial Intelligence | Natural Language Processing          |   0.605 |
|    5 | Artificial Intelligence | Mobile Applications                  |   0.601 |
|    6 | Artificial Intelligence | Unsupervised Machine Learning        |   0.595 |
|    7 | Artificial Intelligence | Supervised Machine Learning          |   0.587 |
|    8 | Artificial Intelligence | Speech-Language Pathology            |   0.586 |
|    9 | Artificial Intelligence | Signal Processing, Computer-Assisted |   0.585 |
|   10 | Artificial Intelligence | Social Skills                        |   0.583 |

## Summary
