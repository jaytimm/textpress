#' textpress: A Lightweight and Versatile NLP Toolkit
#'
#' A lightweight toolkit for text retrieval and NLP with a consistent and
#' predictable API organized around four actions: fetching, reading, processing,
#' and searching. Functions cover the full pipeline from web data acquisition to
#' text processing and indexing. Multiple search strategies are supported
#' including regex, BM25 keyword ranking, cosine similarity, and dictionary
#' matching. Pipe-friendly with no heavy dependencies and all outputs are plain
#' data frames. Also useful as a building block for retrieval-augmented
#' generation pipelines and autonomous agent workflows.
#'
#' @importFrom utils head tail
#' @importFrom stats runif setNames
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom data.table :=
#' @importFrom data.table .BY
#' @importFrom data.table .EACHI
#' @importFrom data.table .GRP
#' @importFrom data.table .I
#' @importFrom data.table .N
#' @importFrom data.table .NGRP
#' @importFrom data.table .SD
#' @importFrom data.table data.table
## usethis namespace: end
NULL
