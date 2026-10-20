# Sensitivity analyses of the coupling results: author overlap, Part-specific
# coupling and per-Part counts.

#' Shared inputs of the sensitivity analyses
#'
#' Verifies that recoupling the validated corpus reproduces the main analysis.
analysis_inputs <- function(corpus, coupling, base, ref, settings) {
  cp <- coupling$coupling
  if (settings$licensed) {
    stopifnot(
      "the coupling corpus should hold 221 records" = nrow(cp) == settings$published_citers,
      "the intellectual base should hold 134 foundations" =
        length(base$keys) == settings$published_base
    )
  }
  stopifnot(n_distinct(base$part_foundations$ref_key) == length(base$keys))

  meta <- corpus$records %>%
    filter(UT %in% cp$UT) %>%
    select(UT, PY, AU, AF, C1, TI, SO, flag_type) %>%
    distinct(UT, .keep_all = TRUE) %>%
    flag_author_overlap(ref)

  recoupled <- couple(coupling$by_record, base$keys, ref)
  stopifnot(identical(recoupled %>% arrange(UT) %>% pull(n_shared),
                      cp %>% arrange(UT) %>% pull(n_shared)))

  list(
    uts = cp$UT,
    by_record = coupling$by_record,
    baseline = recoupled,
    meta = meta,
    part_attr = attribute_parts(corpus$refs %>% filter(UT %in% cp$UT), ref),
    part_foundations = base$part_foundations,
    keys = base$keys
  )
}

#' Author-overlap sensitivity
#'
#' S0 baseline; S1 drops citing papers with any Project author; S2 drops
#' foundations first-authored by the group; S3 does both.
author_overlap_analysis <- function(inp, ref, settings) {
  meta <- inp$meta
  overlap_audit <- meta %>%
    filter(author_overlap) %>%
    transmute(UT, PY, authors_full = AF, affiliation = stringr::str_trunc(C1, 160),
              title = stringr::str_to_sentence(TI), v1_flag = flag_type) %>%
    arrange(PY)
  overlap_uts <- overlap_audit$UT
  group_keys <- inp$keys[stringr::str_detect(inp$keys, ref$foundation_author_regex)]

  scenarios <- list(
    S0 = list(label = "S0 Baseline (v1.0.0)", uts = inp$uts, keys = inp$keys),
    S1 = list(label = "S1 Exclude author-overlap citers",
              uts = setdiff(inp$uts, overlap_uts), keys = inp$keys),
    S2 = list(label = "S2 Exclude group-authored foundations",
              uts = inp$uts, keys = setdiff(inp$keys, group_keys)),
    S3 = list(label = "S3 Exclude both",
              uts = setdiff(inp$uts, overlap_uts), keys = setdiff(inp$keys, group_keys))
  )
  results <- purrr::map(scenarios, function(s) {
    cp <- couple(inp$by_record %>% filter(UT %in% s$uts), s$keys, ref) %>%
      left_join(meta %>% select(UT, PY, author_overlap), by = "UT")
    list(label = s$label, coupling = cp, keys = s$keys)
  })

  links <- function(cp) {
    cp %>% select(UT, shared) %>% tidyr::unnest(shared) %>% count(shared, name = "n_citers")
  }

  scenario_summary <- purrr::map_dfr(results, function(r) {
    summarise_scenario(r$coupling, r$label) %>%
      mutate(n_foundations = length(r$keys),
             n_reproduced = n_distinct(unlist(r$coupling$shared)))
  })

  strand_summary <- purrr::map_dfr(results, function(r) {
    links(r$coupling) %>%
      mutate(strand = strand_of(shared, ref)) %>%
      group_by(strand) %>%
      summarise(reproduced_foundations = n(), citer_links = sum(n_citers),
                mean_citers_per_foundation = round(mean(n_citers), 1), .groups = "drop") %>%
      mutate(scenario = r$label, .before = 1)
  })

  top10 <- purrr::map_dfr(results, function(r) {
    r$coupling %>%
      select(UT, shared) %>%
      tidyr::unnest(shared) %>%
      count(shared, name = "n_citers", sort = TRUE) %>%
      slice_head(n = 10) %>%
      mutate(pct = round(100 * n_citers / nrow(r$coupling), 1),
             strand = strand_of(shared, ref), scenario = r$label, .before = 1) %>%
      rename(ref_key = shared)
  })

  temporal <- purrr::map_dfr(results, function(r) {
    r$coupling %>%
      filter(!is.na(PY)) %>%
      mutate(window = year_window(PY, settings)) %>%
      group_by(window) %>%
      summarise(n_papers = n(), mean_shared = round(mean(n_shared), 2),
                mean_unc = round(mean(n_shared_unc), 2), mean_cs = round(mean(n_shared_cs), 2),
                pct_heirs = round(100 * mean(n_shared >= 3), 1), .groups = "drop") %>%
      mutate(scenario = r$label, .before = 1)
  })

  by_class <- results$S0$coupling %>%
    mutate(class = overlap_class(n_shared)) %>%
    count(author_overlap, class) %>%
    tidyr::pivot_wider(names_from = class, values_from = n, values_fill = 0)

  list(
    results = results,
    tables = list(
      author_overlap_records = overlap_audit,
      foundations_group_authorship = tibble::tibble(ref_key = inp$keys) %>%
        mutate(group_authored = ref_key %in% group_keys, strand = strand_of(ref_key, ref)),
      author_overlap_scenario_summary = scenario_summary,
      author_overlap_strand_summary = strand_summary,
      author_overlap_top10_foundations = top10,
      author_overlap_temporal = temporal,
      author_overlap_by_class = by_class
    ),
    figures = list(R1_author_overlap_temporal = figure(plot_scenario_temporal(temporal), 8, 5.5))
  )
}

