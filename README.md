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

| doc_id | sentence_id | text_id | text                                                                                                                                                          |
|:---|-----:|:---|:----------------------------------------------------------|
| 1      |           1 | 1.1     | I tested several tools and tried different prompting techniques.                                                                                              |
| 1      |           2 | 1.2     | After months of experiments and dozens of articles written with the help of large language models (LLM), I’ve decided to stick with good-old writing by hand. |
| 1      |           3 | 1.3     | However, ChatGPT has changed my approach to writing for the better, even if it is not the tool I use most often.                                              |
| 1      |           4 | 1.4     | I don’t think the technology is ready to replace professional writers.                                                                                        |
| 1      |           5 | 1.5     | But that can change very soon, which is why I’m also preparing for what is to come.                                                                           |

### Tokenization

``` r
tokens <- df_ss |> textpress::nlp_tokenize_text()
```

    ## $`1.1`
    ##  [1] "I"          "tested"     "several"    "tools"      "and"       
    ##  [6] "tried"      "different"  "prompting"  "techniques" "."

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
| 4      | 16          | In April, the Cyberspace Administration of China released draft regulations on the development of generative <b>artificial intelligence</b> models that would require “AI-produced content \[to\] embody core socialist values.”                                                 |
| 5      | 1           | Free TV company, Telly, debuted its new <b>artificial intelligence</b> voice assistant, “Hey Telly,” at CES 2024.                                                                                                                                                                |
| 6      | 4           | As someone studying <b>artificial intelligence</b> in education, I was curious: Could ChatGPT help?                                                                                                                                                                              |
| 8      | 2           | ChatGPT maker OpenAI finally announced on Wednesday its app store for the public to try the customized versions of its popular chatbot, ChatGPT, as the <b>artificial intelligence</b> company works to expand the reach of its flagship technology and turn it into a cash cow. |

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
| 1.1    |     1 |   1 |       1 | 1        | I       | I       | PRON  | PRP  |
| 1.1    |     3 |   8 |       2 | 2        | tested  | test    | VERB  | VBD  |
| 1.1    |    10 |  16 |       3 | 3        | several | several | ADJ   | JJ   |
| 1.1    |    18 |  22 |       4 | 4        | tools   | tool    | NOUN  | NNS  |
| 1.1    |    24 |  26 |       5 | 5        | and     | and     | CCONJ | CC   |

### Build inline text

``` r
inline_ss <- ud_annotated_corpus |>
  mutate(inline = paste0(token, '/', xpos, '/', token_id)) |>
  tidyr::separate(col = doc_id, 
                  into = c('doc_id', 'sentence_id'), 
                  sep = '\\.') |>
  group_by(doc_id, sentence_id) |>
  summarise(text = paste0(inline, collapse = " "))

inline_ss$text[1] #|> strwrap(width = 40)
```

    ## [1] "I/PRP/1 tested/VBD/2 several/JJ/3 tools/NNS/4 and/CC/5 tried/VBD/6 different/JJ/7 prompting/NN/8 techniques/NNS/9 ././10"

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
  knitr::kable(escape = F, format = "html") |>
  kableExtra::kable_styling(c("striped", "condensed"), full_width = T,) 
```

<table class="table table-striped table-condensed" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
doc_id
</th>
<th style="text-align:left;">
sentence_id
</th>
<th style="text-align:left;">
text
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
14
</td>
<td style="text-align:left;">
5
</td>
<td style="text-align:left;">
In/IN/1
our/PRP$/2 tests/NNS/3 ,/,/4 Bard/NNP/5 demonstrated/VBD/6 a/DT/7 slight/JJ/8 edge/NN/9 in/IN/10 providing/VBG/11 more/RBR/12 \<b\>nuanced/JJ/13 and/CC/14 detailed/JJ/15\</b\> responses/NNS/16 compared/VBN/17 to/IN/18 ChatGPT/NNP/19 ././20 \</td\>  \</tr\>  \<tr\>  \<td style="text-align:left;"\> 18 \</td\>  \<td style="text-align:left;"\> 11 \</td\>  \<td style="text-align:left;"\> Each/DT/1 API/NN/2 has/VBZ/3 to/TO/4 be/VB/5 continuously/RB/6 \<b\>tested/JJ/7 and/CC/8 verified/JJ/9\</b\> to/TO/10 ensure/VB/11 your/PRP$/12
software/NN/13 functions/NNS/14 as/IN/15 it/PRP/16 should/MD/17 ././18
</td>
</tr>
<tr>
<td style="text-align:left;">
24
</td>
<td style="text-align:left;">
31
</td>
<td style="text-align:left;">
Make/VB/1 sure/JJ/2 the/DT/3 affirmation/NN/4 is/VBZ/5
<b>achievable/JJ/6 and/CC/7 positive/JJ/8</b> ,/,/9 and/CC/10 no/RB/11
longer/RBR/12 than/IN/13 \[/-LRB-/14 insert/VB/15 word/NN/16 limit/NN/17
\]/-RRB-/18 words/NNS/19 ././20 ”/’’/21
</td>
</tr>
<tr>
<td style="text-align:left;">
25
</td>
<td style="text-align:left;">
18
</td>
<td style="text-align:left;">
Try/VB/1 to/TO/2 make/VB/3 the/DT/4 name/NN/5 as/IN/6
<b>descriptive/JJ/7 and/CC/8 catchy/JJ/9</b> as/IN/10 possible/JJ/11
././12
</td>
</tr>
</tbody>
</table>

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

<table>
<thead>
<tr>
<th style="text-align:left;">
text_id
</th>
<th style="text-align:left;">
text
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
15.24
</td>
<td style="text-align:left;">
Embrace the future of education by leveraging the capabilities of
ChatGPT to unlock your full academic potential .
</td>
</tr>
<tr>
<td style="text-align:left;">
6.4
</td>
<td style="text-align:left;">
As someone studying artificial intelligence in education , I was curious
: Could ChatGPT help ?
</td>
</tr>
<tr>
<td style="text-align:left;">
6.41
</td>
<td style="text-align:left;">
My exploration of the exponential decay equation with ChatGPT symbolizes
the broader challenges and opportunities presented by AI in education .
</td>
</tr>
</tbody>
</table>

## Retrieval-augmented generation

### Sentence Window Retrieval

``` r
chunks <- df_ss |>
  textpress::rag_chunk_sentences(chunk_size = 2, 
                                 context_size = 1) 

