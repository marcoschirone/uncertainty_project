up_raw  <- convert2df(up_file,  dbsource = "wos", format = "plaintext")
cit_raw <- convert2df(cit_file, dbsource = "wos", format = "plaintext")

cat("Source papers (raw):", nrow(up_raw), "| Citing set (raw):", nrow(cit_raw), "\n\n")

# ------------------------------------------------------------------
# Restrict UP source to the five-paper JASIST series.
# The source WoS file (citing_jasist5.txt) contains exactly five
# records corresponding to the five Parts. Filtering to
# all_five_uts ensures all five Parts contribute to the
# intellectual base. The three pre-2002 contextual papers
# (Wilson 1999 IP&M, Wilson 1999 conference, Ford 2000 ASIS)
# are not in this file; the erratum is excluded separately.
# ------------------------------------------------------------------
up_raw <- up_raw %>% filter(UT %in% all_five_uts)

# Hard guard: the intellectual base must be built from exactly the five Parts.
# If the source export is swapped for the old eight-record file, this stops the
# run instead of silently producing eight-Part results.
if (nrow(up_raw) != 5L) {
  stop(
    "Expected exactly 5 UP source records after filtering to all_five_uts, but found ",
    nrow(up_raw),
    ". Check that up_file points at citing_jasist5.txt (five Parts), not the ",
    "old eight-record export.",
    call. = FALSE
  )
}

up_cr  <- parse_wos_cr(up_file)
cit_cr <- parse_wos_cr(cit_file)

up_cr  <- up_cr %>% filter(UT %in% all_five_uts)
stopifnot("UP cited-reference set must cover all five Parts" =
            length(unique(up_cr$UT)) == 5L)

cat("Source papers (filtered to JASIST series):", nrow(up_raw), "\n")
cat("UP CR rows:", nrow(up_cr), "| Citing CR rows:", nrow(cit_cr), "\n\n")

up_cr  <- up_cr  %>% mutate(ref_key = normalize_ref(CR))
cit_cr <- cit_cr %>% mutate(ref_key = normalize_ref(CR))

cat("Distinct keys UP:", length(unique(up_cr$ref_key)), "\n")

up_cr  <- up_cr  %>% mutate(ref_key = apply_merges(ref_key, merge_rules))
cit_cr <- cit_cr %>% mutate(ref_key = apply_merges(ref_key, merge_rules))

cat("Post-dedup keys UP:", length(unique(up_cr$ref_key)), "\n\n")

saveRDS(up_raw, file.path(processed_dir, "up_raw.rds"))
saveRDS(cit_raw, file.path(processed_dir, "cit_raw.rds"))
saveRDS(up_cr,  file.path(processed_dir, "up_cr.rds"))
saveRDS(cit_cr, file.path(processed_dir, "cit_cr.rds"))