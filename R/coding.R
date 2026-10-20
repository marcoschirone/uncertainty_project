# Citation-function coding: Table 1 on the validated corpus, its association
# with reference overlap, and inter-coder reliability. All analyses are skipped
# until coding files are placed in data/manual/.

#' Read the coding files, if present
#'
#' Primary codes: R2_03_coding.csv (the coding sheet saved as CSV UTF-8) or
#' citation_function_codes.csv. Second coder: R2_06_second_coder.csv or
#' citation_function_second_coder.csv. Column names are case-insensitive.
read_coding <- function(dir, settings) {
  first_existing <- function(files) {
    hit <- file.path(dir, files)[file.exists(file.path(dir, files))]
    if (length(hit)) hit[1] else NA_character_
  }
  primary <- first_existing(c("R2_03_coding.csv", "citation_function_codes.csv"))
  second <- first_existing(c("R2_06_second_coder.csv", "citation_function_second_coder.csv"))
  list(
    primary = if (!is.na(primary)) read_code_sheet(primary, "C1", settings),
    second = if (!is.na(second)) read_code_sheet(second, "C2", settings),
    sources = c(primary = primary, second = second)
  )
}

read_code_sheet <- function(path, default_coder, settings) {
  txt <- readLines(path, encoding = "UTF-8", warn = FALSE)
  txt[1] <- sub("^﻿", "", txt[1])
  x <- utils::read.csv(text = txt, stringsAsFactors = FALSE, check.names = FALSE,
                       encoding = "UTF-8", na.strings = c("", "NA"))
  names(x) <- tolower(trimws(names(x)))
  column <- function(candidates) {
    hit <- intersect(candidates, names(x))
    if (length(hit)) x[[hit[1]]] else NA
  }
  out <- tibble::tibble(
    UT = trimws(column("ut")),
    part = toupper(trimws(column("part"))),
    `function` = tolower(trimws(column("function"))),
    coder = column("coder"),
    notes = column("notes"),
    contrastive = toupper(trimws(column("contrastive"))),
    misattribution = toupper(trimws(column("misattribution")))
  )
  out$coder[is.na(out$coder) | out$coder == ""] <- default_coder
  out <- out %>% filter(!is.na(`function`), `function` != "")

  bad <- setdiff(unique(out$`function`), settings$functions)
  if (length(bad)) {
    stop("Unknown function labels in ", basename(path), ": ", paste(bad, collapse = ", "),
         call. = FALSE)
  }
  dup <- out %>% count(UT, part) %>% filter(n > 1)
  if (nrow(dup)) stop("Duplicate UT + part rows in ", basename(path), call. = FALSE)
  out
}

#' Classify every validated paper-Part link
#'
#' External under the primary-author rule: not institutional, the Part's
#' primary author is not an author, full text available. Under the any-author
#' rule, no Project author at all.
coding_links <- function(inp, coding, ref) {
  unavailable <- ref$part_corrections %>%
    filter(status %in% c("unavailable", "inaccessible"), action != "remove") %>%
    distinct(UT, part) %>%
    mutate(unavailable = TRUE)
  coded <- coding$primary %>%
    select(UT, part, `function`, contrastive, misattribution) %>%
    mutate(coded = TRUE)

  inp$part_attr %>%
    left_join(inp$meta %>% select(UT, AU, flag_type, author_overlap), by = "UT") %>%
    left_join(unavailable, by = c("UT", "part")) %>%
    mutate(unavailable = coalesce(unavailable, FALSE),
           institutional = flag_type == "institutional",
           primary_self = is_primary_author(AU, part, ref),
           external_primary = !institutional & !primary_self & !unavailable,
           external_any = !institutional & !author_overlap & !unavailable) %>%
    left_join(coded, by = c("UT", "part")) %>%
    mutate(coded = coalesce(coded, FALSE))
}

