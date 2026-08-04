up_cr <- readRDS(file.path(processed_dir, "up_cr.rds"))
excluded_keys <- readRDS(file.path(processed_dir, "excluded_keys.rds"))

up_paper_refs <- up_cr %>%
  filter(!(ref_key %in% excluded_keys)) %>%
  group_by(UT) %>%
  summarise(refs = list(unique(ref_key)), .groups = "drop")

uts <- up_paper_refs$UT
n <- length(uts)
overlap_mat <- matrix(0L, n, n)

for (i in seq_len(n)) {
  for (j in seq_len(n)) {
    overlap_mat[i, j] <- length(intersect(
      up_paper_refs$refs[[i]],
      up_paper_refs$refs[[j]]
    ))
  }
}

labels_vec <- up_short_labels[uts]
labels_vec[is.na(labels_vec)] <- substr(uts[is.na(labels_vec)], 1, 20)

# Five-Part scope: the overlap matrix must be 5x5 with every Part named.
if (n != 5L || any(is.na(up_short_labels[uts]))) {
  warning(
    "Overlap matrix is ", n, "x", n,
    " and/or contains unlabelled UTs; expected a 5x5 matrix over the five ",
    "named Parts. Check up_short_labels and the UP source filter."
  )
}

rownames(overlap_mat) <- labels_vec
colnames(overlap_mat) <- labels_vec

print(overlap_mat)

write.csv(overlap_mat, file.path(tables_dir, "overlap_matrix.csv"))

ol <- as.data.frame(as.table(overlap_mat))
names(ol) <- c("Paper1", "Paper2", "Shared")

ol$Paper1 <- factor(ol$Paper1, levels = rev(labels_vec))
ol$Paper2 <- factor(ol$Paper2, levels = labels_vec)

p_hm <- ggplot(ol, aes(x = Paper2, y = Paper1, fill = Shared)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = Shared), size = 3.5) +
  scale_fill_gradient(low = "#FFF3E0", high = "#F46821", name = "Shared\nrefs") +
  labs(title = "Reference overlap between UP papers", x = NULL, y = NULL) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 9)) +
  coord_fixed()

ggsave(file.path(figures_dir, "overlap_heatmap.png"), p_hm, width = 9, height = 8, dpi = 300)

saveRDS(overlap_mat, file.path(processed_dir, "overlap_matrix.rds"))
