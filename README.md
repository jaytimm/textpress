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

| doc_id | sentence_id | text_id | text                                                                                                                                                                                                                                    |
|:--|----:|:---|:-------------------------------------------------------------|
| 1      |           1 | 1.1     | InstructGPT is a refined iteration of OpenAI’s GPT-3 model, expertly fine-tuned to better comprehend and execute user commands, while producing outputs that are more ethical, accurate, and in harmony with human intentions.          |
| 1      |           2 | 1.2     | This advancement signifies a substantial stride in the evolution of AI models, steering them towards more responsive and ethically attuned interactions.                                                                                |
| 1      |           3 | 1.3     | InstructGPT is based on the research paper titled “Training Language Models to Follow Instructions” and its official page on OpenAI is here.                                                                                            |
| 1      |           4 | 1.4     | Although both InstructGPT and ChatGPT are developed by OpenAI and these two models are grounded in the GPT (Generative Pre-trained Transformer) architecture , they are different in methodologies, objectives and training approaches. |
| 1      |           5 | 1.5     | ChatGPT: Primarily designed as a conversational agent, ChatGPT excels in generating human-like text responses.                                                                                                                          |

### Tokenization

``` r
tokens <- df_ss |> textpress::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "InstructGPT" "is"          "a"           "refined"     "iteration"  
    ##  [6] "of"          "OpenAI's"    "GPT"         "-"           "3"          
    ## [11] "model"       ","           "expertly"    "fine"        "-"          
    ## [16] "tuned"       "to"          "better"      "comprehend"  "and"        
    ## [21] "execute"     "user"        "commands"    ","           "while"      
    ## [26] "producing"   "outputs"     "that"        "are"         "more"       
    ## [31] "ethical"     ","           "accurate"    ","           "and"        
    ## [36] "in"          "harmony"     "with"        "human"       "intentions" 
    ## [41] "."

### Cast tokens to df

``` r
df <- tokens |> textpress::nlp_cast_tokens()
df |> head() |> knitr::kable()
```

| text_id | token       |
|:--------|:------------|
| 1.1     | InstructGPT |
| 1.1     | is          |
| 1.1     | a           |
| 1.1     | refined     |
| 1.1     | iteration   |
| 1.1     | of          |

## Search text

``` r
df_ss |>
  textpress::search_corpus(search = 'artificial intelligence',
                          highlight = c('<b>', '</b>'),
                          n = 0,
                          is_inline = F) |>

  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                    |
|:---|:----|:---------------------------------------------------------------|
| 2      | 2           | We explore the brief history of the generative <b>artificial intelligence</b> (AI) platform, reflect on its origins and its power to disrupt and transform operations.                                                  |
| 3      | 1           | Free TV company, Telly, debuted its new <b>artificial intelligence</b> voice assistant, “Hey Telly,” at CES 2024.                                                                                                       |
| 5      | 4           | As someone studying <b>artificial intelligence</b> in education, I was curious: Could ChatGPT help?                                                                                                                     |
| 6      | 1           | SAN FRANCISCO (Reuters) - <b>Artificial intelligence</b> lab OpenAI has launched its GPT Store, a marketplace for personalized artificial intelligence (AI) applications, the company said in a blog post on Wednesday. |
| 6      | 1           | SAN FRANCISCO (Reuters) - Artificial intelligence lab OpenAI has launched its GPT Store, a marketplace for personalized <b>artificial intelligence</b> (AI) applications, the company said in a blog post on Wednesday. |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token       | lemma       | upos | xpos |
|:-------|------:|----:|--------:|:---------|:------------|:------------|:-----|:-----|
| 1.1    |     1 |  11 |       1 | 1        | InstructGPT | Instructgpt | PART | RB   |
| 1.1    |    13 |  14 |       2 | 2        | is          | be          | AUX  | VBZ  |
| 1.1    |    16 |  16 |       3 | 3        | a           | a           | DET  | DT   |
| 1.1    |    18 |  24 |       4 | 4        | refined     | refined     | VERB | VBN  |
| 1.1    |    26 |  34 |       5 | 5        | iteration   | iteration   | NOUN | NN   |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "InstructGPT/RB/1 is/VBZ/2 a/DT/3 refined/VBN/4 iteration/NN/5 of/IN/6 OpenAI's/NNPS/7 GPT/NNP/8 -/,/9 3/CD/10 model/NN/11 ,/,/12 expertly/RB/13 fine/JJ/14 -/HYPH/15 tuned/VBN/16 to/TO/17 better/RBR/18 comprehend/VB/19 and/CC/20 execute/VB/21 user/JJR/22 commands/NNS/23 ,/,/24 while/IN/25 producing/VBG/26 outputs/NNS/27 that/WDT/28 are/VBP/29 more/RBR/30 ethical/JJ/31 ,/,/32 accurate/JJ/33 ,/,/34 and/CC/35 in/IN/36 harmony/NN/37 with/IN/38 human/JJ/39 intentions/NNS/40 ././41"

