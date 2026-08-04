up_cr <- readRDS(file.path(processed_dir, "up_cr.rds"))

up_self_keys <- unique(up_cr$ref_key[
  sapply(up_cr$ref_key, function(k) {
    any(sapply(up_self_patterns, function(p) startsWith(k, p)))
  })
])

# Five-Part scope: the object of study is defined as the five JASIST 2002
# Parts, so the only self-references excluded from the intellectual base are
# the four intra-series patterns in up_self_patterns. Pre-2002 outputs of the
# wider research programme are deliberately NOT excluded: because they are not
# Parts, anything the Parts cite is external by definition. In practice this
# admits two such references, "WILSON T, 1999, EXPLORING THE CONTEXTS OF
# INFORMATION BEHAVIOUR" (cited by Pt2) and "WILSON TD, 1997, UNCERTAINTY
# INFORMAT" (cited by Pt1). Note that Wilson (1999, IP&M) does not arise at
# all: no Part cites it, so it is absent from up_cr and never becomes a
# foundation. Verified against the CR fields of all five Parts, August 2026.

up_self_keys <- unique(up_self_keys)

generic_keys      <- unique(up_cr$ref_key[sapply(up_cr$ref_key, is_generic)])

# Unresolvable keys: no publication year, so they can never match a citing
# paper's reference list. See is_unresolvable() in R/utils.R.
unresolvable_keys <- unique(up_cr$ref_key[sapply(up_cr$ref_key, is_unresolvable)])
unresolvable_keys <- setdiff(unresolvable_keys, c(up_self_keys, generic_keys))

excluded_keys <- unique(c(up_self_keys, generic_keys, unresolvable_keys))

exclusion_summary <- tibble::tibble(
  reason = c("intra-series self-reference", "generic / anonymous",
             "unresolvable (no year)", "total"),
  n = c(length(up_self_keys), length(generic_keys),
        length(unresolvable_keys), length(excluded_keys))
)

cat("Excluded keys:", length(excluded_keys),
    "(self:", length(up_self_keys),
    "| generic:", length(generic_keys),
    "| unresolvable:", length(unresolvable_keys), ")\n")
if (length(unresolvable_keys) > 0) {
  cat("  unresolvable:", paste(unresolvable_keys, collapse = "; "), "\n")
}

up_foundations <- up_cr %>%
  filter(!(ref_key %in% excluded_keys)) %>%
  distinct(ref_key)

cat("External foundations:", nrow(up_foundations), "\n\n")

foundation_in_up <- up_cr %>%
  filter(!(ref_key %in% excluded_keys)) %>%
  group_by(ref_key) %>%
  summarise(n_up_papers = n_distinct(UT), .groups = "drop") %>%
  arrange(desc(n_up_papers))

saveRDS(excluded_keys, file.path(processed_dir, "excluded_keys.rds"))
saveRDS(exclusion_summary, file.path(processed_dir, "exclusion_summary.rds"))
write.csv(exclusion_summary, file.path(tables_dir, "foundation_exclusion_summary.csv"), row.names = FALSE)
saveRDS(up_foundations, file.path(processed_dir, "up_foundations.rds"))
saveRDS(foundation_in_up, file.path(processed_dir, "foundation_in_up.rds"))

write.csv(up_foundations, file.path(tables_dir, "up_foundations.csv"), row.names = FALSE)
write.csv(foundation_in_up, file.path(tables_dir, "foundation_in_up.csv"), row.names = FALSE)