#' Table 1 from the codes, with per-Part reconciliation
table1_analysis <- function(coding, inp, wos, ref, settings) {
  if (is.null(coding$primary)) return(list(tables = list()))
  set.seed(settings$seed_coding)
  fns <- settings$functions
  B <- settings$n_fisher_sim
  links <- coding_links(inp, coding, ref)

  missing_codes <- links %>%
    filter(external_primary, !coded) %>%
    left_join(inp$meta %>% select(UT, PY, TI), by = "UT") %>%
    select(part, UT, PY, TI) %>%
    arrange(part, PY)
  unexpected <- coding$primary %>%
    anti_join(links %>% select(UT, part), by = c("UT", "part")) %>%
    select(UT, part, `function`, notes)
  coverage <- links %>%
    group_by(part) %>%
    summarise(validated_links = n(),
              n_external_primary = sum(external_primary),
              n_external_any = sum(external_any),
              n_coded_external_primary = sum(external_primary & coded),
              n_missing_codes = sum(external_primary & !coded),
              .groups = "drop") %>%
    left_join(unexpected %>% count(part, name = "codes_outside_validated_links"), by = "part") %>%
    mutate(codes_outside_validated_links = coalesce(codes_outside_validated_links, 0L))

  doi_matched <- attribute_parts(wos$citing_refs %>% filter(!UT %in% ref$base_exclusions$UT),
                                 ref, ref$part_corrections[0, ]) %>%
    count(part, name = "wos_doi_matched")
  removals <- ref$part_corrections %>% filter(action == "remove") %>% distinct(UT, part, status)
  false_positives <- removals %>%
    filter(stringr::str_detect(status, "^false_positive")) %>%
    count(part, name = "false_positives")
  removed_inaccessible <- removals %>%
    filter(status == "inaccessible") %>%
    count(part, name = "removed_inaccessible")
  false_negatives <- ref$part_corrections %>%
    filter(action == "add") %>%
    distinct(UT, part) %>%
    count(part, name = "false_negatives_added")
  reconciliation <- ref$parts %>%
    select(part) %>%
    left_join(doi_matched, by = "part") %>%
    left_join(false_positives, by = "part") %>%
    left_join(removed_inaccessible, by = "part") %>%
    left_join(false_negatives, by = "part") %>%
    left_join(links %>%
                group_by(part) %>%
                summarise(validated = n(),
                          n_institutional = sum(institutional),
                          n_primary_self = sum(primary_self & !institutional),
                          n_unavailable = sum(unavailable & !institutional & !primary_self),
                          n_external_primary = sum(external_primary),
                          n_external_any = sum(external_any),
                          n_coded_primary = sum(external_primary & coded),
                          n_coded_any = sum(external_any & coded),
                          .groups = "drop"), by = "part") %>%
    mutate(across(-part, ~ coalesce(as.integer(.x), 0L)),
           check = wos_doi_matched - false_positives - removed_inaccessible +
             false_negatives_added - validated)
  if (any(reconciliation$check != 0)) {
    warning("Per-Part reconciliation does not close for: ",
            paste(reconciliation$part[reconciliation$check != 0], collapse = ", "), call. = FALSE)
  }
  fp_rates <- reconciliation %>%
    transmute(part, false_positives, wos_doi_matched,
              fp_rate_pct = round(100 * false_positives / wos_doi_matched, 1),
              removed_inaccessible, false_negatives_added)

  tables <- list(
    table1_coverage_check = coverage,
    table1_missing_codes = missing_codes,
    table1_unexpected_codes = unexpected,
    per_part_reconciliation = reconciliation,
    false_positive_rates = fp_rates
  )

  for (rule in c("primary_author", "any_author")) {
    keep <- if (rule == "primary_author") links$external_primary else links$external_any
    d <- links[keep & links$coded, ] %>%
      mutate(`function` = factor(`function`, levels = fns),
             part = factor(part, levels = ref$parts$part))
    tab <- table(d$part, d$`function`)
    counts <- as.data.frame.matrix(tab) %>%
      tibble::rownames_to_column("part") %>%
      mutate(n = rowSums(across(all_of(fns))))
    pct <- counts %>% mutate(across(all_of(fns), ~ round(100 * .x / n)))

    t2 <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]
    chi <- suppressWarnings(stats::chisq.test(t2, correct = FALSE))
    fmc <- stats::fisher.test(t2, simulate.p.value = TRUE, B = B)
    tests <- tibble::tibble(rule = rule, n = sum(t2), chisq = unname(chi$statistic),
                            df = unname(chi$parameter), p = chi$p.value,
                            cramers_v = cramers_v(t2),
                            expected_below_5 = sum(chi$expected < 5),
                            cells = length(chi$expected),
                            fisher_monte_carlo_p = fmc$p.value)

    pairs <- utils::combn(rownames(t2), 2, simplify = FALSE)
    pairwise <- purrr::map_dfr(pairs, function(pp) {
      m <- t2[pp, , drop = FALSE]
      m <- m[, colSums(m) > 0, drop = FALSE]
      c2 <- suppressWarnings(stats::chisq.test(m, correct = FALSE))
      tibble::tibble(pair = paste(pp, collapse = "-"), chisq_p = c2$p.value,
                     fisher_p = stats::fisher.test(m, simulate.p.value = TRUE, B = B)$p.value,
                     cramers_v = cramers_v(m))
    }) %>%
      mutate(sig_bonferroni = chisq_p < 0.05 / n(), alpha_bonferroni = 0.05 / n())

    cells <- purrr::map_dfr(colnames(t2), function(category) {
      purrr::map_dfr(pairs, function(pp) {
        k <- t2[pp, category]
        nn <- rowSums(t2[pp, , drop = FALSE])
        tibble::tibble(category = category, pair = paste(pp, collapse = "-"),
                       pct_1 = round(100 * k[1] / nn[1]), pct_2 = round(100 * k[2] / nn[2]),
                       fisher_p = stats::fisher.test(matrix(c(k, nn - k), 2))$p.value)
      })
    }) %>%
      mutate(sig_bonferroni = fisher_p < 0.05 / length(pairs))

    tables[[paste0("table1_counts_", rule)]] <- counts
    tables[[paste0("table1_percent_", rule)]] <- pct
    tables[[paste0("table1_tests_", rule)]] <- tests
    tables[[paste0("table1_pairwise_", rule)]] <- pairwise
    tables[[paste0("table1_cells_", rule)]] <- cells
  }

  tables$table1_contrastive_misattribution <- links %>%
    filter(external_primary, coded) %>%
    group_by(part) %>%
    summarise(coded = n(),
              contrastive = sum(contrastive %in% c("Y", "YES"), na.rm = TRUE),
              misattribution = sum(misattribution %in% c("Y", "YES"), na.rm = TRUE),
              .groups = "drop")

  list(tables = tables)
}

