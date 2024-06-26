% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/web_process_gnewsfeed.R
\name{web_process_gnewsfeed}
\alias{web_process_gnewsfeed}
\title{Process Google News Feed}
\usage{
web_process_gnewsfeed(x)
}
\arguments{
\item{x}{A character string representing the search term for the Google News feed.}
}
\value{
A dataframe with columns corresponding to the parsed RSS feed,
        including URL, title, date, and other relevant metadata.
}
\description{
This function takes a search term, builds an RSS feed from Google News, parses it,
and retrieves URLs, returning a dataframe with the relevant article metadata.
}
\examples{
\dontrun{
meta <- web_process_gnewsfeed("Bidenomics")
}

}
