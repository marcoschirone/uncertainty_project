up_cr <- readRDS(file.path(processed_dir, "up_cr.rds"))
coupling <- readRDS(file.path(processed_dir, "coupling.rds"))
foundation_in_up <- readRDS(file.path(processed_dir, "foundation_in_up.rds"))

# Denominator for foundation adoption percentages = the bibliographic-coupling
# corpus (Part-citers, n = 221), i.e. the same set over which n_citers is
# counted. Using the full 302-record corrected corpus here would understate
# every percentage and disagree with the manuscript (e.g. Wilson 1999 would
# read 20.2% instead of 27.6%).
n_part_citers <- nrow(coupling)

fc <- coupling %>%
  filter(has_shared) %>%
  select(UT, shared) %>%
  unnest(shared) %>%
  count(shared, sort = TRUE, name = "n_citers") %>%
  rename(ref_key = shared)

fc <- fc %>%
  left_join(foundation_in_up, by = "ref_key") %>%
  mutate(
    pct_citers = safe_pct(n_citers, n_part_citers, 1),
    strand = case_when(
      ref_key %in% uncertainty_keys ~ "Uncertainty",
      ref_key %in% cognitive_styles_keys ~ "Cognitive styles",
      TRUE ~ "Other"
    )
  )

fl <- up_cr %>%
  select(ref_key, CR) %>%
  distinct() %>%
  group_by(ref_key) %>%
  slice(1) %>%
  ungroup()

foundation_table <- fc %>%
  left_join(fl, by = "ref_key") %>%
  select(ref_key, CR, n_citers, pct_citers, n_up_papers, strand) %>%
  arrange(desc(n_citers))

cat("=== Top 30 foundations ===\n")
print(head(foundation_table, 30), width = 120)
cat("\n")

write.csv(foundation_table, file.path(tables_dir, "foundation_counts.csv"), row.names = FALSE)

strand_summary <- foundation_table %>%
  group_by(strand) %>%
  summarise(
    n_foundations = n(),
    total_citer_links = sum(n_citers),
    mean_citers = round(mean(n_citers), 1),
    median_citers = median(n_citers),
    max_citers = max(n_citers),
    .groups = "drop"
  ) %>%
  arrange(desc(total_citer_links))

cat("=== Strand comparison ===\n")
print(strand_summary)
cat("\n")

write.csv(strand_summary, file.path(tables_dir, "strand_summary.csv"), row.names = FALSE)

p_str <- foundation_table %>%
  filter(strand != "Other") %>%
  group_by(strand) %>%
  slice_head(n = 10) %>%
  ungroup() %>%
  mutate(ref_key = factor(ref_key, levels = rev(ref_key))) %>%
  ggplot(aes(x = n_citers, y = ref_key, fill = strand)) +
  geom_col() +
  geom_text(aes(label = n_citers), hjust = -0.1, size = 3) +
  scale_fill_manual(values = c("Uncertainty" = "#29BEFD", "Cognitive styles" = "#F757C1")) +
  labs(title = "Foundation adoption by strand", x = "Citing papers", y = NULL, fill = "Strand") +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(figures_dir, "strand_comparison.png"), p_str, width = 11.5, height = 8, dpi = 300)

k <- 3
heirs <- coupling %>%
  filter(n_shared >= k) %>%
  select(UT, TI, PY, SO, flag_type, n_shared, n_shared_unc, n_shared_cs, n_total_refs, jaccard) %>%
  arrange(desc(n_shared), desc(jaccard))

cat("=== Heirs (n_shared >=", k, ") ===\n", " Total:", nrow(heirs), "\n")
print(head(heirs, 20), width = 130)
cat("\n")

write.csv(heirs, file.path(tables_dir, "intellectual_heirs.csv"), row.names = FALSE)

surface <- coupling %>%
  filter(n_shared == 0) %>%
  select(UT, TI, PY, SO, flag_type, n_total_refs) %>%
  arrange(desc(PY))

cat("Surface citers:", nrow(surface), "\n")
write.csv(surface, file.path(tables_dir, "surface_citers.csv"), row.names = FALSE)

# ------------------------------------------------------------------
# Three-way coupling classification (manuscript terminology):
#   intellectual_heir : n_shared >= 3
#   intermediate      : n_shared 1-2
#   surface_citer     : n_shared == 0
# Denominator is the Part-citer / coupling corpus (n = 221).
# ------------------------------------------------------------------
intermediate <- coupling %>%
  filter(n_shared >= 1 & n_shared < k) %>%
  select(UT, TI, PY, SO, flag_type, n_shared, n_shared_unc, n_shared_cs, n_total_refs, jaccard) %>%
  arrange(desc(n_shared), desc(jaccard))

