# Corpus validation: base exclusions, the close-reading correction layer, and
# Part attribution of every citing record.

#' Apply base exclusions and the correction layer
#'
#' Part-level corrections are not record-level removals: a record that is a
#' false positive for one Part but a confirmed citer of another stays in the
#' corpus. A record is removed only when every correction on it is a removal.
apply_corrections <- function(wos, ref) {
  pc <- ref$part_corrections
  raw_uts <- unique(wos$citing_refs$UT)

  base_defined <- ref$base_exclusions$UT
  base_exclusions <- intersect(base_defined, raw_uts)

  remove_candidates <- unique(pc$UT[pc$action == "remove"])
  retain_or_add <- unique(pc$UT[pc$action %in% c("retain", "add")])
  record_fp <- setdiff(remove_candidates, retain_or_add)

  manual_add <- unique(pc$UT[pc$action == "add"])
  manual_add_present <- intersect(manual_add, raw_uts)
  manual_add_missing <- setdiff(manual_add, raw_uts)

  corrected_uts <- union(setdiff(raw_uts, unique(c(base_exclusions, record_fp))),
                         manual_add_present)

  expected <- length(raw_uts) - length(base_exclusions) - length(record_fp)
  if (expected != length(corrected_uts)) {
    stop("Reconciliation mismatch: expected ", expected, " records, found ",
         length(corrected_uts), ".", call. = FALSE)
  }

  refs <- wos$citing_refs[wos$citing_refs$UT %in% corrected_uts, , drop = FALSE]
  records <- wos$citing_records %>%
    filter(UT %in% corrected_uts) %>%
    left_join(ref$record_flags, by = "UT") %>%
    mutate(flag_type = tidyr::replace_na(flag_type, "external"))

  audit <- pc %>%
    mutate(
      in_raw_export = UT %in% raw_uts,
      part_level_remove = action == "remove",
      record_removed_from_forward_corpus = UT %in% record_fp,
      record_retained_in_forward_corpus = UT %in% corrected_uts,
      note_on_record_handling = case_when(
        UT %in% base_exclusions ~ "removed_base_exclusion",
        UT %in% record_fp ~ "removed_record_level_false_positive",
        action %in% c("retain", "add") & UT %in% corrected_uts ~ "retained_or_added",
        action == "add" & !(UT %in% raw_uts) ~ "add_requested_but_missing_from_raw_export",
        TRUE ~ "part_level_only"
      )
    )

  part_summary <- pc %>%
    group_by(part, action, status) %>%
    summarise(n = n(), .groups = "drop") %>%
    arrange(part, action, status)

  record_summary <- tibble::tibble(
    raw_wos_records = length(raw_uts),
    base_exclusions = length(base_exclusions),
    part_level_remove_annotations = sum(pc$action == "remove"),
    unique_remove_candidate_records = length(remove_candidates),
    mixed_records_retained = length(intersect(remove_candidates, retain_or_add)),
    record_level_false_positives_removed = length(record_fp),
    manual_additions_present_in_raw_export = length(manual_add_present),
    manual_additions_missing_from_raw_export = length(manual_add_missing),
    corrected_records = length(corrected_uts)
  )

  reconciliation <- tibble::tibble(
    step = c("Raw WoS citing records",
             "Base exclusions (intra-project cross-citations + correction/erratum)",
             "Record-level false positives removed",
             "Manual additions present in raw export",
             "Manual additions missing from raw export",
             "Final corrected corpus"),
    count = c(length(raw_uts), length(base_exclusions), length(record_fp),
              length(manual_add_present), length(manual_add_missing), length(corrected_uts)),
    effect_on_unique_record_count = c(length(raw_uts), -length(base_exclusions),
                                      -length(record_fp), 0, 0, length(corrected_uts)),
    note = c("Initial WoS-derived citing-record set",
             "Removed before coupling analysis",
             "Confirmed false-positive records with no retained/add citation",
             "Already present as records; corrects Part-level attribution",
             "Not included automatically; requires supplemental record metadata",
             "Corpus used for corrected-corpus coupling analysis")
  )

  list(
    uts = corrected_uts,
    refs = refs,
    records = records,
    base_exclusions = base_exclusions,
    record_summary = record_summary,
    tables = list(
      correction_audit_trail = audit,
      part_level_correction_summary = part_summary,
      record_level_correction_summary = record_summary,
      corpus_reconciliation = reconciliation,
      corrected_citing_records = records,
      manual_additions_missing_from_raw_export = tibble::tibble(UT = manual_add_missing)
    )
  )
}