set.seed(99)
chunks |> sample_n(3) |> knitr::kable(escape = F)
```

<table>
<thead>
<tr>
<th style="text-align:left;">
doc_id
</th>
<th style="text-align:left;">
chunk_id
</th>
<th style="text-align:left;">
chunk
</th>
<th style="text-align:left;">
chunk_plus_context
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
22
</td>
<td style="text-align:left;">
22.2
</td>
<td style="text-align:left;">
And it’s not pulling its punches. The suit seeks not just monetary
compensation but also the destruction of all the defendant’s LLM models
and training data, as well as a halt to unlicensed training on the
publication’s articles.
</td>
<td style="text-align:left;">
The publication recently filed a lawsuit against OpenAI and Microsoft
that claims copyright infringement, trademark dilution, and unfair
competition. <b>And it’s not pulling its punches. The suit seeks not
just monetary compensation but also the destruction of all the
defendant’s LLM models and training data, as well as a halt to
unlicensed training on the publication’s articles.</b> “When you have
these big technology shifts, the law has to adjust,” says Cecilia
Ziniti, a Silicon Valley attorney.
</td>
</tr>
<tr>
<td style="text-align:left;">
22
</td>
<td style="text-align:left;">
22.13
</td>
<td style="text-align:left;">
“The fact that OpenAI made deals with others shows there is a market for
this particular use for data,” says Ziniti. Masnick is more skeptical
that these agreements will be a factor, but notes that “a judge can
decide whatever they want….
</td>
<td style="text-align:left;">
OpenAI also reached an agreement with the Associated Press. <b>“The fact
that OpenAI made deals with others shows there is a market for this
particular use for data,” says Ziniti. Masnick is more skeptical that
these agreements will be a factor, but notes that “a judge can decide
whatever they want….</b> It’s not very predictable.”
</td>
</tr>
<tr>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
1.22
</td>
<td style="text-align:left;">
But I preserved the process of writing detailed outlines before writing
the first draft, especially if I was doing research. It has made my
writing more concise, my editing faster, and the entire process more
pleasant.
</td>
<td style="text-align:left;">
I eventually decided to return to manual writing. <b>But I preserved the
process of writing detailed outlines before writing the first draft,
especially if I was doing research. It has made my writing more concise,
my editing faster, and the entire process more pleasant.</b> Now, I
write and iterate on my outline several times before writing my first
draft.
</td>
</tr>
</tbody>
</table>

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

<table>
<thead>
<tr>
<th style="text-align:right;">
cos_sim
</th>
<th style="text-align:left;">
doc_id
</th>
<th style="text-align:left;">
chunk
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
0.887
</td>
<td style="text-align:left;">
6
</td>
<td style="text-align:left;">
My interaction with ChatGPT underscores the necessity for students to be
equipped with the ability to challenge and question the information
provided by AI. While these tools are powerful, they are not infallible.
</td>
</tr>
<tr>
<td style="text-align:right;">
0.883
</td>
<td style="text-align:left;">
3
</td>
<td style="text-align:left;">
Many charities will also be wary of AI replacing jobs. While disruption,
transformation, and innovation sometimes lead to an upskilling in roles,
ChatGPT still needs human intervention.
</td>
</tr>
<tr>
<td style="text-align:right;">
0.879
</td>
<td style="text-align:left;">
3
</td>
<td style="text-align:left;">
There are ethical issues surrounding the use of ChatGPT. The information
it pulls together to formulate a response should be taken with a grain
of scepticism.
</td>
</tr>
<tr>
<td style="text-align:right;">
0.879
</td>
<td style="text-align:left;">
3
</td>
<td style="text-align:left;">
The model was fine-tuned and optimised to better engage in sustained
dialogues, leading to the birth of ChatGPT.” ChatGPT and its
predecessors are impactful because they can seem like living people.
</td>
</tr>
<tr>
<td style="text-align:right;">
0.877
</td>
<td style="text-align:left;">
15
</td>
<td style="text-align:left;">
In the ever-evolving landscape of education, technology has become a
game-changer, revolutionizing the way students approach learning. One
such groundbreaking tool that has gained prominence is ChatGPT, a
sophisticated language model developed by OpenAI.
</td>
</tr>
</tbody>
</table>

## Summary
