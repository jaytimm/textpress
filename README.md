# textpress

A lightweight, versatile NLP companion in R. Provides basic features for
(1) text processing, (2) corpus search, and (3) web scraping.
Additionally, the package provides utility functions for (4) building
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

| doc_id | sentence_id | text_id | text                                                                                                                                                                                                                   |
|:--|----:|:---|:------------------------------------------------------------|
| 1      |           1 | 1.1     | On Wednesday, OpenAI announced the launch of its GPT Store—a way for ChatGPT users to share and discover custom chatbot roles called “GPTs”—and ChatGPT Team, a collaborative ChatGPT workspace and subscription plan. |
| 1      |           2 | 1.2     | OpenAI bills the new store as a way to “help you find useful and popular custom versions of ChatGPT” for members of Plus, Team, or Enterprise subscriptions.                                                           |
| 1      |           3 | 1.3     | “It’s been two months since we announced GPTs, and users have already created over 3 million custom versions of ChatGPT,” writes OpenAI in its promotional blog.                                                       |
| 1      |           4 | 1.4     | “Many builders have shared their GPTs for others to use.                                                                                                                                                               |
| 1      |           5 | 1.5     | Today, we’re starting to roll out the GPT Store to ChatGPT Plus, Team and Enterprise users so you can find useful and popular GPTs.”                                                                                   |

### Tokenization

``` r
tokens <- df_ss |> textpress::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "On"            "Wednesday"     ","             "OpenAI"       
    ##  [5] "announced"     "the"           "launch"        "of"           
    ##  [9] "its"           "GPT"           "Store"         "—"            
    ## [13] "a"             "way"           "for"           "ChatGPT"      
    ## [17] "users"         "to"            "share"         "and"          
    ## [21] "discover"      "custom"        "chatbot"       "roles"        
    ## [25] "called"        "\""            "GPTs"          "\""           
    ## [29] "—"             "and"           "ChatGPT"       "Team"         
    ## [33] ","             "a"             "collaborative" "ChatGPT"      
    ## [37] "workspace"     "and"           "subscription"  "plan"         
    ## [41] "."

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                             |
|:--|:---|:----------------------------------------------------------------|
| 3      | 2           | We explore the brief history of the generative <b>artificial intelligence</b> (AI) platform, reflect on its origins and its power to disrupt and transform operations.                                                                                                           |
| 4      | 1           | Free TV company, Telly, debuted its new <b>artificial intelligence</b> voice assistant, “Hey Telly,” at CES 2024.                                                                                                                                                                |
| 6      | 4           | As someone studying <b>artificial intelligence</b> in education, I was curious: Could ChatGPT help?                                                                                                                                                                              |
| 8      | 2           | ChatGPT maker OpenAI finally announced on Wednesday its app store for the public to try the customized versions of its popular chatbot, ChatGPT, as the <b>artificial intelligence</b> company works to expand the reach of its flagship technology and turn it into a cash cow. |
| 9      | 3           | The company has integrated ChatGPT, an <b>artificial intelligence</b>-based chatbot, into its IDA voice assistant, marking a new era in automotive technology.                                                                                                                   |

## Search inline

### Annotate corpus with `udpipe`

``` r
ud_annotated_corpus <- udpipe::udpipe(object = model,
                                      x = tokens,
                                      tagger = 'default',
                                      parser = 'none')
