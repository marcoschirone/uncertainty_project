# The intellectual base: the external references of the five Parts.

#' Build the intellectual base
#'
#' Excludes intra-series self-references, generic or anonymous references, and
#' keys without a publication year. Earlier outputs of the wider research
#' programme are not Parts, so references to them count as external.
build_intellectual_base <- function(parts_refs, ref) {
  keys <- unique(parts_refs$ref_key)
  self_keys <- keys[vapply(keys, function(k) any(startsWith(k, ref$self_patterns)), logical(1))]
  generic_keys <- keys[is_generic(keys)]
  unresolvable_keys <- setdiff(keys[is_unresolvable(keys)], c(self_keys, generic_keys))
  excluded <- unique(c(self_keys, generic_keys, unresolvable_keys))

  kept <- parts_refs %>% filter(!(ref_key %in% excluded))
  foundations <- kept %>% distinct(ref_key)
  foundation_in_up <- kept %>%
    group_by(ref_key) %>%
    summarise(n_up_papers = n_distinct(UT), .groups = "drop") %>%
    arrange(desc(n_up_papers))
  part_foundations <- kept %>%
    distinct(UT, ref_key) %>%
    inner_join(ref$parts %>% select(part, UT), by = "UT") %>%
    select(part, ref_key)

  exclusion_summary <- tibble::tibble(
    reason = c("intra-series self-reference", "generic / anonymous",
               "unresolvable (no year)", "total"),
    n = c(length(self_keys), length(generic_keys), length(unresolvable_keys), length(excluded))
  )

  list(
    foundations = foundations,
    keys = foundations$ref_key,
    excluded_keys = excluded,
    part_foundations = part_foundations,
    foundation_in_up = foundation_in_up,
    tables = list(
      foundation_exclusion_summary = exclusion_summary,
      up_foundations = foundations,
      foundation_in_up = foundation_in_up
    )
  )
}

#' Foundations shared between each pair of Parts
part_overlap <- function(parts_refs, base, ref) {
  by_part <- parts_refs %>%
    filter(!(ref_key %in% base$excluded_keys)) %>%
    group_by(UT) %>%
    summarise(refs = list(unique(ref_key)), .groups = "drop")

  m <- outer(seq_len(nrow(by_part)), seq_len(nrow(by_part)),
             Vectorize(function(i, j) length(intersect(by_part$refs[[i]], by_part$refs[[j]]))))
  storage.mode(m) <- "integer"
  labels <- ref$parts$label[match(by_part$UT, ref$parts$UT)]
  if (anyNA(labels) || nrow(m) != nrow(ref$parts)) {
    stop("The overlap matrix must cover the five named Parts.", call. = FALSE)
  }
  dimnames(m) <- list(labels, labels)

  list(
    matrix = m,
    tables = list(overlap_matrix = m),
    figures = list(overlap_heatmap = figure(plot_overlap_heatmap(m), 9, 8))
  )
}