summarise_scenario <- function(cp, label) {
  cp %>%
    summarise(
      scenario = label,
      n_citers = n(),
      n_foundations = NA_integer_,
      with_shared = sum(n_shared > 0),
      pct_with_shared = round(100 * mean(n_shared > 0), 1),
      heirs = sum(n_shared >= 3),
      pct_heirs = round(100 * mean(n_shared >= 3), 1),
      intermediate = sum(n_shared %in% 1:2),
      surface = sum(n_shared == 0),
      mean_shared = round(mean(n_shared), 2),
      median_shared = stats::median(n_shared),
      max_shared = max(n_shared),
      mean_shared_unc = round(mean(n_shared_unc), 2),
      mean_shared_cs = round(mean(n_shared_cs), 2)
    )
}

#' Part-specific coupling and the per-Part count bridge
#'
#' For each Part, its own references (and those cited by no other Part) are
#' compared between corpus records that cite the Part and those that do not.
part_specific_analysis <- function(inp, ref) {
  pa <- inp$part_attr
  pf <- inp$part_foundations

  parts_per_record <- pa %>% count(UT, name = "n_parts")
  pattern <- parts_per_record %>%
    count(n_parts, name = "n_records") %>%
    mutate(pct = round(100 * n_records / sum(n_records), 1))

  one_scope <- function(uts_scope, label) {
    purrr::map_dfr(ref$parts$part, function(p) {
      own <- pf %>% filter(part == p) %>% pull(ref_key) %>% unique()
      exclusive <- setdiff(own, pf %>% filter(part != p) %>% pull(ref_key) %>% unique())
      citers <- intersect(pa$UT[pa$part == p], uts_scope)
      rb <- inp$by_record %>%
        filter(UT %in% uts_scope) %>%
        mutate(own = purrr::map_int(refs, ~ length(intersect(.x, own))),
               excl = purrr::map_int(refs, ~ length(intersect(.x, exclusive))),
               cites_p = UT %in% citers)
      a <- rb %>% filter(cites_p)
      b <- rb %>% filter(!cites_p)
      w_own <- suppressWarnings(stats::wilcox.test(a$own, b$own))
      w_excl <- suppressWarnings(stats::wilcox.test(a$excl, b$excl))
      tibble::tibble(
        scenario = label, part = p,
        base_size = length(own), exclusive_base = length(exclusive),
        n_citers = nrow(a), n_noncitters = nrow(b),
        citers_mean_own = round(mean(a$own), 2), noncit_mean_own = round(mean(b$own), 2),
        citers_pct_any_own = round(100 * mean(a$own > 0), 1),
        noncit_pct_any_own = round(100 * mean(b$own > 0), 1),
        p_own = signif(w_own$p.value, 3),
        citers_mean_excl = round(mean(a$excl), 2), noncit_mean_excl = round(mean(b$excl), 2),
        citers_pct_any_excl = round(100 * mean(a$excl > 0), 1),
        noncit_pct_any_excl = round(100 * mean(b$excl > 0), 1),
        p_excl = signif(w_excl$p.value, 3)
      )
    })
  }

  overlap_uts <- inp$meta$UT[inp$meta$author_overlap]
  ps <- bind_rows(one_scope(inp$uts, "S0 Baseline"),
                  one_scope(setdiff(inp$uts, overlap_uts), "S1 Exclude author-overlap citers"))

  strand_by_part <- pa %>%
    inner_join(inp$baseline %>% select(UT, n_shared, n_shared_unc, n_shared_cs), by = "UT") %>%
    group_by(part) %>%
    summarise(n_citers = n(), mean_shared = round(mean(n_shared), 2),
              mean_unc = round(mean(n_shared_unc), 2), mean_cs = round(mean(n_shared_cs), 2),
              pct_any_cs = round(100 * mean(n_shared_cs > 0), 1), .groups = "drop")

  # Validated Part citers split by the self-citation rules, against the
  # external-citer counts of the submitted Table 1.
  t1 <- ref$table1_submitted
  unavailable <- ref$part_corrections %>%
    filter(status %in% c("unavailable", "inaccessible")) %>%
    distinct(UT, part)
  bridge <- pa %>%
    left_join(inp$meta %>% select(UT, AU, flag_type, author_overlap), by = "UT") %>%
    mutate(primary = is_primary_author(AU, part, ref),
           unavailable = paste(UT, part) %in% paste(unavailable$UT, unavailable$part)) %>%
    group_by(part) %>%
    summarise(validated_citers = n(),
              primary_author_selfcit = sum(primary),
              institutional = sum(flag_type == "institutional"),
              any_author_overlap = sum(author_overlap),
              unavailable = sum(unavailable),
              external_primary_rule = sum(!primary & flag_type != "institutional"),
              external_any_rule = sum(!author_overlap & flag_type != "institutional"),
              .groups = "drop") %>%
    mutate(wos_doi_count_ms = t1$wos_doi_matched[match(part, t1$part)],
           table1_external_ms = t1$external_citers[match(part, t1$part)],
           gap_vs_table1 = external_primary_rule - table1_external_ms)

  list(
    tables = list(
      parts_cited_per_record = pattern,
      citers_per_part = pa %>% count(part, name = "n_citers"),
      part_specific_coupling = ps,
      strand_reproduction_by_part_cited = strand_by_part,
      per_part_count_bridge = bridge
    ),
    figures = list(R1_part_specific_coupling = figure(plot_part_specific(ps), 7.5, 4.8))
  )
}
