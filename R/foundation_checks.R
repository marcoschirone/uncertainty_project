# Survivorship of foundations, venues and disciplines, and checks of specific
# claims in the manuscript.

#' Reach of every foundation, reproduced or not
survivorship_analysis <- function(inp, ref) {
  reach <- inp$baseline %>%
    select(UT, shared) %>%
    tidyr::unnest(shared) %>%
    count(shared, name = "n_citers") %>%
    rename(ref_key = shared)
  origin <- inp$part_foundations %>%
    group_by(ref_key) %>%
    summarise(cited_by_parts = paste(sort(unique(part)), collapse = "+"),
              n_parts = n_distinct(part), .groups = "drop")

  found_all <- tibble::tibble(ref_key = inp$keys) %>%
    left_join(reach, by = "ref_key") %>%
    left_join(origin, by = "ref_key") %>%
    mutate(
      n_citers = coalesce(n_citers, 0L),
      reproduced = n_citers > 0,
      strand = strand_of(ref_key, ref),
      group_authored = stringr::str_detect(ref_key, ref$foundation_author_regex),
      year = ref_year(ref_key),
      period = cut(year, c(-Inf, 1979, 1989, 1995, 2001),
                   labels = c("pre-1980", "1980-1989", "1990-1995", "1996-2001")),
      source_type = ifelse(
        stringr::str_detect(ref_key, "THESIS|P ASIS|PROC|CONF|ANN M|MEET|INT C|INF SEEK C|MIRA"),
        "Proceedings/thesis", "Journal/book/other")
    ) %>%
    arrange(desc(n_citers))

  rate_table <- function(df, by) {
    df %>%
      group_by(.data[[by]]) %>%
      summarise(n_foundations = n(), reproduced = sum(reproduced),
                citer_links = sum(n_citers), .groups = "drop") %>%
      rowwise() %>%
      mutate(rate = round(100 * reproduced / n_foundations, 1),
             lo = round(100 * wilson_ci(reproduced, n_foundations)[1], 1),
             hi = round(100 * wilson_ci(reproduced, n_foundations)[2], 1),
             links_per_foundation = round(citer_links / n_foundations, 2)) %>%
      ungroup() %>%
      rename(level = 1) %>%
      mutate(dimension = by, .before = 1)
  }
  survivorship <- bind_rows(
    rate_table(found_all, "strand"),
    rate_table(found_all %>% mutate(part_of_origin = ifelse(n_parts > 1, "Several Parts",
                                                            cited_by_parts)), "part_of_origin"),
    rate_table(found_all %>% mutate(period = as.character(period)), "period"),
    rate_table(found_all, "source_type"),
    rate_table(found_all %>% mutate(group_authored = ifelse(group_authored, "Group-authored",
                                                            "Other authors")), "group_authored")
  )

  u <- found_all %>% filter(strand == "Uncertainty")
  cs <- found_all %>% filter(strand == "Cognitive styles")
  ft <- stats::fisher.test(matrix(c(sum(u$reproduced), sum(!u$reproduced),
                                    sum(cs$reproduced), sum(!cs$reproduced)), 2))
  wt <- suppressWarnings(stats::wilcox.test(u$n_citers, cs$n_citers))
  strand_test <- tibble::tibble(
    comparison = c("Reproduction rate, uncertainty vs cognitive styles (Fisher)",
                   "Citer-links per foundation incl. zeros (Wilcoxon)"),
    uncertainty = c(sprintf("%d/%d", sum(u$reproduced), nrow(u)),
                    sprintf("mean %.2f, median %.0f", mean(u$n_citers), median(u$n_citers))),
    cognitive_styles = c(sprintf("%d/%d", sum(cs$reproduced), nrow(cs)),
                         sprintf("mean %.2f, median %.0f", mean(cs$n_citers), median(cs$n_citers))),
    estimate = c(round(unname(ft$estimate), 2), NA),
    p = c(signif(ft$p.value, 3), signif(wt$p.value, 3))
  )

  list(
    tables = list(
      foundations_all_134 = found_all,
      foundation_survivorship = survivorship,
      strand_contrast_all_foundations = strand_test
    ),
    figures = list(R1_survivorship = figure(plot_survivorship(found_all), 7.5, 5.5))
  )
}

jasist_pattern <- paste("AMERICAN SOCIETY FOR INFORMATION SCIENCE",
                        "ASSOCIATION FOR INFORMATION SCIENCE AND TECHNOLOGY", sep = "|")
ipm_pattern <- "^INFORMATION PROCESSING (&|AND) MANAGEMENT"
health_pattern <- paste("HEALTH", "MEDIC", "NURSING", "PHARMAC", "PSYCHIATRY", "PEDIATRIC",
                        "ONCOLOGY", "SURGERY", "NEUROSCIENCE", sep = "|")

core_venue <- function(so) {
  case_when(
    stringr::str_detect(so, jasist_pattern) ~ "JASIST/JASIS&T",
    stringr::str_detect(so, "^INFORMATION RESEARCH") ~ "Information Research",
    stringr::str_detect(so, "^JOURNAL OF DOCUMENTATION") ~ "Journal of Documentation",
    stringr::str_detect(so, ipm_pattern) ~ "IP&M",
    TRUE ~ "Other"
  )
}

