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

## Basic annotation

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

df |> head() |> knitr::kable()
```

| text_id | token     |
|:--------|:----------|
| 1.1     | ChatGPT   |
| 1.1     | will      |
| 1.1     | soon      |
| 1.1     | summarize |
| 1.1     | news      |
| 1.1     | articles  |

## Search text

``` r
df_ss |>
  nlpx::nlp_search_corpus(search = 'artificial intelligence', 
                          highlight = c('**', '**'),
                          n = 0) |>
  
  select(doc_id:text) |>
  knitr::kable(escape = F)
```

| doc_id | sentence_id | text                                                                                                                                                                                                                                                                                                                      |
|:--|:---|:-----------------------------------------------------------------|
| 1      | 1           | ChatGPT will soon summarize news articles from Politico, Business Insider and other Axel Springer-owned publications—and could include content otherwise available only to paid subscribers —in an unprecedented new agreement that could shape the future of journalism’s relationship with **artificial intelligence**. |
| 1      | 7           | The deal comes as publishers and creators grapple with concern over copyright infringement and compensation in the emerging field of **artificial intelligence**.                                                                                                                                                         |
| 4      | 1           | OpenAI on Thursday said that a major outage on its **artificial intelligence** chatbot, ChatGPT, was resolved.                                                                                                                                                                                                            |
| 5      | 5           | Google Pixel 8 phone owners will be among the first to tap into its new **artificial intelligence** abilities, but Gemini will come to Gmail and other Google Workspace tools in early 2024.                                                                                                                              |
| 7      | 26          | But last year’s list also didn’t include any **artificial intelligence**-related entries.                                                                                                                                                                                                                                 |
| 8      | 8           | “He said he was cooking fries to make money over the summer, and he would rather be working for me doing AI,” says Hinton, who is often recognized as the godfather of modern **artificial intelligence** (AI).                                                                                                           |
| 10     | 14          | OpenAI recently added DALL-E 3, its most powerful version of an **artificial intelligence** image generator to date, to ChatGPT Plus and Enterprise subscriptions.                                                                                                                                                        |
| 14     | 1           | ChatGPT, an **artificial intelligence** (AI) chatbot that returns answers to written prompts, has been tested and found wanting by researchers at the University of Florida College of Medicine (UF Health) who looked into how well it could answer typical patient questions on urology.                                |
| 14     | 18          | Pathologists and clinical laboratory managers will want to monitor how developers improve the performance of chatbots and other applications using **artificial intelligence**.                                                                                                                                           |
| 16     | 146         | The Texas federal judge has added a requirement that any attorney appearing in his court must attest that “no portion of the filing was drafted by generative **artificial intelligence**,” or if it was, that it was checked “by a human being.”                                                                         |
| 16     | 223         | ChatGPT is a general-purpose chatbot that uses **artificial intelligence** to generate text after a user enters a prompt, developed by tech startup OpenAI.                                                                                                                                                               |
| 19     | 2           | The news comes as publishers, artists, writers and technologists increasingly weigh or pursue legal action against companies behind popular generative **artificial intelligence** tools, including chatbots and image-generation models, for allegedly using their content or creations as training data.                |
| 20     | 27          | How do these laws and rules apply to **artificial intelligence**?                                                                                                                                                                                                                                                         |
| 21     | 2           | A formal announcement of the plans is expected as early as this month at an **artificial intelligence** strategy council meeting.                                                                                                                                                                                         |

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
  knitr::kable()
```

| text_id | text                                                                                                                                                            |
|:----|:------------------------------------------------------------------|
| 12.52   | Ask your closest friends and trusted team members to complete the square brackets in this prompt in ChatGPT and send you the result .                           |
| 16.223  | ChatGPT is a general - purpose chatbot that uses artificial intelligence to generate text after a user enters a prompt , developed by tech startup OpenAI .     |
| 16.242  | ChatGPT is AI - powered and utilizes LLM technology to generate text after a prompt .                                                                           |
| 18.69   | OpenAI first rolled out the ability to prompt ChatGPT with your voice and images in September , but it only made the feature available to paying users .        |
| 3.20    | When prompting ChatGPT , you should not only follow the 9 rules for an effective prompt , but also ask ChatGPT if the prompt you’re about to give is suitable . |
| 3.32    | Create a checklist , explain the rationale behind your prompt , and check ChatGPT has everything it needs before it begins .                                    |
| 3.46    | Re - read your original prompt and figure out what you said that caused ChatGPT to go in the wrong direction .                                                  |
| 3.59    | Put more thought into how you prompt ChatGPT for better results than you’ve been getting so far .                                                               |

## OpenAI embeddings

``` r
vstore <- df_ss |>
  mutate(words = tokenizers::count_words(text),
         batch_id = nlpx::nlp_batch_cumsum(x = words, threshold = 10000)) |>
  nlpx::nlp_fetch_openai_embs(text_id = 'text_id',
                              text = 'text',
                              batch_id = 'batch_id')
```

    ## [1] "Batch 1 of 3"
    ## [1] "Batch 2 of 3"
    ## [1] "Batch 3 of 3"

## Basic retrieval

``` r
query <- nlpx::nlp_fetch_openai_embs(query = 'Fears and risks associated with ChatGPT and the future?')

nlpx::nlp_find_neighbors(x = query, matrix = vstore, n = 15) |>
  left_join(df_ss, by = c('term2' = 'text_id')) |>
  select(cos_sim:text) |>
  knitr::kable()
```

| cos_sim | doc_id | sentence_id | text                                                                                                                                                              |
|---:|:---|-----:|:----------------------------------------------------------|
|   0.880 | 14     |          35 | Is Using ChatGPT for Medical Advice Dangerous to Patients?                                                                                                        |
|   0.874 | 16     |          59 | An independent review from Common Sense Media, a nonprofit advocacy group, found that ChatGPT could potentially be harmful for younger users.                     |
|   0.871 | 11     |          19 | But for many, it was ChatGPT’s release as a free-to-use dialogue agent in November 2022 that quickly revealed this technology’s power and pitfalls.               |
|   0.859 | 11     |          41 | ChatGPT has a large environmental impact, problematic biases and can mislead its users into thinking that its output comes from a person, she says.               |
|   0.858 | 16     |          50 | What this means for ChatGPT’s future, and for the OpenAI Dev Day announcements, remains to be seen.                                                               |
|   0.857 | 20     |           1 | Better performance than ChatGPT?                                                                                                                                  |
|   0.855 | 16     |           4 | What does that mean for OpenAI, ChatGPT and its other ambitions?                                                                                                  |
|   0.854 | 8      |          54 | ChatGPT: Boon and burden?                                                                                                                                         |
|   0.854 | 8      |          50 | ChatGPT: Boon and burden?                                                                                                                                         |
|   0.852 | 16     |         116 | “As you may know, the government has been tightening regulations associated with deep synthesis technologies (DST) and generative AI services, including ChatGPT. |
|   0.851 | 16     |          56 | This announcement comes at a time when ChatGPT is being criticized by educators for encouraging cheating, resulting in bans in certain school districts.          |
|   0.851 | 16     |           6 | While there is a more…nefarious side to ChatGPT, it’s clear that AI tools are not going away anytime soon.                                                        |
|   0.850 | 16     |          60 | ChatGPT got an overall three-star rating in the report, with its lowest ratings relating to transparency, privacy, trust and safety.                              |
|   0.849 | 16     |         156 | Meta said in a report on May 3 that malware posing as ChatGPT was on the rise across its platforms.                                                               |
|   0.849 | 16     |         229 | Anyone can use ChatGPT!                                                                                                                                           |
