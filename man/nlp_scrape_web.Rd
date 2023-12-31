% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nlp_scrape_web.R
\name{nlp_scrape_web}
\alias{nlp_scrape_web}
\title{Scrape News Data from Various Sources}
\usage{
nlp_scrape_web(x, input = "search", cores = 3)
}
\arguments{
\item{x}{A character string for the search query or RSS feed URL, or a character vector of URLs.}

\item{input}{A character string specifying the input type: 'search', 'rss', or 'urls'.}

\item{cores}{The number of cores to use for parallel processing.}
}
\value{
A data frame containing scraped news data.
}
\description{
Function accepts three types of input:
a Google News search query, a direct list of news URLs, or an RSS feed URL. Depending on the input type,
it either performs a Google News search and processes the resulting RSS feeds, directly scrapes the
provided URLs, or processes an RSS feed to extract URLs for scraping.
}