#' Paper-level association of citation function with reference overlap
#'
#' A paper is "substantive_any" if any cited Part is reviewed, supported,
#' negative or applied, and "perfunctory_only" otherwise. The paper, not the
#' paper-Part link, is the unit, so the observations are independent.
function_overlap_analysis <- function(coding, inp, settings) {
  codes <- coding$primary
  if (is.null(codes)) return(list(tables = list()))
  if (any(!codes$UT %in% inp$uts)) {
    warning("Some coded records are outside the validated corpus.", call. = FALSE)
  }
  B <- settings$n_fisher_sim

  paper <- codes %>%
    group_by(UT) %>%
    summarise(n_parts_coded = n(),
              engagement = ifelse(all(`function` == "perfunctory"),
                                  "perfunctory_only", "substantive_any"),
              functions_present = paste(sort(unique(`function`)), collapse = ";"),
              .groups = "drop") %>%
    inner_join(inp$baseline %>%
                 transmute(UT, n_shared,
                           overlap_class = case_when(n_shared >= 3 ~ "high_overlap",
                                                     n_shared >= 1 ~ "limited_overlap",
                                                     TRUE ~ "no_overlap")),
               by = "UT") %>%
    mutate(engagement = factor(engagement, levels = c("perfunctory_only", "substantive_any")),
           overlap_class = factor(overlap_class,
                                  levels = c("no_overlap", "limited_overlap", "high_overlap")))

  test_table <- function(tab, unit, statistic = NULL) {
    chi <- suppressWarnings(stats::chisq.test(tab, correct = FALSE))
    set.seed(settings$seed)
    fmc <- stats::fisher.test(tab, simulate.p.value = TRUE, B = B)
    if (is.null(statistic)) statistic <- NA_character_
    tibble::tibble(unit = unit, n_papers = sum(tab), statistic = statistic,
                   chisq = unname(chi$statistic), df = unname(chi$parameter),
                   chisq_p = chi$p.value, min_expected = min(chi$expected),
                   cramers_v = sqrt(unname(chi$statistic) / (sum(tab) * (min(dim(tab)) - 1))),
                   fisher_monte_carlo_p = fmc$p.value, fisher_B = B)
  }

  tab <- table(paper$engagement, paper$overlap_class)
  tables <- list(
    citation_function_overlap_paper_level = paper,
    citation_function_overlap_crosstab = with_row_names(as.data.frame.matrix(tab)),
    citation_function_overlap_association =
      test_table(tab, "paper", "citation engagement x overlap class")
  )

  single <- codes %>%
    inner_join(inp$part_attr %>% count(UT, name = "n_parts") %>% filter(n_parts == 1), by = "UT")
  if (nrow(single) > 0) {
    ts <- table(single$part, single$`function`)
    ts <- ts[rowSums(ts) > 0, colSums(ts) > 0, drop = FALSE]
    tables$table1_single_part_citers_crosstab <- with_row_names(as.data.frame.matrix(ts))
    tables$table1_single_part_citers_test <-
      test_table(ts, "paper; single-Part citers only") %>% select(-statistic)
  }
  list(tables = tables)
}

