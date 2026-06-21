# 1. Read the corrected 302-record corpus
citing_corrected <- read.csv(
  "output/tables/corrected_citing_records.csv",
  stringsAsFactors = FALSE
)

cat("Records loaded:", nrow(citing_corrected), "\n")

# 2. Match Parts via DOI patterns in the CR field
#    (covers most cases; author-year fallback for older refs without DOIs)
library(stringr)
library(dplyr)

citing_corrected <- citing_corrected %>%
  mutate(
    # Part-to-DOI mapping (matches R/config.R):
    #   P1 Spink  = 10.1002/ASI.10081  (JASIST V53, P695)
    #   P2 Wilson = 10.1002/ASI.10082
    #   P3 Spink  = 10.1002/ASI.10083  (JASIST V53, P842)
    #   P4 Ford   = 10.1002/ASI.10084
    #   P5 Ellis  = 10.1002/ASI.10133
    cites_P1 = str_detect(CR, fixed("10.1002/ASI.10081")) |
      str_detect(CR, regex("SPINK A,\\s*2002,\\s*J AM SOC INF SCI TEC,\\s*V53,\\s*P695",
                           ignore_case = TRUE)),
    cites_P2 = str_detect(CR, fixed("10.1002/ASI.10082")) |
      str_detect(CR, regex("WILSON TD?,\\s*2002,\\s*J AM SOC INF",
                           ignore_case = TRUE)),
    cites_P3 = str_detect(CR, fixed("10.1002/ASI.10083")) |
      str_detect(CR, regex("SPINK A,\\s*2002,\\s*J AM SOC INF SCI TEC,\\s*V53,\\s*P842",
                           ignore_case = TRUE)),
    cites_P4 = str_detect(CR, fixed("10.1002/ASI.10084")) |
      str_detect(CR, regex("FORD N,\\s*2002,\\s*J AM SOC INF SCI TEC",
                           ignore_case = TRUE)),
    cites_P5 = str_detect(CR, fixed("10.1002/ASI.10133")) |
      str_detect(CR, regex("ELLIS D,\\s*2002,\\s*J AM SOC INF SCI TEC",
                           ignore_case = TRUE)),
    n_parts_cited = cites_P1 + cites_P2 + cites_P3 + cites_P4 + cites_P5
  )

# 3. Apply Part-level corrections from the audit trail
audit <- read.csv(
  "output/tables/correction_audit_trail.csv",
  stringsAsFactors = FALSE
)

# Get Part-level false positives (papers in corpus but
# with a specific Part citation removed)
part_fps <- audit %>%
  filter(action == "remove",
         record_retained_in_forward_corpus == TRUE |
           part_level_remove == TRUE)

# Zero out false-positive Part flags per audit trail
for (i in seq_len(nrow(part_fps))) {
  ut  <- part_fps$UT[i]
  prt <- part_fps$part[i]
  col <- paste0("cites_", prt)
  if (col %in% names(citing_corrected)) {
    idx <- which(citing_corrected$UT == ut)
    if (length(idx) > 0) {
      citing_corrected[idx, col] <- FALSE
    }
  }
}

# Recalculate n_parts_cited after corrections
citing_corrected <- citing_corrected %>%
  mutate(
    n_parts_cited = cites_P1 + cites_P2 + cites_P3 +
      cites_P4 + cites_P5
  )

# 4. Tom's three figures — recomputed
# Denominator: Part-citers only (records citing >= 1 of the five Parts after
# corrections), matching the 06 bibliographic-coupling corpus (n = 221).
# The full corrected corpus (302) includes records that reach the UP only via
# the pre-2002 precursors and is NOT the correct base for a Part-citation
# distribution.
cat("\n===== RECOMPUTED FIGURES FOR TOM =====\n\n")

part_citers <- citing_corrected %>% filter(n_parts_cited >= 1)
n_part_citers <- nrow(part_citers)
cat("Part-citers (denominator):", n_part_citers, "\n")

single <- sum(part_citers$n_parts_cited == 1)
single_pct <- 100 * single / n_part_citers
cat("Single-Part citers:", single,
    sprintf("(%.1f%%)\n", single_pct))

all_five <- sum(part_citers$n_parts_cited == 5)
cat("Papers citing all five Parts:", all_five, "\n")

three_plus <- sum(part_citers$n_parts_cited >= 3)
cat("Papers citing three or more Parts:", three_plus, "\n")

# 5. Full distribution for reference
cat("\n--- Distribution of Parts cited per paper (Part-citers only) ---\n")
print(table(part_citers$n_parts_cited))

cat("\n--- Records in corpus citing zero Parts (precursor-only reach) ---\n")
zero <- sum(citing_corrected$n_parts_cited == 0)
cat("Zero-Part records:", zero,
    "(reach the UP only via pre-2002 precursors; excluded from the distribution)\n")