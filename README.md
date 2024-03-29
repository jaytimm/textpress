[![R build
status](https://github.com/jaytimm/textpress/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/textpress/actions)

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
| 3      | 4           | As someone studying <b>artificial intelligence</b> in education, I was curious: Could ChatGPT help?                                                                                                                                                                              |
| 4      | 3           | DOE’s decision is supposed to set the foundation for future agency uses of generative <b>artificial intelligence</b>, Chad Smith, a spokesperson for the department, told FedScoop.                                                                                              |
| 6      | 2           | ChatGPT maker OpenAI finally announced on Wednesday its app store for the public to try the customized versions of its popular chatbot, ChatGPT, as the <b>artificial intelligence</b> company works to expand the reach of its flagship technology and turn it into a cash cow. |
| 7      | 3           | The company has integrated ChatGPT, an <b>artificial intelligence</b>-based chatbot, into its IDA voice assistant, marking a new era in automotive technology.                                                                                                                   |
| 12     | 1           | The field of <b>artificial intelligence</b> (AI) has witnessed a remarkable surge in innovation, with ChatGPT from OpenAI leading the charge.                                                                                                                                    |

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
  tidyr::separate(col = doc_id, 
                  into = c('doc_id', 'sentence_id'), 
                  sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] |> strwrap(width = 55)
```

    ##  [1] "On/IN/1 Wednesday/NNP/2 ,/,/3 OpenAI/NNP/4"           
    ##  [2] "announced/VBD/5 the/DT/6 launch/NN/7 of/IN/8"         
    ##  [3] "its/PRP$/9 GPT/NN/10 Store/NN/11 —/,/12 a/DT/13"      
    ##  [4] "way/NN/14 for/IN/15 ChatGPT/NNP/16 users/NNS/17"      
    ##  [5] "to/TO/18 share/VB/19 and/CC/20 discover/VB/21"        
    ##  [6] "custom/JJ/22 chatbot/NN/23 roles/NNS/24 called/VBN/25"
    ##  [7] "\"/``/26 GPTs/NNS/27 \"/''/28 —/,/29 and/CC/30"       
    ##  [8] "ChatGPT/NNP/31 Team/NNP/32 ,/,/33 a/DT/34"            
    ##  [9] "collaborative/JJ/35 ChatGPT/NN/36 workspace/NN/37"    
    ## [10] "and/CC/38 subscription/NN/39 plan/NN/40 ././41"

### Search for lexico-grammatical pattern

``` r
inline_ss |>
  textpress::search_corpus(search = 'JJ and JJ',
                           highlight = c('<b>', '</b>'),
                           n = 0,
                           is_inline = T) |>

  select(doc_id:text) |>
  filter(tokenizers::count_words(text) < 75) |>
  slice(3:4) |>
  ## DT::datatable(escape = F)
  knitr::kable(escape = F) 
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                           |
|:--|:----|:---------------------------------------------------------------|
| 17     | 11          | Each/DT/1 API/NN/2 has/VBZ/3 to/TO/4 be/VB/5 continuously/RB/6 <b>tested/JJ/7 and/CC/8 verified/JJ/9</b> to/TO/10 ensure/VB/11 your/PRP$/12 software/NN/13 functions/NNS/14 as/IN/15 it/PRP/16 should/MD/17 ././18                             |
| 22     | 31          | Make/VB/1 sure/JJ/2 the/DT/3 affirmation/NN/4 is/VBZ/5 <b>achievable/JJ/6 and/CC/7 positive/JJ/8</b> ,/,/9 and/CC/10 no/RB/11 longer/RBR/12 than/IN/13 \[/-LRB-/14 insert/VB/15 word/NN/16 limit/NN/17 \]/-RRB-/18 words/NNS/19 ././20 ”/’’/21 |

## Search df

> Identify sentences that contain both `ChatGPT` and `education`.

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
| 3.4     | As someone studying artificial intelligence in education , I was curious : Could ChatGPT help ?                                                  |
| 3.41    | My exploration of the exponential decay equation with ChatGPT symbolizes the broader challenges and opportunities presented by AI in education . |

## Retrieval-augmented generation

### Sentence Window Retrieval

> Chunks built out of (n = `chunk_size`) sentences; context added as (n
> = `context_size`) sentences as window before and after chunk. Chunks
> (in bold-face below) are indexed in vector store for retrieval; chunks
> plus contexts (normal font below) serve as input to LLM.

``` r
chunks <- df_ss |>
  textpress::rag_chunk_sentences(chunk_size = 2, 
                                 context_size = 1) 

set.seed(99)
chunks |> sample_n(3) |> select(-chunk) |> knitr::kable(escape = F)
```

| doc_id | chunk_id | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|:-|:--|:-------------------------------------------------------------------|
| 22     | 22.2     | But its use isn’t reserved for workspaces and classrooms. <b>Thanks to its massive corpus of training data and sophisticated algorithms its applications are quite literally endless – creating valuable opportunities for users looking to unlock their best self in 2024, and beyond. Whether you’re in your ‘new year, new me’ era, or you simply want to build healthier habits and stick to them year-round, we’ve rounded up some of the top self-improvement prompts to feed ChatGPT this January.</b> We also offer advice on what makes a great prompt, to help you get the most out of generative AI. |
| 22     | 22.13    | Some of my personal, professional, and academic goals include: \[include examples of goals\]. <b>Use a mixture of inspiring imagery and language, and don’t make the vision board any bigger than \[insert size limit here\]. “Use a neutral color palette and cursive fonts like this vision board: \[insert photo of vision board here\].”</b> Daily affirmations are positive mantras you repeat routinely to encourage optimism and success.                                                                                                                                                                |
| 2      | 2.8      | I either queried for news or gave them links to news reports and asked the model to summarize them or write an article based on them. <b>I did not like the results. The articles they generate don’t follow a logical flow and I ended up restructuring the text.</b> The models sometimes repeat facts at different places or place them where they don’t make sense.                                                                                                                                                                                                                                         |

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

| cos_sim | doc_id | chunk                                                                                                                                                                                                                                                                                                                 |
|--:|:--|:-----------------------------------------------------------------|
|   0.877 | 3      | My interaction with ChatGPT underscores the necessity for students to be equipped with the ability to challenge and question the information provided by AI. While these tools are powerful, they are not infallible.                                                                                                 |
|   0.874 | 1      | As usual, our standard Ars warning about AI language models applies: “Bring your own data” for analysis, don’t rely on ChatGPT as a factual resource, and don’t rely on its outputs in ways you cannot personally confirm. OpenAI has provided more details about ChatGPT Team on its website.                        |
|   0.873 | 16     | The issues surrounding its tendency to basically steal preexisting content will undoubtedly continue to mount for the AI company, unless they can prove that what ChatGPT is doing is indeed “fair use.” Mind Matters features original news and analysis at the intersection of artificial and natural intelligence. |
|   0.869 | 3      | Faced with a challenging problem, I wanted to confirm my understanding before guiding hers. As someone studying artificial intelligence in education, I was curious: Could ChatGPT help?                                                                                                                              |
|   0.865 | 16     | ChatGPT, the large language model developed by OpenAI, might seem like it generates novel content, but of course we know that it partakes in what’s generally called “scraping.” It takes pre-existing material on the Internet in response to the prompt a human user inserts.                                       |

## Summary
