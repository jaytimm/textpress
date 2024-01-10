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
| 3      | 16          | In April, the Cyberspace Administration of China released draft regulations on the development of generative <b>artificial intelligence</b> models that would require “AI-produced content \[to\] embody core socialist values.”                                                 |
| 4      | 1           | Free TV company, Telly, debuted its new <b>artificial intelligence</b> voice assistant, “Hey Telly,” at CES 2024.                                                                                                                                                                |
| 5      | 4           | As someone studying <b>artificial intelligence</b> in education, I was curious: Could ChatGPT help?                                                                                                                                                                              |
| 7      | 2           | ChatGPT maker OpenAI finally announced on Wednesday its app store for the public to try the customized versions of its popular chatbot, ChatGPT, as the <b>artificial intelligence</b> company works to expand the reach of its flagship technology and turn it into a cash cow. |
| 8      | 3           | The company has integrated ChatGPT, an <b>artificial intelligence</b>-based chatbot, into its IDA voice assistant, marking a new era in automotive technology.                                                                                                                   |

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

inline_ss$text[1] |> strwrap(width = 60)
```

    ## [1] "On/IN/1 Wednesday/NNP/2 ,/,/3 OpenAI/NNP/4 announced/VBD/5"  
    ## [2] "the/DT/6 launch/NN/7 of/IN/8 its/PRP$/9 GPT/NN/10"           
    ## [3] "Store/NN/11 —/,/12 a/DT/13 way/NN/14 for/IN/15"              
    ## [4] "ChatGPT/NNP/16 users/NNS/17 to/TO/18 share/VB/19 and/CC/20"  
    ## [5] "discover/VB/21 custom/JJ/22 chatbot/NN/23 roles/NNS/24"      
    ## [6] "called/VBN/25 \"/``/26 GPTs/NNS/27 \"/''/28 —/,/29 and/CC/30"
    ## [7] "ChatGPT/NNP/31 Team/NNP/32 ,/,/33 a/DT/34"                   
    ## [8] "collaborative/JJ/35 ChatGPT/NN/36 workspace/NN/37 and/CC/38" 
    ## [9] "subscription/NN/39 plan/NN/40 ././41"

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
| 24     | 31          | Make/VB/1 sure/JJ/2 the/DT/3 affirmation/NN/4 is/VBZ/5 <b>achievable/JJ/6 and/CC/7 positive/JJ/8</b> ,/,/9 and/CC/10 no/RB/11 longer/RBR/12 than/IN/13 \[/-LRB-/14 insert/VB/15 word/NN/16 limit/NN/17 \]/-RRB-/18 words/NNS/19 ././20 ”/’’/21 |
| 25     | 18          | Try/VB/1 to/TO/2 make/VB/3 the/DT/4 name/NN/5 as/IN/6 <b>descriptive/JJ/7 and/CC/8 catchy/JJ/9</b> as/IN/10 possible/JJ/11 ././12                                                                                                              |

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
| 15.24   | Embrace the future of education by leveraging the capabilities of ChatGPT to unlock your full academic potential .                               |
| 5.4     | As someone studying artificial intelligence in education , I was curious : Could ChatGPT help ?                                                  |
| 5.41    | My exploration of the exponential decay equation with ChatGPT symbolizes the broader challenges and opportunities presented by AI in education . |

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
chunks |> sample_n(3) |> knitr::kable(escape = F)
```

| doc_id | chunk_id | chunk                                                                                                                                                                                                                                                                                                                                                               | chunk_plus_context                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|:-|:-|:-------------------------|:------------------------------------------|
| 22     | 22.7     | “Whenever you have a verbatim copy, that’s a replacement, and that’s going to be pretty colorable \[plausible to the court\],” says Ziniti. “The New York Times also has enough of a library, going back to 1851, that they can actually say some percentage of the training data was New York Times.”                                                              | The claim is supported by 100 examples of ChatGPT reproducing near-exact copy from New York Times articles. <b>“Whenever you have a verbatim copy, that’s a replacement, and that’s going to be pretty colorable \[plausible to the court\],” says Ziniti. “The New York Times also has enough of a library, going back to 1851, that they can actually say some percentage of the training data was New York Times.”</b> Even so, the suit’s victory isn’t certain.                                                                                                                                                                        |
| 22     | 22.18    | In the meantime, companies and organizations training AI face a potential minefield—and may want to keep an eye on the source of data used for training. “From an engineering point of view, when you add a new source to your dataset to train on, you keep track of that, figure out where you looked at it, note the terms of use for the website,” says Ziniti. | But even this act is not yet law, and it’s unclear when the regulations it outlines will come into effect. <b>In the meantime, companies and organizations training AI face a potential minefield—and may want to keep an eye on the source of data used for training. “From an engineering point of view, when you add a new source to your dataset to train on, you keep track of that, figure out where you looked at it, note the terms of use for the website,” says Ziniti.</b> She notes that training from sources that include a wide variety of data, such as Common Crawl, is more defensible than training on a narrow dataset. |
| 2      | 2.8      | I did not like the results. The articles they generate don’t follow a logical flow and I ended up restructuring the text.                                                                                                                                                                                                                                           | I either queried for news or gave them links to news reports and asked the model to summarize them or write an article based on them. <b>I did not like the results. The articles they generate don’t follow a logical flow and I ended up restructuring the text.</b> The models sometimes repeat facts at different places or place them where they don’t make sense.                                                                                                                                                                                                                                                                     |

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

| cos_sim | doc_id | chunk                                                                                                                                                                                                                                                                                                                                    |
|--:|:--|:------------------------------------------------------------------|
|   0.888 | 5      | My interaction with ChatGPT underscores the necessity for students to be equipped with the ability to challenge and question the information provided by AI. While these tools are powerful, they are not infallible.                                                                                                                    |
|   0.883 | 1      | As usual, our standard Ars warning about AI language models applies: “Bring your own data” for analysis, don’t rely on ChatGPT as a factual resource, and don’t rely on its outputs in ways you cannot personally confirm. OpenAI has provided more details about ChatGPT Team on its website.                                           |
|   0.877 | 15     | In the ever-evolving landscape of education, technology has become a game-changer, revolutionizing the way students approach learning. One such groundbreaking tool that has gained prominence is ChatGPT, a sophisticated language model developed by OpenAI.                                                                           |
|   0.875 | 5      | Faced with a challenging problem, I wanted to confirm my understanding before guiding hers. As someone studying artificial intelligence in education, I was curious: Could ChatGPT help?                                                                                                                                                 |
|   0.871 | 19     | Generative artificial intelligence has come to forefront of the technology industry’s mind after OpenAI released ChatGPT in late 2022. Since then, companies from Google (GOOG) (GOOGL) to Amazon (AMZN) and Apple (AAPL) have jumped on the AI bandwagon, trying to incorporate smarter technology into everyday products and services. |

## Summary