### Search for lexico-grammatical pattern

``` r
inline_ss |>
  textpress::search_corpus(search = 'JJ model',
                           highlight = c('<b>', '</b>'),
                           n = 0,
                           is_inline = T) |>

  select(doc_id:text) |>
  slice(1:5) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
|:-|:--|:------------------------------------------------------------------|
| 22     | 14          | The/DT/1 limit/NN/2 really/RB/3 is/VBZ/4 your/PRP/5*i**m**a**g**i**n**a**t**i**o**n*/*N**N*/6, /, /7*b**u**t*/*C**C*/8*i**d**e**a**s*/*N**N**S*/9*c**a**n*/*M**D*/10*s**p**a**n*/*V**B*/11*f**r**o**m*/*I**N*/12*p**r**a**c**t**i**c**a**l*/*J**J*/13*u**s**e*/*N**N*/14*c**a**s**e**s*/*N**N**S*/15*l**i**k**e*/*I**N*/16*S**E**O*/*N**N*/17*h**e**l**p**e**r**s*/*N**N**S*/18*a**n**d*/*C**C*/19*n**u**t**r**i**t**i**o**n*/*N**N*/20*p**l**a**n**n**e**r**s*/*N**N**S*/21, /, /22*t**o*/*I**N*/23*m**o**r**e*/*J**J**R*/24*b**i**z**a**r**r**e*/*N**N*/25*c**o**n**c**e**p**t**s*/*N**N**S*/26*l**i**k**e*/*I**N*/27*B**a**d**R**e**c**i**p**e*/*N**N**P*/28*G**P**T*/*N**N**P*/29–/, /30*a*/*D**T*/31 \< *b* \> *c**u**s**t**o**m*/*J**J*/32*m**o**d**e**l*/*N**N*/33 \< /*b* \> *d**e**s**i**g**n**e**d*/*V**B**N*/34*t**o*/*T**O*/35*p**u**t*/*V**B*/36*y**o**u*/*P**R**P*/37*o**f**f*/*R**P*/38*y**o**u**r*/*P**R**P*/39 dinner/NN/40 by/IN/41 inventing/VBG/42 bad/JJ/43 and/CC/44 amusing/JJ/45 recipes/NNS/46 ././47 |
| 22     | 22          | Now/RB/1 it’s/PRP/2*t**i**m**e*/*N**N*/3*t**o*/*T**O*/4*t**e**s**t*/*V**B*/5*y**o**u**r*/*P**R**P*/6 <b>custom/JJ/7 model/NN/8</b> ././9                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| 4      | 14          | “/\`\`/1 Telly/RB/2 ,/,/3 with/IN/4 its/PRP$/5 <b>unique/JJ/6 model/NN/7</b> and/CC/8 innovative/JJ/9 ad/NN/10 inventory/NN/11 ,/,/12 solves/VBZ/13 that/DT/14 problem/NN/15 ././16                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

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
| 11.24   | Embrace the future of education by leveraging the capabilities of ChatGPT to unlock your full academic potential .                               |
| 5.4     | As someone studying artificial intelligence in education , I was curious : Could ChatGPT help ?                                                  |
| 5.41    | My exploration of the exponential decay equation with ChatGPT symbolizes the broader challenges and opportunities presented by AI in education . |

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
|   0.881 | 16     |           1 | Generative AI, particularly OpenAI’s ChatGPT, is making waves in the tech industry, transforming the way we interact with the internet and reshaping our technological experiences.                                                 |
|   0.879 | 5      |          21 | My interaction with ChatGPT underscores the necessity for students to be equipped with the ability to challenge and question the information provided by AI.                                                                        |
|   0.872 | 17     |           6 | The type of algorithm behind the popular ChatGPT, large language models have taken the world by storm with their ability to understand language, audio, and image inputs, while doling out useful—if not always accurate—responses. |
|   0.867 | 25     |          10 | ChatGPT is a text-generating AI chatbot developed by OpenAI, a company that has launched into the stratosphere of buzzy tech startups over the past year.                                                                           |
|   0.865 | 16     |          18 | While the potential benefits of generative AI are vast, it’s important to temper this enthusiasm with a realistic understanding of the challenges ahead.                                                                            |

## Summary
