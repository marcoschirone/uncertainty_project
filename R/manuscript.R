# The numbers reported in the article, recomputed from a run.
#
# manuscript_facts() recomputes every quantity the article reports, formatted
# at the article's precision; ids follow the number-audit register.
# compare_with_manuscript() joins them with the values printed in the article
# (data/private/manuscript_values.csv, kept out of the repository until
# publication) and flags any difference.

manuscript_facts <- function(wos, corpus, base, overlap, coupling, described, inputs,
                             author_overlap, part_specific, temporal, survivorship,
                             venues, claims, ref, settings) {
  out <- list()
  add <- function(id, quantity, value) {
    out[[length(out) + 1]] <<- tibble::tibble(id = id, quantity = quantity,
                                              fresh = as.character(value))
  }
  f1 <- function(x) sprintf("%.1f", x)
  f2 <- function(x) sprintf("%.2f", x)
  join <- function(x) paste(x, collapse = " / ")
  pct_of <- function(k, d) f1(100 * k / d)
  n_pct <- function(k, d) sprintf("%d (%s%%)", k, pct_of(k, d))
  value_range <- function(x) if (length(x)) paste(min(x), max(x), sep = "-") else "none"
  round_half_up <- function(x) floor(x + 0.5)

  cp <- coupling$coupling
  n <- nrow(cp)
  pa <- inputs$part_attr
  parts <- ref$parts$part
  per_part <- function(x) join(x[parts])
  count_parts <- function(p) table(factor(p, parts))
  rs <- corpus$record_summary
  pc <- ref$part_corrections

  # Corpus ------------------------------------------------------------------
  add("N001", "Records citing at least one Part (DOI-restricted)", nrow(wos$citing_records))
  add("N002", "Records in the citing export", wos$n_retrieved)
  add("N003", "Base exclusions (intra-project + erratum)", rs$base_exclusions)
  add("N005", "Part-level removal annotations / unique records",
      join(c(rs$part_level_remove_annotations, rs$unique_remove_candidate_records)))
  add("N006", "Mixed records retained / record-level false positives",
      join(c(rs$mixed_records_retained, rs$record_level_false_positives_removed)))
  add("N007", "Validated citing corpus", n)
  add("N008", "Part-level additions / records added", join(c(sum(pc$action == "add"), 0)))
  add("N009", "Papers not obtainable",
      n_distinct(pc$UT[pc$status %in% c("unavailable", "inaccessible")]))
  add("N010", "Retrieval date of citing records",
      paste(sort(unique(wos$citing_records$DA)), collapse = ", "))
  add("N011", "Export date of the Parts' reference lists",
      paste(sort(unique(wos$parts_records$DA)), collapse = ", "))
  add("N012", "Publication-year span", paste(range(cp$PY), collapse = "-"))

  # Per-Part counts -----------------------------------------------------------
  doi_matched <- attribute_parts(wos$citing_refs %>% filter(!UT %in% ref$base_exclusions$UT),
                                 ref, pc[0, ])
  doi_n <- count_parts(doi_matched$part)
  validated_n <- count_parts(pa$part)
  fp <- pc %>%
    filter(action == "remove", stringr::str_detect(status, "^false_positive")) %>%
    distinct(UT, part)
  no_codes <- tibble::tibble(UT = character(), part = character(), `function` = character(),
                             contrastive = character(), misattribution = character())
  links <- coding_links(inputs, list(primary = no_codes), ref)
  self_rate <- links %>%
    group_by(part) %>%
    summarise(r = mean(primary_self & !institutional), .groups = "drop")
  parts_per_record <- table(factor(count(pa, UT)$n, 1:5))

  add("N014", "WoS DOI-matched citers per Part, after exclusions", per_part(doi_n))
  add("N015", "Sum of per-Part matches / records",
      join(c(sum(doi_n), n_distinct(doi_matched$UT))))
  add("N016", "Validated citers per Part", per_part(validated_n))
  add("N017", "External citers per Part, primary-author rule, full text available",
      per_part(count_parts(links$part[links$external_primary])))
  add("N017b", "External citers per Part, any-author rule, full text available",
      per_part(count_parts(links$part[links$external_any])))
  add("N018", "False-positive rate per Part (removals / DOI matches, %)",
      per_part(stats::setNames(f1(100 * count_parts(fp$part) / doi_n), parts)))
  add("N019", "Ford (2004) records added for Part 4", sum(pc$action == "add" & pc$part == "P4"))
  add("N020", "Records citing exactly one Part", n_pct(parts_per_record[["1"]], n))
  add("N021", "Records citing all five Parts", parts_per_record[["5"]])
  add("N021b", "Records citing 1 / 2 / 3 / 4 / 5 Parts", join(as.integer(parts_per_record)))
  add("N022", "Part with the highest primary-author self-citation rate",
      self_rate$part[which.max(self_rate$r)])

  # Descriptives -------------------------------------------------------------
  annual <- temporal$tables$temporal_annual_counts
  by_year <- sort(table(cp$PY), decreasing = TRUE)
  add("N023", "Document types", join(as.integer(sort(table(cp$DT), decreasing = TRUE))))
  add("N024", "Peak years",
      join(sprintf("%d (%s)", as.integer(by_year[1:3]), names(by_year)[1:3])))
  add("N025", "Papers per five-year window", join(as.integer(table(year_window(cp$PY, settings)))))
  add("N026", "Annual counts range; years with fewer than five papers",
      sprintf("%d-%d; %d", min(annual$n_papers), max(annual$n_papers), sum(annual$n_papers < 5)))

  # Intellectual base -----------------------------------------------------------
  exclusions <- base$tables$foundation_exclusion_summary$n
  unresolvable_keys <- base$excluded_keys[is_unresolvable(base$excluded_keys) &
                                            !is_generic(base$excluded_keys)]
  unresolved <- corpus$refs %>% filter(UT %in% cp$UT, ref_key %in% unresolvable_keys)
  ft <- described$foundation_table
  m <- overlap$matrix
  label <- stats::setNames(ref$parts$label, parts)

  add("N027", "Foundational references", length(base$keys))
  add("N028", "Unresolvable (in-press) keys excluded", exclusions[3])
  add("N028b", "Excluded keys: self / generic / unresolvable", join(exclusions[1:3]))
  add("N029", "Citing papers / references linked by the unresolvable key",
      join(c(n_distinct(unresolved$UT), nrow(unresolved))))
  add("N030", "Foundations reproduced / not reproduced",
      join(c(nrow(ft), length(base$keys) - nrow(ft))))
  add("N031", "Foundations per Part (P1-P5)", join(diag(m)[label]))
  add("N032", "Shared references P4-P3 / P4-P2 / P1-P5",
      join(c(m[label["P4"], label["P3"]], m[label["P4"], label["P2"]], m[label["P1"], label["P5"]])))

  # Coupling -------------------------------------------------------------------
  k <- settings$heir_threshold
  n_high <- sum(cp$n_shared >= k)
  n_limited <- sum(cp$n_shared >= 1 & cp$n_shared < k)
  n_none <- sum(cp$n_shared == 0)
  thresholds <- vapply(1:5, function(t) f1(100 * mean(cp$n_shared >= t)), character(1))
  ng <- claims$tables$named_groups_coupling_class
  top6 <- utils::head(ft, 6)
  top20 <- utils::head(ft, 20)

  add("N033", "Papers sharing at least one foundation", n_pct(n - n_none, n))
  add("N034", "Papers sharing none", n_pct(n_none, n))
  add("N035", "Mean / median / maximum shared",
      join(c(f2(mean(cp$n_shared)), stats::median(cp$n_shared), max(cp$n_shared))))
  add("N036", "High / limited / no overlap",
      join(c(n_pct(n_high, n), n_pct(n_limited, n), n_pct(n_none, n))))
  add("N037", "Share with high overlap at thresholds 2 and 4 (%)", join(thresholds[c(2, 4)]))
  add("N037b", "Share at thresholds 1-5 (%)", join(thresholds))
  add("N038", "Named papers at thresholds 1-5",
      join(vapply(1:5, function(t) sum(ng$n_shared >= t), integer(1))))
  add("N039", "Top six foundations: papers (%)",
      join(sprintf("%d (%s%%)", top6$n_citers, f1(top6$pct_citers))))
  add("N039b", "Top six foundations: keys", join(top6$ref_key))
  add("N041", "Top 20 by strand (U / CS / Other); foundations tied at rank 20",
      sprintf("%d / %d / %d; %d", sum(top20$strand == "Uncertainty"),
              sum(top20$strand == "Cognitive styles"), sum(top20$strand == "Other"),
              sum(ft$n_citers == ft$n_citers[min(20, nrow(ft))])))

  # Author overlap -------------------------------------------------------------
  sc <- author_overlap$tables$author_overlap_scenario_summary
  ao_records <- author_overlap$tables$author_overlap_records
  ao_class <- author_overlap$tables$author_overlap_by_class
  group_found <- author_overlap$tables$foundations_group_authorship
  by_authorship <- survivorship$tables$foundation_survivorship %>%
    filter(dimension == "group_authored")
  early <- author_overlap$tables$author_overlap_temporal %>% filter(window == "2002-2006")

  add("N043", "Citing papers with any author overlap", n_pct(nrow(ao_records), n))
  add("N044", "Author-overlap papers flagged self / institutional / external",
      join(c(sum(ao_records$v1_flag == "self_citation"), sum(ao_records$v1_flag == "institutional"),
             sum(ao_records$v1_flag == "external"))))
  add("N046", "Author-overlap papers with high overlap",
      sum(ao_class$intellectual_heir[ao_class$author_overlap]))
  add("N047", "S1: papers / at least one shared (%) / high overlap (%)",
      join(c(sc$n_citers[2], f1(sc$pct_with_shared[2]), f1(sc$pct_heirs[2]))))
  add("N048", "Group-authored foundations",
      n_pct(sum(group_found$group_authored), nrow(group_found)))
  add("N049", "Share of foundation-citer links that are group-authored (%)",
      sprintf("%.0f", 100 * by_authorship$citer_links[by_authorship$level == "Group-authored"] /
                sum(by_authorship$citer_links)))
  add("N050", "S2 and S3: at least one shared / high overlap (%)",
      join(f1(c(sc$pct_with_shared[3], sc$pct_heirs[3], sc$pct_with_shared[4], sc$pct_heirs[4]))))
  add("N051", "Mean overlap 2002-2006, baseline / S1",
      join(f2(early$mean_shared[!grepl("^S[23]", early$scenario)])))

  # Strands --------------------------------------------------------------------
  ss <- described$tables$strand_summary
  strand <- function(s) ss[ss$strand == s, ]
  surv <- survivorship$tables$foundation_survivorship %>% filter(dimension == "strand")
  survival <- function(s) {
    r <- surv[surv$level == s, ]
    sprintf("%d of %d (%s%%)", r$reproduced, r$n_foundations, f1(r$rate))
  }
  sbp <- part_specific$tables$strand_reproduction_by_part_cited
  others <- sbp$pct_any_cs[sbp$part != "P4"]

  add("N052", "Uncertainty: reproduced / links / mean",
      join(c(strand("Uncertainty")$n_foundations, strand("Uncertainty")$total_citer_links,
             f1(strand("Uncertainty")$mean_citers))))
  add("N053", "Cognitive styles: reproduced / links / mean",
      join(c(strand("Cognitive styles")$n_foundations, strand("Cognitive styles")$total_citer_links,
             f1(strand("Cognitive styles")$mean_citers))))
  add("N054", "Other: reproduced / links",
      join(c(strand("Other")$n_foundations, strand("Other")$total_citer_links)))
  add("N055", "Reproduced foundations in the two strands",
      strand("Uncertainty")$n_foundations + strand("Cognitive styles")$n_foundations)
  add("N056", "All foundations reproduced: CS / Uncertainty / Other",
      join(c(survival("Cognitive styles"), survival("Uncertainty"), survival("Other"))))
  add("N057", "Fisher p (strand reproduction) / Wilcoxon p (links)",
      join(sprintf("%.2f", survivorship$tables$strand_contrast_all_foundations$p)))
  add("N058", "Any cognitive-styles foundation: P4 citers / range for other Parts (%)",
      sprintf("%s / %s-%s", f1(sbp$pct_any_cs[sbp$part == "P4"]), f1(min(others)), f1(max(others))))

  # Part-specific coupling -------------------------------------------------------
  ps <- part_specific$tables$part_specific_coupling
  ps0 <- ps %>% filter(scenario == "S0 Baseline")
  ps1 <- ps %>% filter(scenario != "S0 Baseline")
  significant <- function(d) join(d$part[d$p_own < 0.005])
  p4 <- ps0[ps0$part == "P4", ]

  add("N059", "Parts whose citers reproduce own references (p < 0.005)", significant(ps0))
  add("N061", "P4: exclusive references; any reproduced citers vs others (%); means",
      sprintf("%d; %s vs %s; %s vs %s", p4$exclusive_base, f1(p4$citers_pct_any_excl),
              f1(p4$noncit_pct_any_excl), f2(p4$citers_mean_excl), f2(p4$noncit_mean_excl)))
  add("N062", "Same Parts significant after excluding author-overlap papers", significant(ps1))

  # Temporal -----------------------------------------------------------------------
  tt <- temporal$tables$temporal_trend_tests
  trend <- function(outcome, scenario = "S0 Baseline") {
    tt[tt$scenario == scenario & trimws(tt$outcome) == outcome, ]
  }
  rr <- trend("Shared foundations (count)")
  age <- trend("Pre-2002 share of all references (ageing)")
  fnd <- trend("Foundations among pre-2002 references")
  unc <- trend("Uncertainty strand among pre-2002 refs")
  cs <- trend("Cognitive-styles strand among pre-2002 refs")
  fnd1 <- trend("Foundations among pre-2002 references", "S1 Exclude author-overlap citers")
  wt <- temporal$tables$temporal_windows_with_baseline %>% filter(scenario == "S0 Baseline")
  last <- nrow(wt)

  add("N063", "Rate ratio of shared foundations per 5 years (95% CI)",
      sprintf("%.2f (%.2f-%.2f)", rr$per_5_years, rr$lo, rr$hi))
  add("N064", "Pre-2002 share first to last window (%); OR per 5 years",
      sprintf("%s -> %s; %.2f", f1(wt$pct_pre2002[1]), f1(wt$pct_pre2002[last]), age$per_5_years))
  add("N065", "Foundations among pre-2002 references, OR per 5 years (95% CI), p",
      sprintf("%.2f (%.2f-%.2f), p = %.2f", fnd$per_5_years, fnd$lo, fnd$hi, fnd$p))
  add("N066", "Strands and S1: OR per 5 years (p)",
      sprintf("U %.2f (%.2f); CS %.2f (%.2f); S1 %.2f (%.2f)", unc$per_5_years, unc$p,
              cs$per_5_years, cs$p, fnd1$per_5_years, fnd1$p))
  add("N067", "Papers with any CS foundation, last two windows; CS OR (95% CI)",
      sprintf("%d of %d / %d of %d; %.2f (%.2f-%.2f)", wt$papers_any_cs[last - 1],
              wt$n_papers[last - 1], wt$papers_any_cs[last], wt$n_papers[last],
              cs$per_5_years, cs$lo, cs$hi))

  # Submitted Table 1 (counts reconstructed from its percentages) ------------------
  t1 <- ref$table1_submitted
  t1m <- as.matrix(t1[c("perfunctory", "reviewed", "supported", "applied")])
  chi <- suppressWarnings(stats::chisq.test(t1m))
  pw <- claims$tables$table1_pairwise_tests
  pair_p <- function(pair) sprintf("%.3f", pw$chisq_p[pw$pair == pair])
  cross <- pw %>% filter(pair %in% c("P1-P3", "P1-P5", "P2-P3", "P2-P5", "P3-P4", "P4-P5"))
  supported <- function(p) c(t1m[t1$part == p, "supported"], t1$external_citers[t1$part == p])
  s3 <- supported("P3")
  s5 <- supported("P5")

  add("N071", "Submitted Table 1: chi-squared, df, V; expected counts below 5",
      sprintf("%.2f, %d, %.2f; %d of %d", chi$statistic, chi$parameter, cramers_v(t1m),
              sum(chi$expected < 5), length(chi$expected)))
  add("N072", "Submitted Table 1 pairwise p: P1-P2 / P1-P4 / P2-P4 / P3-P5 / P1-P5",
      join(vapply(c("P1-P2", "P1-P4", "P2-P4", "P3-P5", "P1-P5"), pair_p, character(1))))
  add("N073", "Cross-cluster pairs significant at 0.005 / with p < 0.001",
      join(c(sum(cross$chisq_p < 0.005), sum(cross$chisq_p < 0.001))))
  add("N075", "Supported, P3 vs P5, Fisher p",
      sprintf("%.3f", stats::fisher.test(matrix(c(s3[1], s3[2] - s3[1], s5[1], s5[2] - s5[1]),
                                                2))$p.value))

  # Named groups and authors -----------------------------------------------------
  nvr <- claims$tables$named_groups_vs_rest
  shared_of <- function(g) join(sort(ng$n_shared[ng$group == g], decreasing = TRUE))
  authors <- inputs$meta$AU

  add("N082", "Papers by the six named groups", nrow(ng))
  add("N083", "Shared foundations: McGill / Strathclyde / UNSW / Chen (range)",
      sprintf("%s / %s / %s / %s", shared_of("McGill"), shared_of("Strathclyde"),
              shared_of("UNSW"), value_range(ng$n_shared[ng$group == "Chen"])))
  add("N084", "Named papers with high overlap; others (%); odds ratio; p",
      sprintf("%d of %d; %s%%; %.1f; %s", nvr$named_heirs, nvr$named_n,
              pct_of(nvr$other_heirs, nvr$other_n), nvr$odds_ratio,
              if (nvr$p < 0.001) "< 0.001" else sprintf("%.3f", nvr$p)))
  add("N085", "Named papers sharing only one foundation", join(ng$first_author[ng$n_shared == 1]))
  add("N086", "Corpus papers co-authored by S. Y. Chen",
      sum(stringr::str_detect(authors, "(^|;)CHEN SY(;|$)")))
  add("N087", "Corpus papers with Kostagiolas as author",
      sum(stringr::str_detect(authors, "KOSTAGIOLAS")))

  # Venues and disciplines ---------------------------------------------------------
  vd <- venues$tables$venue_discipline_check
  vp <- vd[vd$scope %in% parts, ]
  corpus_row <- vd[vd$scope == "Corpus", ]
  ir <- cp$UT[stringr::str_detect(cp$SO, "^INFORMATION RESEARCH")]
  p2 <- unique(pa$UT[pa$part == "P2"])
  ir_p2 <- length(intersect(ir, p2))
  ir_other <- length(setdiff(ir, p2))
  ir_test <- stats::fisher.test(matrix(c(ir_p2, length(p2) - ir_p2,
                                         ir_other, n - length(p2) - ir_other), 2))
  p2_row <- vp[vp$scope == "P2", ]
  p4_row <- vp[vp$scope == "P4", ]

  add("N088", "Share of each Part's citers in four core journals (range, %)",
      sprintf("%d-%d", round_half_up(min(vp$core4_pct)), round_half_up(max(vp$core4_pct))))
  add("N089", "Leading core venue for every Part",
      paste(unique(sub(" \\(.*", "", vp$leading_core_venue_merged)), collapse = "; "))
  add("N090", "Information Research: P2 citers vs others; Fisher p",
      sprintf("%d of %d vs %d of %d; %.2f", ir_p2, length(p2), ir_other, n - length(p2),
              ir_test$p.value))
  add("N091", "Citing papers in Information Research", length(ir))
  add("N093", "Computer Science Research Area share (%)", f1(corpus_row$cs_area_pct))
  add("N094", "Computing-only venues (%)", f1(corpus_row$cs_only_pct))
  add("N095", "Health: P2 citers; maximum share among other Parts (%)",
      sprintf("%d of %d (%s%%); %s", p2_row$health_n, p2_row$n, f1(p2_row$health_pct),
              f1(max(vp$health_pct[vp$scope != "P2"]))))
  add("N096", "LIS share of each Part's citers (range, %)",
      sprintf("%s-%s", f1(min(vp$lis_pct)), f1(max(vp$lis_pct))))
  add("N097", "Part 4 citers in education", sprintf("%d of %d", p4_row$education_n, p4_row$n))
  add("N098", "Core-journal share, P4 / P5 (%)",
      join(f1(c(p4_row$core4_pct, vp$core4_pct[vp$scope == "P5"]))))
  add("N099", "Papers reproducing Wilson (1999) / citers of Part 2 / Part 4",
      join(c(ft$n_citers[ft$ref_key == "WILSON TD, 1999, J DOC"], validated_n[["P2"]],
             validated_n[["P4"]])))
  add("N100", "R version of this run", paste(R.version$major, R.version$minor, sep = "."))
  add("C001", "Records removed by close reading, of those retrieved",
      join(c(rs$record_level_false_positives_removed, rs$raw_wos_records)))

  dplyr::bind_rows(out)
}

#' Join the fresh values with the values printed in the article
compare_with_manuscript <- function(facts, values_file) {
  if (is.na(values_file) || !file.exists(values_file)) return(NULL)
  printed <- read_reference_csv(values_file)
  norm <- function(x) gsub("\\s+", " ", trimws(as.character(x)))
  status <- function(value, judgement, fresh) {
    case_when(is.na(value) ~ "not reported",
              norm(value) == norm(fresh) ~ "match",
              !is.na(judgement) ~ judgement,
              TRUE ~ "differs")
  }
  facts %>%
    left_join(printed %>% select(-any_of("quantity")), by = "id") %>%
    mutate(revised_status = status(revised, revised_judgement, fresh),
           submitted_status = status(submitted, submitted_judgement, fresh)) %>%
    select(id, quantity, fresh, revised, revised_status, submitted, submitted_status,
           any_of(c("location", "note")))
}
