base_path <- getwd()

# ---------------------------------------------------------------------------
# Input resolution.
# The repository ships SYNTHETIC demo exports in data/raw/ (safe to publish).
# To run the real analysis, place the proprietary Web of Science exports under
# data/private/ (which is git-ignored). resolve_input() prefers data/private/
# when present, so the real run never modifies tracked files.
# ---------------------------------------------------------------------------
resolve_input <- function(fname) {
  private <- file.path(base_path, "data", "private", fname)
  if (file.exists(private)) private else file.path(base_path, "data", "raw", fname)
}

up_file  <- resolve_input("citing_jasist5.txt")
cit_file <- resolve_input("323_references.txt")

# ---------------------------------------------------------------------------
# All five JASIST 2002 Parts (for intellectual base construction).
# Used to filter UP source records so that the intellectual base is
# built from the references of all five Parts.
# ---------------------------------------------------------------------------
all_five_uts <- c(
  "WOS:000176317500001",  # Pt1 Spink  (framework)
  "WOS:000176317500002",  # Pt2 Wilson (uncertainty)
  "WOS:000176317500003",  # Pt3 Spink  (successive searching)
  "WOS:000176317500004",  # Pt4 Ford   (cognitive styles)
  "WOS:000177658400002"   # Pt5 Ellis  (intermediary interaction)
)

# ---------------------------------------------------------------------------
# Subset of the five Parts that appear in the citing corpus
# (323_references.txt) as intra-series cross-citations.
# Pt1 (Spink) and Pt5 (Ellis) do not appear in 323_references.txt
# and are therefore omitted — including them would cause a
# reconciliation mismatch. Used only for cross-citation exclusion.
# ---------------------------------------------------------------------------
jasist_uts <- c(
  "WOS:000176317500002",  # Pt2 Wilson
  "WOS:000176317500003",  # Pt3 Spink
  "WOS:000176317500004"   # Pt4 Ford
)

# ---------------------------------------------------------------------------
# DOIs of the five Parts, used to filter the citing corpus to records
# that cite at least one of the five Parts (removing records that cite
# only the pre-2002 UP precursors).
# ---------------------------------------------------------------------------
part_dois <- c(
  "10.1002/ASI.10081",    # Pt1 Spink
  "10.1002/ASI.10082",    # Pt2 Wilson
  "10.1002/ASI.10083",    # Pt3 Spink
  "10.1002/ASI.10084",    # Pt4 Ford
  "10.1002/ASI.10133"     # Pt5 Ellis
)

# Erratum / correction record to exclude from citing corpus
erratum_uts <- c(
  "WOS:000179509900016"
)

# ---------------------------------------------------------------------------
# Five-Part scope guards.
# The corpus is restricted to the five JASIST 2002 Parts. The three pre-2002
# contextual precursors (Wilson 1999 IP&M, Wilson 1999 conference, Ford 2000
# ASIS) are NOT constitutive. These assertions fail loudly if the scope is
# accidentally widened back to eight (e.g. by pointing up_file at the old
# Uncertanty_project_dataset.txt instead of citing_jasist5.txt).
# ---------------------------------------------------------------------------
stopifnot(
  "all_five_uts must list exactly five Part UTs" = length(all_five_uts) == 5L,
  "part_dois must list exactly five Part DOIs"   = length(part_dois) == 5L,
  "jasist_uts (intra-series cross-citers) must be a subset of all_five_uts" =
    all(jasist_uts %in% all_five_uts)
)

processed_dir <- file.path(base_path, "data", "processed")
tables_dir    <- file.path(base_path, "output", "tables")
figures_dir   <- file.path(base_path, "output", "figures")
logs_dir      <- file.path(base_path, "output", "logs")

dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(logs_dir, showWarnings = FALSE, recursive = TRUE)