#' Agreement between two independent coders, before adjudication
reliability_analysis <- function(coding, settings) {
  if (is.null(coding$primary) || is.null(coding$second)) return(list(tables = list()))
  pick <- function(x, label) {
    x %>% transmute(UT, part, !!paste0("function_", label) := `function`)
  }
  d <- inner_join(pick(coding$primary, "c1"), pick(coding$second, "c2"), by = c("UT", "part"))
  if (!nrow(d)) stop("No overlapping UT + part cases between the coders.", call. = FALSE)

  k5 <- cohen_kappa(d$function_c1, d$function_c2, settings$functions)
  d <- d %>%
    mutate(binary_c1 = ifelse(function_c1 == "perfunctory", "perfunctory", "substantive"),
           binary_c2 = ifelse(function_c2 == "perfunctory", "perfunctory", "substantive"))
  k2 <- cohen_kappa(d$binary_c1, d$binary_c2, c("perfunctory", "substantive"))

  list(tables = list(
    citation_function_reliability = tibble::tibble(
      coding = c("five-category nominal", "binary perfunctory/substantive"),
      n_double_coded = c(k5["n"], k2["n"]),
      raw_agreement = c(k5["agreement"], k2["agreement"]),
      cohen_kappa = c(k5["kappa"], k2["kappa"])
    ),
    citation_function_reliability_confusion =
      with_row_names(as.data.frame.matrix(table(d$function_c1, d$function_c2))),
    citation_function_double_coded_cases = d
  ))
}

#' Clean coding files for deposit
clean_coding_tables <- function(coding) {
  out <- list()
  if (!is.null(coding$primary)) {
    out$citation_function_codes <- coding$primary %>% select(UT, part, `function`, coder, notes)
  }
  if (!is.null(coding$second)) {
    out$citation_function_second_coder <- coding$second %>%
      select(UT, part, `function`, coder, notes)
  }
  out
}
