pairs <- function(text, ...) {
  res <- util_find_abbreviations(data.frame(doc_id = "d1", text = text), ...)
  stats::setNames(res$long_form, res$short_form)
}

test_that("basic definitions with hyphens, digits and back-to-back pairs", {
  p <- pairs("tumor necrosis factor (TNF) and interleukin-6 (IL-6) rose in type 2 diabetes mellitus (T2DM).")
  expect_equal(p[["TNF"]], "tumor necrosis factor")
  expect_equal(p[["IL-6"]], "interleukin-6")
  expect_equal(p[["T2DM"]], "type 2 diabetes mellitus")
  expect_length(p, 3)
})

test_that("trailing text after ';' is dropped and reverse direction works", {
  p <- pairs("magnetic resonance imaging (MRI; see ref 3) and the BMI (body mass index).")
  expect_equal(p[["MRI"]], "magnetic resonance imaging")
  expect_equal(p[["BMI"]], "body mass index")
  expect_length(p, 2)
})

test_that("plural short forms and short forms starting with a digit", {
  p <- pairs("Selective serotonin reuptake inhibitors (SSRIs) and 5-hydroxytryptamine (5-HT)")
  expect_equal(p[["SSRIs"]], "Selective serotonin reuptake inhibitors")
  expect_equal(p[["5-HT"]], "5-hydroxytryptamine")
  expect_length(p, 2)
})

test_that("taxonomic match in a document with no parentheses", {
  res <- util_find_abbreviations(data.frame(
    doc_id = "d1",
    text = "Escherichia coli was cultured. Growth of E. coli was slow."
  ))
  expect_equal(nrow(res), 1)
  expect_equal(res$short_form, "E. coli")
  expect_equal(res$long_form, "Escherichia coli")
  expect_equal(res$method, "taxonomic")
})

test_that("statistical and date parentheticals are ignored", {
  p <- pairs("Patients (n = 40) were enrolled (2019). Results were significant (p < 0.05).")
  expect_length(p, 0)
})

test_that("missing and empty text is skipped without error", {
  res <- util_find_abbreviations(data.frame(doc_id = c("a", "b"), text = c(NA, "")))
  expect_equal(nrow(res), 0)
})

test_that("empty result is a zero-row data.table with all four columns", {
  res <- util_find_abbreviations(data.frame(doc_id = "a", text = "Nothing here."))
  expect_s3_class(res, "data.table")
  expect_equal(nrow(res), 0)
  expect_named(res, c("doc_id", "short_form", "long_form", "method"))
})

test_that("methods filters the output", {
  corpus <- data.frame(
    doc_id = "d1",
    text = "Escherichia coli (EC) was cultured. Growth of E. coli was slow."
  )
  tax <- util_find_abbreviations(corpus, methods = "taxonomic")
  par <- util_find_abbreviations(corpus, methods = "parenthetical")
  expect_gt(nrow(tax), 0)
  expect_gt(nrow(par), 0)
  expect_true(all(tax$method == "taxonomic"))
  expect_true(all(par$method == "parenthetical"))
})

test_that("missing doc_id or text columns stop with a clear error", {
  expect_error(util_find_abbreviations(data.frame(text = "x")), "doc_id")
  expect_error(util_find_abbreviations(data.frame(doc_id = "x")), "text")
})

test_that("invalid methods value errors via match.arg()", {
  expect_error(
    util_find_abbreviations(data.frame(doc_id = "a", text = "x"), methods = "bogus"),
    "should be one of"
  )
})

test_that("a duplicate pair within one document appears once", {
  res <- util_find_abbreviations(data.frame(
    doc_id = "d1",
    text = "body mass index (BMI) was high. Later, body mass index (BMI) fell."
  ))
  expect_equal(nrow(res), 1)
})

test_that("the same pair in two documents appears once per document", {
  res <- util_find_abbreviations(data.frame(
    doc_id = c("a", "b"),
    text = "body mass index (BMI) was high."
  ))
  expect_equal(res$doc_id, c("a", "b"))
})

test_that("rows sharing `by` values are pooled into one unit", {
  corpus <- data.frame(
    doc_id = c("a", "a", "b"),
    node_id = c(1, 2, 1),
    text = c("Escherichia coli was cultured.", "Growth of E. coli was slow.",
             "Growth of E. coli was slow.")
  )
  res <- util_find_abbreviations(corpus, by = "doc_id", methods = "taxonomic")
  expect_equal(res$doc_id, "a")
  expect_named(res, c("doc_id", "short_form", "long_form", "method"))

  # Splitting by node keeps the definition and the short form apart
  res2 <- util_find_abbreviations(corpus, by = c("doc_id", "node_id"))
  expect_equal(nrow(res2), 0)
  expect_named(res2, c("doc_id", "node_id", "short_form", "long_form", "method"))
})

test_that("initials before function words are not taxonomic pairs", {
  res <- util_find_abbreviations(data.frame(
    doc_id = "d1",
    text = "Site and Silva and Jones S. and Smith reported on Escherichia coli and E. coli."
  ), methods = "taxonomic")
  expect_equal(res$short_form, "E. coli")
})

test_that("lines and table cells do not leak into long forms", {
  res <- util_find_abbreviations(data.frame(
    doc_id = "d1",
    text = paste("George McDermott (Republican)", "Sam Husseini (Green)",
                 "Buddy Roemer (ran unsuccessfully for the Reform Party nomination)",
                 "The Federal Election Commission (FEC) regulates political action committees (PACs).",
                 sep = "\n")
  ))
  expect_setequal(res$short_form, c("FEC", "PACs"))
})

test_that("2,000 short documents run in under 2 seconds", {
  skip_on_cran()
  texts <- c(
    "tumor necrosis factor (TNF) and interleukin-6 (IL-6) rose in type 2 diabetes mellitus (T2DM).",
    "magnetic resonance imaging (MRI; see ref 3) and the BMI (body mass index).",
    "Escherichia coli was cultured. Growth of E. coli was slow.",
    "Patients (n = 40) were enrolled (2019). Results were significant (p < 0.05)."
  )
  corpus <- data.frame(doc_id = seq_len(2000), text = rep(texts, 500))
  elapsed <- system.time(util_find_abbreviations(corpus))[["elapsed"]]
  expect_lt(elapsed, 2)
})
