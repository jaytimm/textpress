% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/web_scrape_urls.R
\name{web_scrape_urls}
\alias{web_scrape_urls}
\title{Scrape News Data from Various Sources}
\usage{
web_scrape_urls(x, cores = 3)
}
\arguments{
\item{x}{A character vector of URLs.}

\item{cores}{The number of cores to use for parallel processing.}
}
\value{
A data frame containing scraped news data.
}
\description{
Function scrapes content of provided list of URLs.
}
\examples{
\dontrun{
url <- 'https://www.nytimes.com/2024/03/25/nyregion/trump-bond-reduced.html'
article_tif <- web_scrape_urls(x = url, input = 'urls', cores = 1)
}


}
