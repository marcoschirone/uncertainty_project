# ------------------------------------------------------------------
# Bibliographic coupling to the UP intellectual base (Kessler 1963).
# For each Part-citing record, n_shared = the count of foundational
# references it shares with the UP intellectual base. This is the
# "intellectual base overlap" measure reported in the manuscript;
# n_shared_unc and n_shared_cs split it by the uncertainty and
# cognitive-styles strands.
# ------------------------------------------------------------------
cit_cr_corrected <- readRDS(file.path(processed_dir, "cit_cr_corrected.rds"))
cit_raw_corrected <- readRDS(file.path(processed_dir, "cit_raw_corrected.rds"))
up_foundations <- readRDS(file.path(processed_dir, "up_foundations.rds"))

# ------------------------------------------------------------------
# Filter to records citing at least one of the five JASIST Parts.
# Removes records that entered the corpus via the pre-2002 UP
# precursors (Wilson 1999 IP&M, Wilson 1999 conference, Ford 2000)
# but cite none of the five 2002 Parts.
# part_dois is defined in R/config.R.
# ------------------------------------------------------------------
part_pattern <- paste(part_dois, collapse = "|")
before_n <- nrow(cit_raw_corrected)
cit_raw_corrected <- cit_raw_corrected %>%
  filter(str_detect(CR, regex(part_pattern, ignore_case = TRUE)))
cit_cr_corrected <- cit_cr_corrected %>%
  filter(UT %in% unique(cit_raw_corrected$UT))
cat("Part-citer filter:", before_n, "->", nrow(cit_raw_corrected),
    "(removed", before_n - nrow(cit_raw_corrected), "non-Part citers)\n\n")

n_external <- length(unique(cit_cr_corrected$UT))
cat("Corrected external citing records:", n_external, "\n\n")

foundation_set <- up_foundations$ref_key

cit_refs_by_ut <- cit_cr_corrected %>%
  group_by(UT) %>%
  summarise(
    n_total_refs = n_distinct(ref_key),
    refs = list(unique(ref_key)),
    .groups = "drop"
  )

coupling <- cit_refs_by_ut %>%
  mutate(
    shared = map(refs, ~ intersect(.x, foundation_set)),
    n_shared = map_int(shared, length),
    has_shared = n_shared > 0,
    jaccard = n_shared / map2_int(refs, shared, ~ length(union(.x, foundation_set))),
    n_shared_unc = map_int(shared, ~ length(intersect(.x, uncertainty_keys))),
    n_shared_cs = map_int(shared, ~ length(intersect(.x, cognitive_styles_keys)))
  ) %>%
  left_join(
    cit_raw_corrected %>% select(UT, TI, PY, SO, DT, TC, flag_type) %>% distinct(),
    by = "UT"
  )

summary_coupling <- coupling %>%
  summarise(
    n_citers = n(),
    n_with_shared = sum(has_shared),
    prop_with_shared = round(n_with_shared / n_citers, 4),
    mean_shared = round(mean(n_shared), 2),
    median_shared = median(n_shared),
    max_shared = max(n_shared),
    mean_jaccard = round(mean(jaccard, na.rm = TRUE), 4),
    median_jaccard = round(median(jaccard, na.rm = TRUE), 4),
    mean_shared_unc = round(mean(n_shared_unc), 2),
    mean_shared_cs = round(mean(n_shared_cs), 2)
  )

cat("=== Corrected-corpus bibliographic-coupling summary ===\n")
print(as.data.frame(summary_coupling))
cat("\n")

saveRDS(coupling, file.path(processed_dir, "coupling.rds"))
saveRDS(summary_coupling, file.path(processed_dir, "summary_coupling.rds"))

write.csv(as.data.frame(summary_coupling), file.path(tables_dir, "coupling_summary.csv"), row.names = FALSE)