```

| doc_id | start | end | term_id | token_id | token     | lemma     | upos  | xpos |
|:-------|------:|----:|--------:|:---------|:----------|:----------|:------|:-----|
| 1.1    |     1 |   2 |       1 | 1        | On        | on        | ADP   | IN   |
| 1.1    |     4 |  12 |       2 | 2        | Wednesday | Wednesday | PROPN | NNP  |
| 1.1    |    14 |  14 |       3 | 3        | ,         | ,         | PUNCT | ,    |
| 1.1    |    16 |  21 |       4 | 4        | OpenAI    | OpenAI    | PROPN | NNP  |
| 1.1    |    23 |  31 |       5 | 5        | announced | announce  | VERB  | VBD  |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, into = c('doc_id', 'sentence_id'), sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "On/IN/1 Wednesday/NNP/2 ,/,/3 OpenAI/NNP/4 announced/VBD/5 the/DT/6 launch/NN/7 of/IN/8 its/PRP$/9 GPT/NN/10 Store/NN/11 —/,/12 a/DT/13 way/NN/14 for/IN/15 ChatGPT/NNP/16 users/NNS/17 to/TO/18 share/VB/19 and/CC/20 discover/VB/21 custom/JJ/22 chatbot/NN/23 roles/NNS/24 called/VBN/25 \"/``/26 GPTs/NNS/27 \"/''/28 —/,/29 and/CC/30 ChatGPT/NNP/31 Team/NNP/32 ,/,/33 a/DT/34 collaborative/JJ/35 ChatGPT/NN/36 workspace/NN/37 and/CC/38 subscription/NN/39 plan/NN/40 ././41"

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

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|:--|:----|:----------------------------------------------------------------|
| 14     | 5           | In/IN/1 our/PRP/2*t**e**s**t**s*/*N**N**S*/3, /, /4*B**a**r**d*/*N**N**P*/5*d**e**m**o**n**s**t**r**a**t**e**d*/*V**B**D*/6*a*/*D**T*/7*s**l**i**g**h**t*/*J**J*/8*e**d**g**e*/*N**N*/9*i**n*/*I**N*/10*p**r**o**v**i**d**i**n**g*/*V**B**G*/11*m**o**r**e*/*R**B**R*/12 \< *b* \> *n**u**a**n**c**e**d*/*J**J*/13*a**n**d*/*C**C*/14*d**e**t**a**i**l**e**d*/*J**J*/15 \< /*b* \> *r**e**s**p**o**n**s**e**s*/*N**N**S*/16*c**o**m**p**a**r**e**d*/*V**B**N*/17*t**o*/*I**N*/18*C**h**a**t**G**P**T*/*N**N**P*/19././20\|\|18\|11\|*E**a**c**h*/*D**T*/1*A**P**I*/*N**N*/2*h**a**s*/*V**B**Z*/3*t**o*/*T**O*/4*b**e*/*V**B*/5*c**o**n**t**i**n**u**o**u**s**l**y*/*R**B*/6 \< *b* \> *t**e**s**t**e**d*/*J**J*/7*a**n**d*/*C**C*/8*v**e**r**i**f**i**e**d*/*J**J*/9 \< /*b* \> *t**o*/*T**O*/10*e**n**s**u**r**e*/*V**B*/11*y**o**u**r*/*P**R**P*/12 software/NN/13 functions/NNS/14 as/IN/15 it/PRP/16 should/MD/17 ././18 |
| 23     | 31          | Make/VB/1 sure/JJ/2 the/DT/3 affirmation/NN/4 is/VBZ/5 <b>achievable/JJ/6 and/CC/7 positive/JJ/8</b> ,/,/9 and/CC/10 no/RB/11 longer/RBR/12 than/IN/13 \[/-LRB-/14 insert/VB/15 word/NN/16 limit/NN/17 \]/-RRB-/18 words/NNS/19 ././20 ”/’’/21                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| 24     | 18          | Try/VB/1 to/TO/2 make/VB/3 the/DT/4 name/NN/5 as/IN/6 <b>descriptive/JJ/7 and/CC/8 catchy/JJ/9</b> as/IN/10 possible/JJ/11 ././12                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

## Search df

``` r
tokens |>
  textpress::nlp_cast_tokens() |>
  
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
| 15.24   | Embrace the future of education by leveraging the capabilities of ChatGPT to unlock your full academic potential .                               |
| 6.4     | As someone studying artificial intelligence in education , I was curious : Could ChatGPT help ?                                                  |
| 6.41    | My exploration of the exponential decay equation with ChatGPT symbolizes the broader challenges and opportunities presented by AI in education . |

## Retrieval-augmented generation

### Sentence Window Retrieval

``` r
chunks <- df_ss |>
  textpress::rag_chunk_sentences(chunk_size = 2, 
                                 context_size = 1) 

chunks |> sample_n(3) |> knitr::kable(escape = F)
```

