cit_raw <- readRDS(file.path(processed_dir, "cit_raw.rds"))
cit_cr  <- readRDS(file.path(processed_dir, "cit_cr.rds"))

# Start with raw WoS citing records, remove intra-project/correction records,
# then apply validation corrections.
raw_uts <- unique(cit_cr$UT)

base_exclusions <- uts_drop_base

# ------------------------------------------------------------------
# Correction logic
# ------------------------------------------------------------------
# Part-level corrections are not the same as record-level removals.
#
# A paper can be a false positive for one UP Part but a genuine citer
# of another Part. Such mixed cases must be retained in the forward
# bibliographic-coupling corpus.
#
# Therefore:
# - remove_candidates = all records with at least one Part-level removal
# - retain_or_add     = records with at least one confirmed genuine/addition
# - record_level_false_positives = records removed from the forward corpus
#   because no verified genuine UP citation remains in the correction layer.
# ------------------------------------------------------------------

remove_candidates <- unique(part_corrections$UT[part_corrections$action == "remove"])
retain_or_add <- unique(part_corrections$UT[part_corrections$action %in% c("retain", "add")])

record_level_false_positives <- setdiff(remove_candidates, retain_or_add)

# Always remove base exclusions: intra-project cross-citations + correction/erratum.
corrected_exclusions <- unique(c(base_exclusions, record_level_false_positives))

# Confirmed missed citations can only be added automatically if the UT is present
# in the raw citing export. Otherwise they are reported as missing for follow-up.
manual_add_present <- intersect(manual_add_uts, raw_uts)
manual_add_missing <- setdiff(manual_add_uts, raw_uts)

corrected_uts <- setdiff(raw_uts, corrected_exclusions)
corrected_uts <- union(corrected_uts, manual_add_present)

cit_cr_corrected <- cit_cr %>%
  filter(UT %in% corrected_uts)

cit_raw_corrected <- cit_raw %>%
  filter(UT %in% corrected_uts) %>%
  left_join(record_flags, by = "UT") %>%
  mutate(flag_type = tidyr::replace_na(flag_type, "external"))

# ------------------------------------------------------------------
# Audit tables
# ------------------------------------------------------------------

audit <- part_corrections %>%
  mutate(
    in_raw_export = UT %in% raw_uts,
    part_level_remove = action == "remove",
    record_removed_from_forward_corpus = UT %in% record_level_false_positives,
    record_retained_in_forward_corpus = UT %in% corrected_uts,
    note_on_record_handling = dplyr::case_when(
      UT %in% base_exclusions ~ "removed_base_exclusion",
      UT %in% record_level_false_positives ~ "removed_record_level_false_positive",
      action %in% c("retain", "add") & UT %in% corrected_uts ~ "retained_or_added",
      action == "add" & !(UT %in% raw_uts) ~ "add_requested_but_missing_from_raw_export",
      TRUE ~ "part_level_only"
    )
  )

part_summary <- part_corrections %>%
  group_by(part, action, status) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(part, action, status)

record_summary <- tibble::tibble(
  raw_wos_records = length(raw_uts),
  base_exclusions = length(base_exclusions),
  part_level_remove_annotations = sum(part_corrections$action == "remove"),
  unique_remove_candidate_records = length(remove_candidates),
  mixed_records_retained = length(intersect(remove_candidates, retain_or_add)),
  record_level_false_positives_removed = length(record_level_false_positives),
  manual_additions_present_in_raw_export = length(manual_add_present),
  manual_additions_missing_from_raw_export = length(manual_add_missing),
  corrected_records = length(corrected_uts)
)

# Explicit reconciliation table for manuscript reporting.
# Note: manual additions present in the raw export usually do not increase
# the unique record count, because the record is already part of raw_uts.
# They correct Part-level attribution, not necessarily record-level membership.

corpus_reconciliation <- tibble::tibble(
  step = c(
    "Raw WoS citing records",
    "Base exclusions (intra-project cross-citations + correction/erratum)",
    "Record-level false positives removed",
    "Manual additions present in raw export",
    "Manual additions missing from raw export",
    "Final corrected corpus"
  ),
  count = c(
    length(raw_uts),
    length(base_exclusions),
    length(record_level_false_positives),
    length(manual_add_present),
    length(manual_add_missing),
    length(corrected_uts)
  ),
  effect_on_unique_record_count = c(
    length(raw_uts),
    -length(base_exclusions),
    -length(record_level_false_positives),
    0,
    0,
    length(corrected_uts)
  ),
  note = c(
    "Initial WoS-derived citing-record set",
    "Removed before coupling analysis",
    "Confirmed false-positive records with no retained/add citation",
    "Already present as records; corrects Part-level attribution",
    "Not included automatically; requires supplemental record metadata",
    "Corpus used for corrected-corpus coupling analysis"
  )
)

# Arithmetic check
expected_final <- length(raw_uts) - length(base_exclusions) - length(record_level_false_positives)

if (expected_final != length(corrected_uts)) {
  warning(
    "Reconciliation mismatch: expected ",
    expected_final,
    " but corrected_uts has ",
    length(corrected_uts),
    ". Check manual additions and duplicate UTs."
  )
}

cat("Raw citing records:", length(raw_uts), "\n")
cat("Base exclusions:", length(base_exclusions), "\n")
cat("Part-level remove annotations:", sum(part_corrections$action == "remove"), "\n")
cat("Unique remove-candidate records:", length(remove_candidates), "\n")
cat("Mixed records retained:", length(intersect(remove_candidates, retain_or_add)), "\n")
cat("Record-level false positives removed:", length(record_level_false_positives), "\n")
cat("Manual additions present in raw export:", length(manual_add_present), "\n")
cat("Manual additions missing from raw export:", length(manual_add_missing), "\n")
cat("Corrected citing records:", length(corrected_uts), "\n\n")

cat("=== Corpus reconciliation ===\n")
print(corpus_reconciliation)
cat("\n")

saveRDS(corrected_uts, file.path(processed_dir, "corrected_uts.rds"))
saveRDS(cit_cr_corrected, file.path(processed_dir, "cit_cr_corrected.rds"))
saveRDS(cit_raw_corrected, file.path(processed_dir, "cit_raw_corrected.rds"))
saveRDS(audit, file.path(processed_dir, "correction_audit.rds"))
saveRDS(record_summary, file.path(processed_dir, "record_correction_summary.rds"))
saveRDS(corpus_reconciliation, file.path(processed_dir, "corpus_reconciliation.rds"))

write.csv(audit, file.path(tables_dir, "correction_audit_trail.csv"), row.names = FALSE)
write.csv(part_summary, file.path(tables_dir, "part_level_correction_summary.csv"), row.names = FALSE)
write.csv(record_summary, file.path(tables_dir, "record_level_correction_summary.csv"), row.names = FALSE)
write.csv(corpus_reconciliation, file.path(tables_dir, "corpus_reconciliation.csv"), row.names = FALSE)
write.csv(cit_raw_corrected, file.path(tables_dir, "corrected_citing_records.csv"), row.names = FALSE)

# Always write this file (even when empty) so a stale copy from an earlier,
# wider-corpus run cannot persist on disk. In the five-Part corpus the three
# Ford 2004 additions are present in the raw export, so this is expected to be
# a header-only (zero-row) file.
write.csv(
  tibble::tibble(UT = manual_add_missing),
  file.path(tables_dir, "manual_additions_missing_from_raw_export.csv"),
  row.names = FALSE
)
if (length(manual_add_missing) == 0) {
  cat("Manual additions missing from raw export: none ",
      "(header-only file written).\n")
}
