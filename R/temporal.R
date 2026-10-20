# Temporal analysis with a citation-ageing baseline.
#
# Every foundation predates 2002, so it can only be reproduced among a citing
# paper's pre-2002 references. Per paper:
#   pre-2002 share   = pre-2002 references / dated references   (ageing)
#   foundation share = shared foundations / pre-2002 references (conditional)
# A falling conditional share would indicate displacement of the Project's
# foundations within the older literature still cited; a falling pre-2002
# share alone indicates ordinary ageing.

temporal_analysis <- function(inp, settings) {
  paper_level <- inp$baseline %>%
    left_join(inp$meta %>% select(UT, PY, author_overlap), by = "UT") %>%
    mutate(ref_years = purrr::map(refs, ref_year),
           n_dated = purrr::map_int(ref_years, ~ sum(!is.na(.x))),
           n_pre2002 = purrr::map_int(ref_years, ~ sum(.x <= 2001, na.rm = TRUE)),
           median_ref_age = purrr::map2_dbl(ref_years, PY, ~ stats::median(.y - .x, na.rm = TRUE)),
           window = year_window(PY, settings))

  annual <- paper_level %>%
    group_by(PY) %>%
    summarise(n_papers = n(), mean_shared = round(mean(n_shared), 2),
              mean_unc = round(mean(n_shared_unc), 2), mean_cs = round(mean(n_shared_cs), 2),
              .groups = "drop")

  windows <- bind_rows(
    window_table(paper_level, "S0 Baseline", settings),
    window_table(paper_level %>% filter(!author_overlap), "S1 Exclude author-overlap citers", settings)
  )
  trends <- bind_rows(
    trend_tests(paper_level, "S0 Baseline"),
    trend_tests(paper_level %>% filter(!author_overlap), "S1 Exclude author-overlap citers")
  )

  list(
    paper_level = paper_level %>% select(-refs, -shared, -ref_years),
    tables = list(
      temporal_annual_counts = annual,
      temporal_windows_with_baseline = windows,
      temporal_trend_tests = trends
    ),
    figures = list(R1_temporal_baseline = figure(plot_temporal_baseline(windows), 8, 5))
  )
}

window_table <- function(df, label, settings) {
  R <- settings$n_boot
  seed <- settings$seed
  df %>%
    group_by(window) %>%
    group_modify(function(d, k) {
      pre <- pooled_ratio_ci(d$n_pre2002, d$n_dated, R, seed)
      fnd <- pooled_ratio_ci(d$n_shared, d$n_pre2002, R, seed)
      unc <- pooled_ratio_ci(d$n_shared_unc, d$n_pre2002, R, seed)
      cs <- pooled_ratio_ci(d$n_shared_cs, d$n_pre2002, R, seed)
      ms <- boot_mean_ci(d$n_shared, R, seed)
      pct <- function(x) round(100 * x, 1)
      tibble::tibble(
        n_papers = nrow(d),
        mean_refs = round(mean(d$n_total_refs), 1),
        median_ref_age = stats::median(d$median_ref_age, na.rm = TRUE),
        mean_shared = round(mean(d$n_shared), 2),
        mean_shared_lo = round(ms[1], 2), mean_shared_hi = round(ms[2], 2),
        pct_pre2002 = pct(pre[1]), pct_pre2002_lo = pct(pre[2]), pct_pre2002_hi = pct(pre[3]),
        found_per100pre = pct(fnd[1]), found_lo = pct(fnd[2]), found_hi = pct(fnd[3]),
        unc_per100pre = pct(unc[1]), unc_lo = pct(unc[2]), unc_hi = pct(unc[3]),
        cs_per100pre = pct(cs[1]), cs_lo = pct(cs[2]), cs_hi = pct(cs[3]),
        papers_any_cs = sum(d$n_shared_cs > 0)
      )
    }) %>%
    ungroup() %>%
    mutate(scenario = label, .before = 1)
}

#' Paper-level trend tests, effects per five years
#'
#' Quasi-binomial GLMs for shares, quasi-Poisson for the count of shared
#' foundations; year is continuous.
trend_tests <- function(df, label) {
  d <- df %>% filter(n_dated > 0)
  d2 <- d %>% filter(n_pre2002 > 0)
  fit_share <- function(k, n, data) {
    stats::glm(cbind(data[[k]], data[[n]] - data[[k]]) ~ PY, family = stats::quasibinomial,
               data = data)
  }
  models <- list(
    list(m = stats::glm(n_shared ~ PY, family = stats::quasipoisson, data = d),
         what = "Shared foundations (count)", n = nrow(d), effect = "rate ratio"),
    list(m = fit_share("n_pre2002", "n_dated", d),
         what = "Pre-2002 share of all references (ageing)", n = nrow(d), effect = "odds ratio"),
    list(m = fit_share("n_shared", "n_pre2002", d2),
         what = "Foundations among pre-2002 references", n = nrow(d2), effect = "odds ratio"),
    list(m = fit_share("n_shared_unc", "n_pre2002", d2),
         what = "  Uncertainty strand among pre-2002 refs", n = nrow(d2), effect = "odds ratio"),
    list(m = fit_share("n_shared_cs", "n_pre2002", d2),
         what = "  Cognitive-styles strand among pre-2002 refs", n = nrow(d2), effect = "odds ratio")
  )
  purrr::map_dfr(models, function(x) {
    co <- summary(x$m)$coefficients["PY", ]
    ci <- co[1] + c(-1.96, 1.96) * co[2]
    tibble::tibble(scenario = label, outcome = x$what, n_papers = x$n, effect = x$effect,
                   per_5_years = round(exp(5 * co[1]), 3),
                   lo = round(exp(5 * ci[1]), 3), hi = round(exp(5 * ci[2]), 3),
                   p = signif(co[4], 3))
  })
}
