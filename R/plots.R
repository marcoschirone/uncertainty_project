# Figures. Colours follow the published figures.

strand_colours <- c("Uncertainty" = "#29BEFD", "Cognitive styles" = "#F757C1", "Other" = "#777777")
strand_colours_dark <- c("Uncertainty" = "#1F77B4", "Cognitive styles" = "#D6278A")

theme_up <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 12),
      plot.subtitle = ggplot2::element_text(colour = "grey40", size = 10)
    )
}

plot_overlap_heatmap <- function(m) {
  labels <- rownames(m)
  ol <- as.data.frame(as.table(m))
  names(ol) <- c("Paper1", "Paper2", "Shared")
  ol$Paper1 <- factor(ol$Paper1, levels = rev(labels))
  ol$Paper2 <- factor(ol$Paper2, levels = labels)
  ggplot(ol, aes(x = Paper2, y = Paper1, fill = Shared)) +
    theme_up() +
    geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = Shared), size = 3.5) +
    scale_fill_gradient(low = "#FFF3E0", high = "#F46821", name = "Shared\nrefs") +
    labs(title = "Reference overlap between UP papers", x = NULL, y = NULL) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 9)) +
    coord_fixed()
}

plot_strand_comparison <- function(foundation_table) {
  foundation_table %>%
    filter(strand != "Other") %>%
    group_by(strand) %>%
    slice_head(n = 10) %>%
    ungroup() %>%
    mutate(ref_key = factor(ref_key, levels = rev(ref_key))) %>%
    ggplot(aes(x = n_citers, y = ref_key, fill = strand)) +
    theme_up() +
    geom_col() +
    geom_text(aes(label = n_citers), hjust = -0.1, size = 3) +
    scale_fill_manual(values = strand_colours[1:2]) +
    labs(title = "Foundation adoption by strand", x = "Citing papers", y = NULL, fill = "Strand") +
    theme(axis.text.y = element_text(size = 8))
}

plot_temporal_mean <- function(temporal) {
  ggplot(temporal, aes(x = PY, y = mean_shared)) +
    theme_up() +
    geom_col(fill = "#FFB000", width = 0.7) +
    geom_smooth(method = "loess", formula = y ~ x, se = TRUE, colour = "#F43256", linewidth = 0.8) +
    labs(title = "Foundation sharing over time", x = "Publication year",
         y = "Mean shared foundations")
}

plot_temporal_strand <- function(temporal) {
  tl <- temporal %>%
    select(PY, mean_shared_unc, mean_shared_cs) %>%
    tidyr::pivot_longer(c(mean_shared_unc, mean_shared_cs), names_to = "strand",
                        values_to = "mean_shared") %>%
    mutate(strand = ifelse(strand == "mean_shared_unc", "Uncertainty", "Cognitive styles"))
  ggplot(tl, aes(x = PY, y = mean_shared, colour = strand)) +
    theme_up() +
    geom_point(alpha = 0.5, size = 1.5) +
    geom_smooth(method = "loess", formula = y ~ x, se = TRUE, linewidth = 0.8) +
    scale_colour_manual(values = strand_colours[1:2]) +
    labs(title = "Foundation sharing by strand", x = "Publication year",
         y = "Mean shared foundations", colour = "Strand")
}

plot_shared_distribution <- function(cp) {
  ggplot(cp, aes(x = n_shared)) +
    theme_up() +
    geom_histogram(binwidth = 1, fill = "#29BEFD", colour = "white", linewidth = 0.3) +
    labs(title = "Distribution of shared foundations", x = "Shared foundational references",
         y = "Citing papers")
}

plot_top_foundations <- function(foundation_table, n = 20) {
  foundation_table %>%
    slice_head(n = n) %>%
    mutate(ref_key = factor(ref_key, levels = rev(ref_key))) %>%
    ggplot(aes(x = n_citers, y = ref_key, fill = strand)) +
    theme_up() +
    geom_col() +
    geom_text(aes(label = n_citers), hjust = -0.1, size = 3) +
    scale_fill_manual(values = strand_colours) +
    labs(title = paste("Top", n, "shared foundational works"), x = "Citing papers", y = NULL,
         fill = "Strand") +
    theme(axis.text.y = element_text(size = 8))
}

plot_scenario_temporal <- function(temporal_by_scenario) {
  ggplot(temporal_by_scenario, aes(window, mean_shared, group = scenario, colour = scenario)) +
    theme_up() +
    geom_line(linewidth = 0.8) +
    geom_point(size = 2) +
    scale_colour_manual(values = c("#1F77B4", "#D62728", "#2CA02C", "#7F7F7F")) +
    labs(title = "Mean shared foundations by period under the four scenarios",
         x = NULL, y = "Mean shared foundations per citing paper", colour = NULL) +
    theme(legend.position = "bottom", legend.direction = "vertical")
}

plot_part_specific <- function(ps) {
  d <- ps %>%
    filter(scenario == "S0 Baseline") %>%
    select(part, citers_mean_excl, noncit_mean_excl) %>%
    tidyr::pivot_longer(-part, names_to = "group", values_to = "mean") %>%
    mutate(group = ifelse(group == "citers_mean_excl", "Cite this Part", "Do not cite this Part"))
  ggplot(d, aes(part, mean, fill = group)) +
    theme_up() +
    geom_col(position = position_dodge(0.75), width = 0.7) +
    scale_fill_manual(values = c("Cite this Part" = "#1F77B4", "Do not cite this Part" = "#BDBDBD")) +
    labs(title = "Reproduction of each Part's exclusive references",
         x = NULL, y = "Mean exclusive references shared", fill = NULL) +
    theme(legend.position = "bottom")
}

plot_temporal_baseline <- function(wt) {
  fd <- wt %>%
    filter(scenario == "S0 Baseline") %>%
    select(window, n_papers, unc_per100pre, unc_lo, unc_hi, cs_per100pre, cs_lo, cs_hi) %>%
    tidyr::pivot_longer(c(unc_per100pre, cs_per100pre), names_to = "strand", values_to = "est") %>%
    mutate(lo = ifelse(strand == "unc_per100pre", unc_lo, cs_lo),
           hi = ifelse(strand == "unc_per100pre", unc_hi, cs_hi),
           strand = ifelse(strand == "unc_per100pre", "Uncertainty", "Cognitive styles"),
           xlab = paste0(window, "\n(n = ", n_papers, ")"))
  ggplot(fd, aes(xlab, est, colour = strand, group = strand)) +
    theme_up() +
    geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(0.3)) +
    geom_line(position = position_dodge(0.3)) +
    scale_colour_manual(values = strand_colours_dark) +
    labs(title = "Project foundations per 100 pre-2002 references cited",
         subtitle = "Pooled ratio per five-year window, 95% bootstrap CI",
         x = NULL, y = "Foundations per 100 pre-2002 references", colour = NULL) +
    theme(legend.position = "bottom")
}

plot_survivorship <- function(found_all) {
  found_all %>%
    filter(strand != "Other") %>%
    mutate(strand = factor(strand, c("Uncertainty", "Cognitive styles"))) %>%
    ggplot(aes(n_citers, fill = strand)) +
    theme_up() +
    geom_histogram(binwidth = 2, boundary = 0, colour = "white") +
    facet_wrap(~strand, ncol = 1) +
    scale_fill_manual(values = strand_colours_dark, guide = "none") +
    labs(title = "Reach of every foundation, including those never reproduced",
         x = "Citing papers reproducing the foundation", y = "Foundations")
}