write.csv(intermediate, file.path(tables_dir, "intermediate_citers.csv"), row.names = FALSE)

coupling <- coupling %>%
  mutate(coupling_class = dplyr::case_when(
    n_shared >= k ~ "intellectual_heir",
    n_shared >= 1 ~ "intermediate",
    TRUE          ~ "surface_citer"
  ))

coupling_classification <- coupling %>%
  count(coupling_class, name = "n") %>%
  mutate(
    pct = safe_pct(n, sum(n), 1),
    coupling_class = factor(coupling_class,
                            levels = c("intellectual_heir", "intermediate", "surface_citer"))
  ) %>%
  arrange(coupling_class)

cat("=== Coupling classification (n =", nrow(coupling), ") ===\n")
print(coupling_classification)
cat("\n")

write.csv(coupling_classification, file.path(tables_dir, "coupling_classification_summary.csv"), row.names = FALSE)

temporal <- coupling %>%
  filter(!is.na(PY)) %>%
  group_by(PY) %>%
  summarise(
    n_papers = n(),
    n_with_shared = sum(has_shared),
    mean_shared = mean(n_shared),
    mean_shared_unc = mean(n_shared_unc),
    mean_shared_cs = mean(n_shared_cs),
    .groups = "drop"
  ) %>%
  mutate(prop_shared = n_with_shared / n_papers)

write.csv(temporal, file.path(tables_dir, "temporal_summary.csv"), row.names = FALSE)

p_tmp <- ggplot(temporal, aes(x = PY, y = mean_shared)) +
  geom_col(fill = "#FFB000", width = 0.7) +
  geom_smooth(method = "loess", se = TRUE, colour = "#F43256", linewidth = 0.8) +
  labs(title = "Foundation sharing over time", x = "Publication year", y = "Mean shared foundations")

ggsave(file.path(figures_dir, "temporal_mean_shared.png"), p_tmp, width = 8, height = 5, dpi = 300)

tl <- temporal %>%
  select(PY, mean_shared_unc, mean_shared_cs) %>%
  pivot_longer(cols = c(mean_shared_unc, mean_shared_cs), names_to = "strand", values_to = "mean_shared") %>%
  mutate(strand = ifelse(strand == "mean_shared_unc", "Uncertainty", "Cognitive styles"))

p_ts <- ggplot(tl, aes(x = PY, y = mean_shared, colour = strand)) +
  geom_point(alpha = 0.5, size = 1.5) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 0.8) +
  scale_colour_manual(values = c("Uncertainty" = "#29BEFD", "Cognitive styles" = "#F757C1")) +
  labs(title = "Foundation sharing by strand", x = "Publication year", y = "Mean shared foundations", colour = "Strand")

ggsave(file.path(figures_dir, "temporal_strand.png"), p_ts, width = 8, height = 5, dpi = 300)

p_dist <- ggplot(coupling, aes(x = n_shared)) +
  geom_histogram(binwidth = 1, fill = "#29BEFD", colour = "white", linewidth = 0.3) +
  labs(title = "Distribution of shared foundations", x = "Shared foundational references", y = "Citing papers")

ggsave(file.path(figures_dir, "shared_foundations_distribution.png"), p_dist, width = 8, height = 5, dpi = 300)

p_top <- foundation_table %>%
  slice_head(n = 20) %>%
  mutate(ref_key = factor(ref_key, levels = rev(ref_key))) %>%
  ggplot(aes(x = n_citers, y = ref_key, fill = strand)) +
  geom_col() +
  geom_text(aes(label = n_citers), hjust = -0.1, size = 3) +
  scale_fill_manual(values = c("Uncertainty" = "#29BEFD", "Cognitive styles" = "#F757C1", "Other" = "#777777")) +
  labs(title = "Top 20 shared foundational works", x = "Citing papers", y = NULL, fill = "Strand") +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(figures_dir, "top_foundations.png"), p_top, width = 11, height = 7, dpi = 300)

saveRDS(foundation_table, file.path(processed_dir, "foundation_table.rds"))
saveRDS(strand_summary, file.path(processed_dir, "strand_summary.rds"))
saveRDS(heirs, file.path(processed_dir, "heirs.rds"))
saveRDS(surface, file.path(processed_dir, "surface.rds"))
saveRDS(temporal, file.path(processed_dir, "temporal.rds"))
