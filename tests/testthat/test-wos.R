test_that("cited references are parsed per record, with continuation lines", {
  path <- write_export(list(
    c("PT J", "TI First", "CR SMITH J, 1999, J DOC, V1, P1",
      "   JONES K, 2001, INFORM PROCESS MANAG, V2, P3", "UT WOS:1", "ER"),
    c("PT J", "TI No references", "UT WOS:2", "ER"),
    c("PT J", "CR ORPHAN A, 2000, X", "ER"),
    c("PT J", "CR LAST B, 2002, Y", "UT WOS:3")
  ))
  cr <- parse_wos_cr(path)
  expect_equal(cr$UT, c("WOS:1", "WOS:1"))
  expect_equal(cr$CR, c("SMITH J, 1999, J DOC, V1, P1", "JONES K, 2001, INFORM PROCESS MANAG, V2, P3"))
})

test_that("references normalise to author, year and source", {
  expect_equal(normalize_ref("Wilson TD,  1999, J DOC, V55, P249"), "WILSON TD, 1999, J DOC")
  expect_equal(normalize_ref("SPINK A, IN PRESS INFORMATION"), "SPINK A")
  expect_equal(normalize_ref("SPINK A"), "SPINK A")
})

test_that("keys without a year are unresolvable and years are extracted", {
  expect_true(is_unresolvable("SPINK A"))
  expect_false(is_unresolvable("SPINK A, 1997, J AM SOC INFORM SCI"))
  expect_equal(ref_year(c("BELKIN NJ, 1982, J DOC", "WILSON TD")), c(1982L, NA))
  expect_true(is_generic("[ANONYMOUS], 1998, THESIS U N TEXAS"))
})

test_that("merge rules map variant keys onto one form", {
  rules <- data.frame(from = "ELLIS D., 1989, JOURNAL OF DOCUMENTATION", to = "ELLIS D, 1989, J DOC")
  expect_equal(apply_merges(c("ELLIS D., 1989, JOURNAL OF DOCUMENTATION", "X"), rules),
               c("ELLIS D, 1989, J DOC", "X"))
})
