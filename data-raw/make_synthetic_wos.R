#!/usr/bin/env Rscript
# Generate synthetic Web of Science exports for the demonstration run.
#
# The licensed Web of Science records cannot be redistributed. This script writes
# two plain-text exports in the WoS tagged format with the structure the pipeline
# expects: the five Part records with their reference lists, and a citing set
# that contains every accession number used by the correction layer. Titles,
# authors, abstracts, venues and the reference lists of citing records are
# invented. Results computed from these files are illustrative only.
#
# Identifiers are read from data/reference/ and data/corrections/, so the script
# must be re-run whenever those files change. From the repository root:
#
#     Rscript data-raw/make_synthetic_wos.R
#
# Output: data/raw/wos_parts.txt and data/raw/wos_citing.txt. Deterministic
# (seed 20020621). Base R only.

set.seed(20020621)

N_RAW <- 323          # records in the citing export
N_PART_CITERS <- 241  # records citing at least one Part by DOI
N_SYNTH_FOUND <- 45   # invented foundations outside the two strands
EXPORT_PARTS <- "2026-05-11"
EXPORT_CITING <- "2026-06-22"
RAW <- file.path("data", "raw")

read_ref <- function(...) {
  utils::read.csv(file.path("data", ...), stringsAsFactors = FALSE, encoding = "UTF-8",
                  colClasses = "character")
}
randint <- function(a, b) sample.int(b - a + 1L, 1L) + a - 1L
shuffle <- function(x) x[sample.int(length(x))]
pick <- function(x, k) x[sample.int(length(x), k)]
choice_w <- function(x, w) x[sample.int(length(x), 1L, prob = w)]
sorted_c <- function(x) sort(unique(x), method = "radix")  # C-locale order

parts <- read_ref("reference", "parts.csv")
strands <- read_ref("reference", "strand_keys.csv")
self_patterns <- read_ref("reference", "self_citation_patterns.csv")$pattern
project_authors <- read_ref("reference", "project_authors.csv")$author
corrections <- read_ref("corrections", "part_corrections.csv")
flags <- read_ref("corrections", "record_flags.csv")
base_exclusions <- read_ref("corrections", "base_exclusions.csv")$UT

part_uts <- parts$UT
part_dois <- parts$doi
part_pages <- parts$start_page
uncertainty_keys <- strands$ref_key[strands$strand == "Uncertainty"]
cognitive_keys <- strands$ref_key[strands$strand == "Cognitive styles"]

remove_uts <- unique(corrections$UT[corrections$action == "remove"])
retain_add_uts <- unique(corrections$UT[corrections$action %in% c("retain", "add")])
record_fp <- setdiff(remove_uts, retain_add_uts)
flag_uts <- unique(flags$UT)

# Reference pools -------------------------------------------------------------
key_to_cr <- function(key) sprintf("%s, V%d, P%d", key, randint(1, 60), randint(1, 400))
strand_keys <- c(uncertainty_keys, cognitive_keys)
strand_crs <- setNames(vapply(strand_keys, key_to_cr, character(1)), strand_keys)
synth_found <- vapply(seq_len(N_SYNTH_FOUND), function(i) {
  sprintf("SYNTHREF %03d, %d, SYNTH J INFORM SCI, V%d, P%d", i, randint(1975, 2001), i %% 40 + 1, i * 3 + 1)
}, character(1))
noise_pool <- vapply(1:260, function(i) {
  sprintf("NOISEREF %03d, %d, NOISE J SYNTH, V%d, P%d", i, randint(1990, 2025), i %% 50 + 1, i * 2 + 3)
}, character(1))
generic <- c("[Anonymous], 2005, SYNTH WORKING PAPER", "*SYNTH ORG, 2009, SYNTH REPORT")
in_press <- c("SPINK A, IN PRESS INFORMATION", "WILSON TD, IN PRESS INFORMATI 2")

journals <- c("JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY",
              "INFORMATION RESEARCH-AN INTERNATIONAL ELECTRONIC JOURNAL",
              "JOURNAL OF DOCUMENTATION", "INFORMATION PROCESSING & MANAGEMENT",
              "SYNTHETIC JOURNAL OF INFORMATION STUDIES", "SYNTHETIC HEALTH INFORMATICS",
              "SYNTHETIC LEARNING TECHNOLOGIES")