#' Venues (SO) and WoS Research Areas (SC), per Part and for the corpus
#'
#' Research Areas are journal-level and may be multiple.
venue_analysis <- function(corpus, inp, ref) {
  records <- corpus$records
  if (!"SC" %in% names(records)) records$SC <- NA_character_
  rec <- records %>%
    filter(UT %in% inp$uts) %>%
    distinct(UT, .keep_all = TRUE) %>%
    transmute(UT, SO, SC = coalesce(SC, ""),
              venue = core_venue(SO),
              cs = stringr::str_detect(SC, "COMPUTER SCIENCE"),
              lis = stringr::str_detect(SC, "INFORMATION SCIENCE & LIBRARY SCIENCE"),
              cs_only = cs & !lis,
              health = stringr::str_detect(SC, health_pattern),
              education = stringr::str_detect(SC, "EDUCATION"))

  summarise_scope <- function(d, label) {
    d %>% summarise(
      scope = label, n = n(),
      core4_n = sum(venue != "Other"), core4_pct = round(100 * mean(venue != "Other"), 1),
      leading_venue = names(sort(table(SO), decreasing = TRUE))[1],
      leading_venue_n = max(table(SO)),
      cs_area_pct = round(100 * mean(cs), 1), cs_only_pct = round(100 * mean(cs_only), 1),
      lis_pct = round(100 * mean(lis), 1),
      health_n = sum(health), health_pct = round(100 * mean(health), 1),
      education_n = sum(education), education_pct = round(100 * mean(education), 1)
    )
  }
  scopes <- c(list(Corpus = rec),
              purrr::set_names(purrr::map(ref$parts$part, function(p) {
                rec %>% filter(UT %in% inp$part_attr$UT[inp$part_attr$part == p])
              }), ref$parts$part))
  vd <- purrr::imap_dfr(scopes, summarise_scope)
  vd$leading_core_venue_merged <- purrr::map_chr(scopes, function(d) {
    t <- sort(table(d$venue[d$venue != "Other"]), decreasing = TRUE)
    paste0(names(t)[1], " (", t[1], ")")
  }) %>% unname()

  list(tables = list(venue_discipline_check = vd))
}

#' Checks of named groups, repeat authors and the submitted Table 1 tests
claims_analysis <- function(inp, ref) {
  cp <- inp$baseline %>%
    left_join(inp$meta %>% select(UT, PY, AU, TI), by = "UT") %>%
    mutate(first_au = stringr::str_trim(stringr::str_extract(AU, "^[^;]+")),
           class = overlap_class(n_shared))

  named_hits <- purrr::pmap_dfr(ref$named_papers, function(group, first_author, year) {
    cp %>%
      filter(PY == year, stringr::str_detect(first_au, stringr::fixed(first_author))) %>%
      transmute(group, UT, PY, first_author = first_au, all_authors = AU,
                title = stringr::str_trunc(stringr::str_to_sentence(TI), 80), n_shared, class)
  }) %>%
    distinct(UT, .keep_all = TRUE) %>%
    # Mampadi 2011: the group's paper is the one co-authored with S. Y. Chen.
    filter(!(first_author == "MAMPADI F" & !stringr::str_detect(all_authors, "CHEN SY")))

  others <- cp %>% filter(!UT %in% named_hits$UT)
  tab <- matrix(c(sum(named_hits$class == "intellectual_heir"),
                  sum(named_hits$class != "intellectual_heir"),
                  sum(others$class == "intellectual_heir"),
                  sum(others$class != "intellectual_heir")), 2)
  ft <- stats::fisher.test(tab)
  named_vs_rest <- tibble::tibble(
    named_heirs = tab[1, 1], named_n = sum(tab[, 1]),
    other_heirs = tab[1, 2], other_n = sum(tab[, 2]),
    odds_ratio = round(unname(ft$estimate), 2),
    ci_lo = round(ft$conf.int[1], 2), ci_hi = round(ft$conf.int[2], 2),
    p = signif(ft$p.value, 3)
  )

  authors <- inp$meta %>%
    select(UT, AU) %>%
    mutate(au = stringr::str_split(AU, ";")) %>%
    tidyr::unnest(au) %>%
    mutate(au = stringr::str_trim(au)) %>%
    distinct(UT, au) %>%
    count(au, name = "n_papers", sort = TRUE)

  # Submitted Table 1: counts reconstructed from the printed percentages.
  t1 <- ref$table1_submitted
  m <- as.matrix(t1[c("perfunctory", "reviewed", "supported", "applied")])
  dimnames(m) <- list(t1$part, c("Perfunctory", "Reviewed", "Supported", "Applied"))
  pairs <- utils::combn(nrow(m), 2)
  pairwise <- purrr::map_dfr(seq_len(ncol(pairs)), function(j) {
    s <- m[pairs[, j], ]
    s <- s[, colSums(s) > 0, drop = FALSE]
    cs <- suppressWarnings(stats::chisq.test(s))
    tibble::tibble(pair = paste(rownames(s), collapse = "-"),
                   chisq_p = signif(cs$p.value, 3),
                   fisher_p = signif(stats::fisher.test(s)$p.value, 3),
                   cramers_v = round(sqrt(unname(cs$statistic) / (sum(s) * (min(dim(s)) - 1))), 2))
  }) %>%
    mutate(sig_bonferroni_005 = chisq_p < 0.005, below_0.001 = chisq_p < 0.001)

  list(
    cp = cp,
    tables = list(
      named_groups_coupling_class = named_hits,
      named_groups_vs_rest = named_vs_rest,
      repeat_authors = authors %>% filter(n_papers >= 3),
      table1_pairwise_tests = pairwise
    )
  )
}