| doc_id | chunk_id | chunk                                                                                                                                                                                                                                                                                                                                                                                                                                                         | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
|:-|:-|:---------------------------|:----------------------------------------|
| 6      | 6.29     | Many parents feel their children aren’t ready for kindergarten, after the pandemic disrupted their ability to socialize and learn skills. Stay ahead of the latest developments on education in California and nationally from early childhood to college and beyond.                                                                                                                                                                                         | Initial results are positive with lots of room for improvement. <b>Many parents feel their children aren’t ready for kindergarten, after the pandemic disrupted their ability to socialize and learn skills. Stay ahead of the latest developments on education in California and nationally from early childhood to college and beyond.</b> Sign up for EdSource’s no-cost daily email.                                                                                                                                                                                                                                                                                     |
| 26     | 26.1     | Microsoft Copilot, the company’s recently launched AI chatbot built with OpenAI technologies, does not yet appear to be siphoning users away from OpenAI’s own ChatGPT, according to a new analysis of app store data. Copilot, which combines an AI chatbot with an Image Creator feature powered by DALL-E 3, is notable for offering free access to OpenAI’s newer GPT-4 technology — something that OpenAI charges for in ChatGPT, which runs on GPT-3.5. | <b>Microsoft Copilot, the company’s recently launched AI chatbot built with OpenAI technologies, does not yet appear to be siphoning users away from OpenAI’s own ChatGPT, according to a new analysis of app store data. Copilot, which combines an AI chatbot with an Image Creator feature powered by DALL-E 3, is notable for offering free access to OpenAI’s newer GPT-4 technology — something that OpenAI charges for in ChatGPT, which runs on GPT-3.5.</b> Given it’s a free alternative, it’s somewhat surprising that Copilot’s launch hasn’t seemingly impacted ChatGPT’s installs or revenue as of yet — but that could be explained by the lack of promotion. |
| 6      | 6.24     | Jonathan Osler is a nonprofit consultant and was formerly a high school teacher, principal, and CalTeach faculty member. The opinions in this commentary are those of the author.                                                                                                                                                                                                                                                                             | (Follow the entire interaction with ChatGPT in the screenshots below.) <b>Jonathan Osler is a nonprofit consultant and was formerly a high school teacher, principal, and CalTeach faculty member. The opinions in this commentary are those of the author.</b> If you would like to submit a commentary, please review our guidelines and contact us.                                                                                                                                                                                                                                                                                                                       |

### OpenAI embeddings

``` r
vstore <- chunks |>
  mutate(words = tokenizers::count_words(chunk)) |>
  filter(words > 20, words < 60) |>
  mutate(batch_id = textpress::rag_batch_cumsum(x = words,
                                                threshold = 10000)) |>

  textpress::rag_fetch_openai_embs(text_id = 'chunk_id',
                                   text = 'chunk',
                                   batch_id = 'batch_id')
```

    ## [1] "Batch 1 of 2"
    ## [1] "Batch 2 of 2"

### Semantic search

``` r
q <- 'What are some concerns about the impact of
advanced AI models like ChatGPT?'
```

``` r
query <- textpress::rag_fetch_openai_embs(query = q)

textpress::search_semantics(x = query,
                            matrix = vstore,
                            n = 5) |>

  left_join(chunks, by = c('term2' = 'chunk_id')) |>
  select(cos_sim:chunk) |>
  knitr::kable()
```

| cos_sim | doc_id | chunk                                                                                                                                                                                                                                                                                          |
|--:|:--|:-----------------------------------------------------------------|
|   0.888 | 6      | My interaction with ChatGPT underscores the necessity for students to be equipped with the ability to challenge and question the information provided by AI. While these tools are powerful, they are not infallible.                                                                          |
|   0.883 | 3      | Many charities will also be wary of AI replacing jobs. While disruption, transformation, and innovation sometimes lead to an upskilling in roles, ChatGPT still needs human intervention.                                                                                                      |
|   0.883 | 1      | As usual, our standard Ars warning about AI language models applies: “Bring your own data” for analysis, don’t rely on ChatGPT as a factual resource, and don’t rely on its outputs in ways you cannot personally confirm. OpenAI has provided more details about ChatGPT Team on its website. |
|   0.879 | 3      | There are ethical issues surrounding the use of ChatGPT. The information it pulls together to formulate a response should be taken with a grain of scepticism.                                                                                                                                 |
|   0.879 | 3      | The model was fine-tuned and optimised to better engage in sustained dialogues, leading to the birth of ChatGPT.” ChatGPT and its predecessors are impactful because they can seem like living people.                                                                                         |

## Summary
