# nlpx

A lightweight, versatile NLP companion in R.

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

## Core NLP tasks

### Simple annotation

``` r
df_ss <- articles |>
  mutate(doc_id = row_number()) |>
  nlpx::nlp_split_sentences() 

df_ss |> head() |> knitr::kable()
```

| doc_id | sentence_id | text_id | text                                                                                                                                                                                                                                                                                                                  |
|:--|---:|:--|:--------------------------------------------------------------|
| 1      |           1 | 1.1     | ChatGPT will soon summarize news articles from Politico, Business Insider and other Axel Springer-owned publications—and could include content otherwise available only to paid subscribers —in an unprecedented new agreement that could shape the future of journalism’s relationship with artificial intelligence. |
| 1      |           2 | 1.2     | OpenAI and Germany-based publisher Axel Springer announced the deal Wednesday, and it will include all of Axel Springer’s media brands, which include Politico, Business Insider and European outlets Bild and Welt.                                                                                                  |
| 1      |           3 | 1.3     | Under the agreement, OpenAI will pay Axel Springer for access to its news content, including some that is usually blocked by a paywall, which ChatGPT will be able to summarize in response to user queries with attribution and links to the full stories.                                                           |
| 1      |           4 | 1.4     | OpenAI will also be able to use Axel Springer news content to train ChatGPT, adding a knowledge base of vetted journalistic sources amid ongoing concern about AI’s ability to provide accurate, real-time information.                                                                                               |
| 1      |           5 | 1.5     | The companies say that the agreement will enhance the AI experience for customers while “creating new financial opportunities that support a sustainable future for journalism.”                                                                                                                                      |
| 1      |           6 | 1.6     | The companies have declined to disclose the financial terms of the deal, but the Wall Street Journal reports it’s expected to generate substantial revenue for Axel Springer.                                                                                                                                         |

``` r
df <- df_ss |>
  nlpx::nlp_tokenize_text() |>
  nlpx::nlp_cast_tokens()

df |> head()
```

    ##    text_id     token
    ## 1:     1.1   ChatGPT
    ## 2:     1.1      will
    ## 3:     1.1      soon
    ## 4:     1.1 summarize
    ## 5:     1.1      news
    ## 6:     1.1  articles

## Search

### Text

``` r
df_ss |>
  nlpx::nlp_search_corpus(search = 'artificial intelligence', 
                          highlight = c('**', '**'),
                          n = 0) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                      | start | end | pattern                 | pattern2 | pos |
|:--|:--|:-----------------------------------------------------|-:|-:|:----|:--|:-|
| 1      | 1           | ChatGPT will soon summarize news articles from Politico, Business Insider and other Axel Springer-owned publications—and could include content otherwise available only to paid subscribers —in an unprecedented new agreement that could shape the future of journalism’s relationship with **artificial intelligence**. |   286 | 308 | artificial intelligence | NA       | NA  |
| 1      | 7           | The deal comes as publishers and creators grapple with concern over copyright infringement and compensation in the emerging field of **artificial intelligence**.                                                                                                                                                         |   134 | 156 | artificial intelligence | NA       | NA  |
| 3      | 1           | OpenAI on Thursday said that a major outage on its **artificial intelligence** chatbot, ChatGPT, was resolved.                                                                                                                                                                                                            |    52 |  74 | artificial intelligence | NA       | NA  |
| 7      | 26          | But last year’s list also didn’t include any **artificial intelligence**-related entries.                                                                                                                                                                                                                                 |    46 |  68 | artificial intelligence | NA       | NA  |
| 9      | 14          | OpenAI recently added DALL-E 3, its most powerful version of an **artificial intelligence** image generator to date, to ChatGPT Plus and Enterprise subscriptions.                                                                                                                                                        |    65 |  87 | artificial intelligence | NA       | NA  |
| 10     | 1           | **Artificial intelligence** chatbots exhibits similar biases to humans, according to new research published in Proceedings of the National Academy of Sciences of the United States of America (PNAS).                                                                                                                    |     1 |  23 | Artificial intelligence | NA       | NA  |
| 13     | 146         | The Texas federal judge has added a requirement that any attorney appearing in his court must attest that “no portion of the filing was drafted by generative **artificial intelligence**,” or if it was, that it was checked “by a human being.”                                                                         |   159 | 181 | artificial intelligence | NA       | NA  |
| 13     | 223         | ChatGPT is a general-purpose chatbot that uses **artificial intelligence** to generate text after a user enters a prompt, developed by tech startup OpenAI.                                                                                                                                                               |    48 |  70 | artificial intelligence | NA       | NA  |
| 16     | 2           | A formal announcement of the plans is expected as early as this month at an **artificial intelligence** strategy council meeting.                                                                                                                                                                                         |    77 |  99 | artificial intelligence | NA       | NA  |
| 17     | 2           | The news comes as publishers, artists, writers and technologists increasingly weigh or pursue legal action against companies behind popular generative **artificial intelligence** tools, including chatbots and image-generation models, for allegedly using their content or creations as training data.                |   152 | 174 | artificial intelligence | NA       | NA  |
| 18     | 27          | How do these laws and rules apply to **artificial intelligence**?                                                                                                                                                                                                                                                         |    38 |  60 | artificial intelligence | NA       | NA  |
| 19     | 1           | The world of **artificial intelligence** (AI) was taken by a storm as the buzz around the potential launch of OpenAI’s latest LLM, ChatGPT 4.5, surfaced on the horizon.                                                                                                                                                  |    14 |  36 | artificial intelligence | NA       | NA  |

### df

``` r
df |>
  nlpx::nlp_search_df(search_col = 'token', 
                      id_col = 'text_id',
                      include = c('ChatGPT', 'prompt'),
                      logic = 'and',
                      exclude = NULL) |>
  
  group_by(text_id) |>
  summarize(text = paste0(token, collapse = ' ')) |>
  knitr::kable()
```

| text_id | text                                                                                                                                                        |
|:----|:------------------------------------------------------------------|
| 13.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI . |
| 13.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                       |
| 15.69   | OpenAI first rolled out the ability to prompt ChatGPT with your voice and images in September , but it only made the feature available to paying users .    |
| 2.52    | Ask your closest friends and trusted team members to complete the square brackets in this prompt in ChatGPT and send you the result .                       |
