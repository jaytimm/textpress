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

| doc_id | sentence_id | text_id | text                                                                                                                                                                        |
|:---|-----:|:---|:----------------------------------------------------------|
| 1      |           1 | 1.1     | If you buy through a BGR link, we may earn an affiliate commission, helping support our expert product labs.                                                                |
| 1      |           2 | 1.2     | Google stunned the world with Gemini, a ChatGPT rival that could receive voice instructions and react to a real-time feed of the world while answering those voice prompts. |
| 1      |           3 | 1.3     | It was miles ahead of what ChatGPT could do.                                                                                                                                |
| 1      |           4 | 1.4     | Also, it was all fake.                                                                                                                                                      |
| 1      |           5 | 1.5     | Disappointingly so.                                                                                                                                                         |

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
                          n = 0) |>
  
  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                              |
|:--|:----|:----------------------------------------------------------------|
| 4      | 2           | The momentous first release of ChatGPT on Nov. 30, 2023 was based on GPT 3.5, the nonzero number firmly establishing the skyward trajectory of **artificial intelligence**.                                                                       |
| 10     | 3           | The strange trend has emerged as Microsoft-backed OpenAI faces stiff competition from other firms pursuing generative **artificial intelligence** products, including Google, which recently released its own “Gemini” chatbot tool.              |
| 13     | 146         | The Texas federal judge has added a requirement that any attorney appearing in his court must attest that “no portion of the filing was drafted by generative **artificial intelligence**,” or if it was, that it was checked “by a human being.” |
| 13     | 223         | ChatGPT is a general-purpose chatbot that uses **artificial intelligence** to generate text after a user enters a prompt, developed by tech startup OpenAI.                                                                                       |
| 14     | 4           | Their findings, published in the journal Telematics and Informatics, suggest the potential for geographic biases existing in current generative **artificial intelligence** (AI) models.                                                          |

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                                                                                                                                               |
|:--|:---|:----------------------------------------------------------------|
| 1      | 21          | If/IN/1 you/PRP/2 know/VBP/3 your/PRP/4*w**a**y*/*N**N*/5*a**r**o**u**n**d*/*I**N*/6*A**I*/*N**N**P*/7*s**o**f**t**w**a**r**e*/*N**N*/8, /, /9*y**o**u*/*P**R**P*/10*c**a**n*/*M**D*/11*s**t**a**r**t*/*V**B*/12*u**s**i**n**g*/*V**B**G*/13*t**h**e*/*D**T*/14 \*  \* *n**e**w*/*J**J*/15*m**o**d**e**l*/*N**N*/16 \*  \* *t**o*/*T**O*/17*i**n**c**o**r**p**o**r**a**t**e*/*V**B*/18*i**n*/*I**N*/19*y**o**u**r*/*P**R**P*/20 apps/NNS/21 ././22 |
| 1      | 31          | It/PRP/1 is/VBZ/2 a/DT/3 decoder/NN/4 -/HYPH/5 **only/JJ/6 model/NN/7 **where/WRB/8 the/DT/9 feedforward/NN/10 block/NN/11 picks/NNS/12 from/IN/13 a/DT/14 set/NN/15 of/IN/16 8/CD/17 distinct/JJ/18 groups/NNS/19 of/IN/20 parameters/NNS/21 ././22                                                                                                                                                                                               |
| 11     | 67          | More/RBR/1 recently/RB/2 ,/,/3 it’s/VBZ/4 been/VBN/5 shifted/VBN/6 to/IN/7 PaLM/NNP/8 2/CD/9 ,/,/10 a/DT/11 more/RBR/12 **powerful/JJ/13 model/NN/14 **,/,/15 which/WDT/16 Google/NNP/17 says/VBZ/18 is/VBZ/19 faster/JJR/20 and/CC/21 more/RBR/22 efficient/JJ/23 than/IN/24 LaMDA/NNP/25 ././26                                                                                                                                                  |
| 13     | 227         | The/DT/1 most/RBS/2 **recent/JJ/3 model/NN/4 **is/VBZ/5 GPT/RB/6 -/SYM/7 4/CD/8 ././9                                                                                                                                                                                                                                                                                                                                                              |
| 15     | 10          | Accordingly/RB/1 ,/,/2 a/DT/3 new/JJ/4 acronym/NN/5 is/VBZ/6 emerging/VBG/7 :/:/8 LMM/NNP/9 (/-LRB-/10 large/JJ/11 **multimodal/JJ/12 model/NN/13 **)/-RRB-/14 ,/,/15 not/RB/16 to/TO/17 be/VB/18 confused/VBN/19 with/IN/20 LLM/NNP/21 ././22                                                                                                                                                                                                     |

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
| 13.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI .                                               |
| 13.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                                                                     |
| 14.11   | Utilizing a list of the 3,108 counties in the contiguous United States , the research group asked the ChatGPT interface to answer a prompt asking about the environmental justice issues in each county . |

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

| cos_sim | doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                            |
|--:|:--|---:|:--------------------------------------------------------------|
|   0.905 | 14     |          16 | With generative AI emerging as a new gateway tool for gaining information, the testing of potential biases in modeling outputs is an important part of improving programs such as ChatGPT.                                                                                                                                      |
|   0.902 | 12     |          49 | Some researchers feared the chatbot would be used to generate disinformation on a massive scale, while others sounded the alarm over ChatGPT’s phishing email-, spam- and malware-generating potential.                                                                                                                         |
|   0.892 | 12     |          50 | The concerns pushed policymakers in Europe to mandate security assessments for any products using generative AI systems like ChatGPT, and over 20,000 signatories — including Elon Musk and Apple co-founder Steve Wozniak — to sign an open letter calling for the immediate pause of large-scale AI experiments like ChatGPT. |
|   0.887 | 12     |          16 | “The primary impact \[ChatGPT\] has had \[is\] encouraging people training AIs to try to mimic it, or encouraging people studying AIs to use it as their central object of study,” Biderman said.                                                                                                                               |
|   0.882 | 4      |          14 | ChatGPT and AI are embedding themselves in systems everywhere so fast that it’s scaring some of the smartest minds on the planet.                                                                                                                                                                                               |

## Summary
