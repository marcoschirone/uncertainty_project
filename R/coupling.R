# Bibliographic coupling of each citing record to the intellectual base
# (Kessler 1963): n_shared is the number of foundations a record also cites.

#' Reference set of each citing record
refs_by_record <- function(refs) {
  refs %>%
    group_by(UT) %>%
    summarise(n_total_refs = n_distinct(ref_key), refs = list(unique(ref_key)),
              .groups = "drop")
}

#' Couple records to a foundation set
couple <- function(by_record, foundation_keys, ref) {
  by_record %>%
    mutate(
      shared = purrr::map(refs, ~ intersect(.x, foundation_keys)),
      n_shared = purrr::map_int(shared, length),
      n_shared_unc = purrr::map_int(shared, ~ length(intersect(.x, ref$uncertainty_keys))),
      n_shared_cs = purrr::map_int(shared, ~ length(intersect(.x, ref$cs_keys)))
    )
}

overlap_class <- function(n_shared, k = 3L) {
  case_when(n_shared >= k ~ "intellectual_heir",
            n_shared >= 1 ~ "intermediate",
            TRUE ~ "surface_citer")
}

#' Couple the validated corpus to the intellectual base
couple_corpus <- function(corpus, base, ref) {
  part_pattern <- paste(ref$parts$doi, collapse = "|")
  records <- corpus$records %>%
    filter(stringr::str_detect(CR, stringr::regex(part_pattern, ignore_case = TRUE)))
  refs <- corpus$refs %>% filter(UT %in% unique(records$UT))
  by_record <- refs_by_record(refs)

  coupling <- couple(by_record, base$keys, ref) %>%
    mutate(
      has_shared = n_shared > 0,
      jaccard = n_shared / purrr::map_int(refs, ~ length(union(.x, base$keys)))
    ) %>%
    relocate(has_shared, jaccard, .after = n_shared) %>%
    left_join(records %>% select(UT, TI, PY, SO, DT, TC, flag_type) %>% distinct(), by = "UT")

  summary <- coupling %>%
    summarise(
      n_citers = n(),
      n_with_shared = sum(has_shared),
      prop_with_shared = round(n_with_shared / n_citers, 4),
      mean_shared = round(mean(n_shared), 2),
      median_shared = median(n_shared),
      max_shared = max(n_shared),
      mean_jaccard = round(mean(jaccard, na.rm = TRUE), 4),
      median_jaccard = round(median(jaccard, na.rm = TRUE), 4),
      mean_shared_unc = round(mean(n_shared_unc), 2),
      mean_shared_cs = round(mean(n_shared_cs), 2)
    )

  list(coupling = coupling, by_record = by_record,
       tables = list(coupling_summary = as.data.frame(summary)))
}

#' Foundation counts, strands, coupling classes and the temporal profile
describe_coupling <- function(coupling, parts_refs, base, ref, settings) {
  cp <- coupling$coupling
  k <- settings$heir_threshold

  first_cr <- parts_refs %>%
    select(ref_key, CR) %>%
    distinct() %>%
    group_by(ref_key) %>%
    slice(1) %>%
    ungroup()
  foundation_table <- cp %>%
    filter(has_shared) %>%
    select(UT, shared) %>%
    tidyr::unnest(shared) %>%
    count(shared, sort = TRUE, name = "n_citers") %>%
    rename(ref_key = shared) %>%
    left_join(base$foundation_in_up, by = "ref_key") %>%
    mutate(pct_citers = safe_pct(n_citers, nrow(cp), 1),
           strand = strand_of(ref_key, ref)) %>%
    left_join(first_cr, by = "ref_key") %>%
    select(ref_key, CR, n_citers, pct_citers, n_up_papers, strand) %>%
    arrange(desc(n_citers))

  strand_summary <- foundation_table %>%
    group_by(strand) %>%
    summarise(n_foundations = n(), total_citer_links = sum(n_citers),
              mean_citers = round(mean(n_citers), 1), median_citers = median(n_citers),
              max_citers = max(n_citers), .groups = "drop") %>%
    arrange(desc(total_citer_links))

  class_cols <- c("UT", "TI", "PY", "SO", "flag_type", "n_shared", "n_shared_unc",
                  "n_shared_cs", "n_total_refs", "jaccard")
  heirs <- cp %>%
    filter(n_shared >= k) %>%
    select(all_of(class_cols)) %>%
    arrange(desc(n_shared), desc(jaccard))
  intermediate <- cp %>%
    filter(n_shared >= 1 & n_shared < k) %>%
    select(all_of(class_cols)) %>%
    arrange(desc(n_shared), desc(jaccard))
  surface <- cp %>%
    filter(n_shared == 0) %>%
    select(UT, TI, PY, SO, flag_type, n_total_refs) %>%
    arrange(desc(PY))

  classification <- cp %>%
    mutate(coupling_class = overlap_class(n_shared, k)) %>%
    count(coupling_class, name = "n") %>%
    mutate(pct = safe_pct(n, sum(n), 1),
           coupling_class = factor(coupling_class,
                                   levels = c("intellectual_heir", "intermediate", "surface_citer"))) %>%
    arrange(coupling_class)

  temporal <- cp %>%
    filter(!is.na(PY)) %>%
    group_by(PY) %>%
    summarise(n_papers = n(), n_with_shared = sum(has_shared), mean_shared = mean(n_shared),
              mean_shared_unc = mean(n_shared_unc), mean_shared_cs = mean(n_shared_cs),
              .groups = "drop") %>%
    mutate(prop_shared = n_with_shared / n_papers)

  list(
    foundation_table = foundation_table,
    tables = list(
      foundation_counts = foundation_table,
      strand_summary = strand_summary,
      intellectual_heirs = heirs,
      surface_citers = surface,
      intermediate_citers = intermediate,
      coupling_classification_summary = classification,
      temporal_summary = temporal
    ),
    figures = list(
      strand_comparison = figure(plot_strand_comparison(foundation_table), 11.5, 8),
      temporal_mean_shared = figure(plot_temporal_mean(temporal), 8, 5),
      temporal_strand = figure(plot_temporal_strand(temporal), 8, 5),
      shared_foundations_distribution = figure(plot_shared_distribution(cp), 8, 5),
      top_foundations = figure(plot_top_foundations(foundation_table), 11, 7)
    )
  )
}
