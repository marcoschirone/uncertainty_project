test_that("Wilson interval matches the closed form", {
  ref_ci <- as.numeric(stats::prop.test(35, 43, correct = FALSE)$conf.int)
  expect_equal(wilson_ci(35, 43), ref_ci, tolerance = 1e-4)
  expect_equal(wilson_ci(0, 0), c(NA_real_, NA_real_))
})

test_that("kappa is 1 for perfect agreement and NA when chance agreement is complete", {
  lev <- c("a", "b")
  expect_equal(unname(cohen_kappa(c("a", "b", "a"), c("a", "b", "a"), lev)["kappa"]), 1)
  expect_true(is.na(cohen_kappa(c("a", "a"), c("a", "a"), lev)["kappa"]))
})

test_that("Cramer's V ignores empty rows and columns", {
  tab <- matrix(c(10, 0, 0, 10, 0, 0), 2)
  expect_equal(cramers_v(tab), 1)
})

test_that("percentages refuse a non-scalar denominator", {
  expect_equal(safe_pct(1, 4), 25)
  expect_error(safe_pct(1, c(2, 3)))
  expect_true(is.na(safe_pct(1, 0)))
})

test_that("agreement coefficients match hand-computed values", {
  a <- c("x", "x", "y", "y", "x")
  b <- c("x", "y", "y", "y", "x")
  out <- agreement_coefficients(a, b)
  expect_equal(unname(out["agreement"]), 0.8)
  expect_equal(unname(out["cohen_kappa"]), 0.32 / 0.52)
  expect_equal(unname(out["cohen_kappa"]), unname(cohen_kappa(a, b, c("x", "y"))["kappa"]))
  expect_equal(unname(out["scott_pi"]), 0.6)
  expect_equal(unname(out["gwet_ac1"]), 0.6)
  expect_equal(unname(out["krippendorff_alpha"]), 1 - 9 * 2 / (100 - 50))
  expect_true(is.na(agreement_coefficients(c("x", "x"), c("x", "x"))["scott_pi"]))
})