journal_weights <- c(6, 2, 2, 2, 5, 1, 1)
research_areas <- setNames(c(
  "Computer Science; Information Science & Library Science",
  "Information Science & Library Science",
  "Computer Science; Information Science & Library Science",
  "Computer Science; Information Science & Library Science",
  "Information Science & Library Science",
  "Health Care Sciences & Services; Medical Informatics",
  "Education & Educational Research; Computer Science"), journals)
doc_types <- c("Article", "Proceedings Paper", "Article; Proceedings Paper", "Review")
doc_weights <- c(78, 8, 7, 7)

# WoS record writer -------------------------------------------------------------
wos_author <- function(name) {
  # 'SPINK A' -> 'Spink, A'; synthetic names pass through
  sp <- regexpr(" ", name, fixed = TRUE)
  if (sp < 0) return(name)
  surname <- substr(name, 1, sp - 1)
  initials <- substr(name, sp + 1, nchar(name))
  if (!nzchar(initials)) return(name)
  paste0(toupper(substr(surname, 1, 1)), tolower(substr(surname, 2, nchar(surname))), ", ", initials)
}

record <- function(ut, ti, py, so, crs, authors, export_date, di = NULL, dt = "Article", tc = 0) {
  lines <- c("PT J", paste("AU", authors[1]), paste0("   ", authors[-1]),
             paste("AF", authors[1]), paste0("   ", authors[-1]),
             paste("TI", ti), paste("SO", so), "LA English", paste("DT", dt),
             "DE synthetic; demonstration",
             "AB Synthetic record generated for pipeline demonstration; not a real publication.",
             sprintf("C1 [%s] Synthetic Univ, Dept Demo, Synth City, Synthland.", authors[1]),
             paste("NR", length(crs)), paste("TC", tc), paste("PY", py))
  if (!is.null(di)) lines <- c(lines, paste("DI", di))
  area <- if (so %in% names(research_areas)) research_areas[[so]] else "Information Science & Library Science"
  lines <- c(lines, paste("SC", area))
  if (length(crs)) lines <- c(lines, paste("CR", crs[1]), paste0("   ", crs[-1]))
  c(lines, paste("DA", export_date), paste("UT", ut), "ER", "")
}