#' Attribute citing records to Parts
#'
#' A record cites a Part when its references contain the Part's DOI, or the
#' 2002 volume-53 start page. Validated corrections are then applied: a
#' removal drops the attribution, an addition creates it.
attribute_parts <- function(cr, ref, corrections = ref$part_corrections) {
  cr_up <- toupper(cr$CR)
  is_2002_v53 <- stringr::str_detect(cr_up, "2002") & stringr::str_detect(cr_up, "V53")
  hits <- purrr::map_dfr(seq_len(nrow(ref$parts)), function(i) {
    by_doi <- stringr::str_detect(cr_up, stringr::fixed(ref$parts$doi[i]))
    by_page <- is_2002_v53 &
      stringr::str_detect(cr_up, paste0(ref$parts$start_page[i], "($|[^0-9])"))
    tibble::tibble(UT = cr$UT[by_doi | by_page], part = ref$parts$part[i])
  }) %>% distinct()

  removes <- corrections %>% filter(action == "remove") %>% distinct(UT, part)
  adds <- corrections %>% filter(action == "add") %>% distinct(UT, part)

  hits %>%
    anti_join(removes, by = c("UT", "part")) %>%
    bind_rows(adds) %>%
    distinct() %>%
    arrange(UT, part)
}

#' The retrieved records with their validation outcome
#'
#' Accession number, DOI and year of every record citing a Part, whether it
#' is retained, the Parts it validly cites, and the reason for any removal.
#' Sufficient to rebuild the corpus from a Web of Science subscription.
corpus_record_list <- function(wos, corpus, part_attr, ref) {
  pc <- ref$part_corrections
  removal_reason <- pc %>%
    filter(action == "remove", UT %in% setdiff(wos$citing_records$UT, corpus$uts)) %>%
    group_by(UT) %>%
    summarise(reason = paste0("Record-level false positive: ",
                              paste(part, note, sep = ": ", collapse = "; ")),
              .groups = "drop")
  cited <- part_attr %>%
    group_by(UT) %>%
    summarise(parts_cited_validated = paste(part, collapse = ";"), .groups = "drop")

  wos$citing_records %>%
    transmute(UT, DOI = DI, PY) %>%
    distinct(UT, .keep_all = TRUE) %>%
    mutate(status = case_when(UT %in% corpus$base_exclusions ~ "Base exclusion",
                              UT %in% corpus$uts ~ "Retained",
                              TRUE ~ "Removed")) %>%
    left_join(cited, by = "UT") %>%
    left_join(removal_reason, by = "UT") %>%
    left_join(ref$base_exclusions %>% rename(base_reason = reason), by = "UT") %>%
    mutate(reason = coalesce(reason, base_reason)) %>%
    select(-base_reason) %>%
    arrange(desc(PY), UT)
}

flag_author_overlap <- function(records, ref) {
  records %>%
    mutate(author_overlap = stringr::str_detect(coalesce(AU, ""), ref$author_regex))
}

#' Does a record's author list contain the primary author of a Part?
is_primary_author <- function(au, part, ref) {
  pattern <- ref$parts$primary_author[match(part, ref$parts$part)]
  purrr::map2_lgl(coalesce(au, ""), pattern,
                  ~ stringr::str_detect(.x, paste0("(^|;)\\s*(", .y, ")\\s*(;|$)")))
}
