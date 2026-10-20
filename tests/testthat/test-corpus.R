ref <- load_reference(reference_files)

test_that("the reference data are consistent", {
  expect_equal(nrow(ref$parts), 5)
  expect_setequal(ref$part_corrections$action, c("remove", "retain", "add"))
  expect_length(ref$correction_category, nrow(ref$part_corrections))
})

test_that("Part attribution uses DOI or start page and applies corrections", {
  cr <- tibble(
    UT = c("A", "B", "C", "C"),
    CR = c("SPINK A, 2002, J AM SOC INF SCI TEC, V53, P695, DOI 10.1002/asi.10081",
           "FORD N, 2002, J AM SOC INF SCI TEC, V53, P728",
           "WILSON TD, 2002, J AM SOC INF SCI TEC, V53, P704, DOI 10.1002/ASI.10082",
           "UNRELATED, 2002, X, V53, P7040")
  )
  corrections <- tibble(UT = c("C", "B"), part = c("P2", "P1"), action = c("remove", "add"),
                        status = "test", note = "")
  out <- attribute_parts(cr, ref, corrections)
  expect_equal(paste(out$UT, out$part), c("A P1", "B P1", "B P4"))
})

test_that("a mixed record stays in the corpus and a pure false positive is removed", {
  ref2 <- ref
  ref2$base_exclusions <- tibble(UT = "BASE", reason = "test")
  ref2$part_corrections <- tibble(
    UT = c("MIXED", "MIXED", "FP"), part = c("P1", "P2", "P3"),
    action = c("remove", "retain", "remove"), status = "test", note = "")
  ref2$record_flags <- tibble(UT = "MIXED", flag_type = "self_citation")
  uts <- c("MIXED", "FP", "BASE", "OK")
  wos <- list(citing_refs = tibble(UT = uts, CR = "X", ref_key = "X"),
              citing_records = tibble(UT = uts, CR = "X"))
  out <- apply_corrections(wos, ref2)
  expect_setequal(out$uts, c("MIXED", "OK"))
  expect_equal(out$record_summary$record_level_false_positives_removed, 1)
  expect_equal(out$records$flag_type[out$records$UT == "MIXED"], "self_citation")
})

test_that("coupling counts shared foundations by strand", {
  r <- list(uncertainty_keys = "U1", cs_keys = "C1")
  by_record <- tibble(UT = c("a", "b"), n_total_refs = c(3L, 1L),
                      refs = list(c("U1", "C1", "Z"), "Z"))
  cp <- couple(by_record, c("U1", "C1", "F"), r)
  expect_equal(cp$n_shared, c(2L, 0L))
  expect_equal(cp$n_shared_unc, c(1L, 0L))
  expect_equal(overlap_class(c(0, 1, 2, 3, 7)),
               c("surface_citer", "intermediate", "intermediate", "intellectual_heir", "intellectual_heir"))
})
