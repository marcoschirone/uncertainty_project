# Curated reference data: the Parts, reference-key rules, strands and the
# close-reading correction layer. All of it lives as CSV under data/.

#' Analysis settings
#'
#' `licensed` is TRUE when the run uses the licensed exports; checks that
#' only hold for the published corpus are enforced only then.
analysis_settings <- function(citing_file) {
  list(
    licensed          = uses_licensed_data(citing_file),
    published_citers  = 221L,
    published_base    = 134L,
    heir_threshold    = 3L,
    year_breaks       = c(2001, 2006, 2011, 2016, 2021, 2026),
    year_labels       = c("2002-2006", "2007-2011", "2012-2016", "2017-2021", "2022-2026"),
    seed              = 20260930L,
    seed_coding       = 20261019L,
    n_boot            = 2000L,
    n_fisher_sim      = 1e5,
    functions         = c("perfunctory", "reviewed", "supported", "negative", "applied")
  )
}

#' Load the reference and correction tables
load_reference <- function(files) {
  read <- function(name) read_reference_csv(files[basename(files) == paste0(name, ".csv")])

  parts <- read("parts")
  strands <- read("strand_keys")
  authors <- read("project_authors")$author
  corrections <- read("part_corrections")

  ref <- list(
    parts              = parts,
    merge_rules        = read("merge_rules"),
    self_patterns      = read("self_citation_patterns")$pattern,
    uncertainty_keys   = strands$ref_key[strands$strand == "Uncertainty"],
    cs_keys            = strands$ref_key[strands$strand == "Cognitive styles"],
    project_authors    = authors,
    named_papers       = read("named_papers"),
    table1_submitted   = read("table1_submitted"),
    base_exclusions    = read("base_exclusions"),
    part_corrections   = tibble::as_tibble(corrections[c("UT", "part", "action", "status", "note")]),
    correction_category = corrections$category,
    record_flags       = tibble::as_tibble(read("record_flags"))
  )
  ref$author_regex <- paste0("(^|;)\\s*(", paste(authors, collapse = "|"), ")\\s*(;|$)")
  ref$foundation_author_regex <- paste0("^(", paste(authors, collapse = "|"), ")[ .,]")
  validate_reference(ref)
  ref
}

validate_reference <- function(ref) {
  stopifnot(
    "parts.csv must list the five Parts" = nrow(ref$parts) == 5L,
    "corrections must use known actions" =
      all(ref$part_corrections$action %in% c("remove", "retain", "add")),
    "corrections must refer to known Parts" =
      all(ref$part_corrections$part %in% ref$parts$part),
    "a key cannot belong to both strands" =
      !any(ref$uncertainty_keys %in% ref$cs_keys)
  )
  invisible(TRUE)
}

strand_of <- function(key, ref) {
  dplyr::case_when(
    key %in% ref$uncertainty_keys ~ "Uncertainty",
    key %in% ref$cs_keys          ~ "Cognitive styles",
    TRUE                          ~ "Other"
  )
}
