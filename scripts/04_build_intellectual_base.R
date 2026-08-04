up_cr <- readRDS(file.path(processed_dir, "up_cr.rds"))

up_self_keys <- unique(up_cr$ref_key[
  sapply(up_cr$ref_key, function(k) {
    any(sapply(up_self_patterns, function(p) startsWith(k, p)))
  })
])

# Five-Part scope: the only self-references excluded from the intellectual
# base are the four JASIST 2002 intra-series patterns in up_self_patterns
# (Pt1 Spink is matched by the Pt2/Pt3 Spink pattern family; Ellis, Wilson and
# Ford are matched directly). The three pre-2002 precursors are deliberately
# NOT excluded, so Wilson (1999, IP&M) is free to enter as an external
# foundation. The earlier grep lines for the 1998/1999 "EXPLORING THE
# CONTEXTS" conference paper are gone: that record is no longer in up_cr.

up_self_keys <- unique(up_self_keys)

generic_keys <- unique(up_cr$ref_key[sapply(up_cr$ref_key, is_generic)])
excluded_keys <- unique(c(up_self_keys, generic_keys))

cat("Excluded keys:", length(excluded_keys), "\n")

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
saveRDS(up_foundations, file.path(processed_dir, "up_foundations.rds"))
saveRDS(foundation_in_up, file.path(processed_dir, "foundation_in_up.rds"))

write.csv(up_foundations, file.path(tables_dir, "up_foundations.csv"), row.names = FALSE)
write.csv(foundation_in_up, file.path(tables_dir, "foundation_in_up.csv"), row.names = FALSE)