write_wos <- function(path, records) {
  con <- file(path, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(c("FN Clarivate Analytics Web of Science", "VR 1.0", unlist(records), "EF"), con, sep = "\n")
}

# The five Parts -----------------------------------------------------------------
part_titles <- c("framework", "uncertainty", "successive searching", "cognitive styles",
                 "intermediary interaction")
self_crs <- vapply(seq_along(self_patterns), function(i) {
  sprintf("%s, V53, P%d, DOI %s", self_patterns[i], 600 + i - 1, part_dois[(i - 1) %% length(part_dois) + 1])
}, character(1))
every_nth <- function(x, i, k) x[seq(i, length(x), by = k)]

part_records <- lapply(seq_along(part_uts), function(i) {
  k <- length(part_uts)
  crs <- c(strand_crs[every_nth(uncertainty_keys, i, k)],
           strand_crs[every_nth(cognitive_keys, i, k)],
           pick(synth_found, 12), self_crs, generic)
  if (i %in% c(3, 4)) crs <- c(crs, in_press[i - 2])
  crs <- shuffle(unname(crs))
  record(ut = part_uts[i], ti = sprintf("Synthetic Part %d: %s (DEMO DATA)", i, part_titles[i]),
         py = 2002, so = journals[1], crs = crs,
         authors = vapply(c("SPINK A", "WILSON TD", "FORD N"), wos_author, character(1), USE.NAMES = FALSE),
         export_date = EXPORT_PARTS, di = part_dois[i], tc = randint(50, 300))
})

# The citing export -----------------------------------------------------------------
required <- sorted_c(c(base_exclusions, corrections$UT, flag_uts))
synth_uts <- sprintf("WOS:%s", formatC(9e14 + seq_len(N_RAW - length(required)) - 1,
                                       width = 15, format = "f", digits = 0, flag = "0"))
all_uts <- c(required, synth_uts)

# Mirror the real corpus: records with a retain/add annotation and record-level
# false positives cite a Part; so do the base exclusions except Part 2's own
# record, which reaches the export only through a precursor.
base_non_citer <- base_exclusions[1]
must_cite <- intersect(unique(c(retain_add_uts, record_fp, setdiff(base_exclusions, base_non_citer))), all_uts)
pool <- shuffle(all_uts[!all_uts %in% must_cite & !all_uts %in% base_non_citer])
part_citers <- unique(c(must_cite, head(pool, max(0, N_PART_CITERS - length(must_cite)))))

found_items <- c(unname(strand_crs[uncertainty_keys]), synth_found, unname(strand_crs[cognitive_keys]))
found_w <- c(rep(3, length(uncertainty_keys)), rep(2, length(synth_found)), rep(1, length(cognitive_keys)))
share_values <- c(0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 21, 30)
share_weights <- c(20, 16, 16, 12, 9, 7, 5, 5, 4, 3, 2, 1)

weighted_sample <- function(items, w, t) {
  # Weighted sampling without replacement (Efraimidis-Spirakis)
  if (t == 0) return(character(0))
  key <- stats::runif(length(items))^(1 / w)
  items[order(key, decreasing = TRUE)][seq_len(min(t, length(items)))]
}

citing_crs <- function(ut) {
  crs <- character(0)
  if (ut %in% part_citers) {
    for (d in pick(seq_along(part_dois), pick(c(1, 1, 1, 1, 2, 3), 1))) {
      crs <- c(crs, sprintf("Synthpart %d, 2002, J AM SOC INF SCI TEC, V53, %s, DOI %s",
                            d, part_pages[d], part_dois[d]))
    }
    crs <- c(crs, weighted_sample(found_items, found_w, choice_w(share_values, share_weights)))
    if (stats::runif(1) < 0.02) crs <- c(crs, in_press[1])
  } else {
    crs <- c(crs, "Synthwilson TD, 1999, SYNTH INFORM PROCESS MANAG, V35, P839")
  }
  crs <- c(crs, pick(noise_pool, randint(6, 20)))
  shuffle(crs)
}

synth_names <- sprintf("Synthauthor%02d, X", 0:59)
citing_authors <- function() {
  authors <- pick(synth_names, randint(1, 3))
  if (stats::runif(1) < 0.08) {
    pos <- randint(0, length(authors))
    authors <- append(authors, wos_author(pick(project_authors[1:6], 1)), after = pos)
  }
  authors
}

cit_records <- lapply(seq_along(all_uts), function(j) {
  ut <- all_uts[j]
  ti <- if (ut %in% head(base_exclusions, -1)) {
    "Synthetic intra-series cross-citation (DEMO DATA)"
  } else if (ut == tail(base_exclusions, 1)) {
    "Synthetic correction (DEMO DATA)"
  } else {
    sprintf("Synthetic citing study %03d (DEMO DATA)", j)
  }
  so <- choice_w(journals, journal_weights)
  py <- randint(2002, 2026)
  crs <- citing_crs(ut)
  authors <- citing_authors()
  record(ut = ut, ti = ti, py = py, so = so, crs = crs, authors = authors,
         export_date = EXPORT_CITING, di = sprintf("10.9999/synthetic.%04d", j),
         dt = choice_w(doc_types, doc_weights), tc = randint(0, 80))
})

dir.create(RAW, showWarnings = FALSE, recursive = TRUE)
write_wos(file.path(RAW, "wos_parts.txt"), part_records)
write_wos(file.path(RAW, "wos_citing.txt"), cit_records)

cat(sprintf("wos_parts.txt : %d Part records\n", length(part_records)))
cat(sprintf("wos_citing.txt: %d citing records, %d citing a Part, %d base exclusions, %d record-level false positives, %d validated\n",
            length(cit_records), length(part_citers), length(intersect(part_citers, base_exclusions)),
            length(intersect(part_citers, record_fp)),
            length(setdiff(part_citers, c(base_exclusions, record_fp)))))
