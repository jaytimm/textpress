% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sem_search_corpus.R
\name{.insert_highlight}
\alias{.insert_highlight}
\title{Insert Highlight in Text}
\usage{
.insert_highlight(text, start, end, highlight)
}
\arguments{
\item{text}{The text string where highlighting is to be applied.}

\item{start}{The starting position of the substring to highlight.}

\item{end}{The ending position of the substring to highlight.}

\item{highlight}{A character vector of length two specifying the
opening and closing highlight markers.}
}
\value{
A character string with the specified substring highlighted.
}
\description{
Inserts highlight markers around a specified substring in a text string.
Used to visually emphasize search query matches in the text.
}
\keyword{internal}
