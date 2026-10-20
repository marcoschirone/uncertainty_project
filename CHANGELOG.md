# Changelog

## 1.1.0 (in preparation)

Analyses added in the first round of review, and a rebuild of the workflow.

### Workflow

- The numbered scripts are replaced by a `targets` pipeline (`_targets.R`, with
  functions in `R/`). Steps rerun only when their code or inputs change.
- The correction layer and all lookup lists are CSV files under
  `data/corrections/` and `data/reference/` instead of R code.
- The cited-reference parser is vectorised (6-20 times faster) and gives
  identical output.
- Unit tests (`tests/testthat/`), lint configuration and a GitHub Actions
  workflow that runs the tests and the whole pipeline on the synthetic data.
- Inputs are `wos_parts.txt` and `wos_citing.txt`. Any citing export that
  contains the Part citers can be used; records not citing a Part by DOI are
  dropped.
- A licensed run refreshes `results/`, withholding the full citing records and
  author addresses.
- `results/tables/corpus_records.csv` lists the accession number, DOI and year
  of the 241 retrieved records, with status, validated Parts and removal
  reason, as stated in the article's data-availability section.
- `output/checks/reported_numbers.csv` recomputes every number reported in the
  article; with `data/private/manuscript_values.csv` the run compares them with
  the text.

### Analyses added

- Author-overlap sensitivity: citing papers with any Project author, and
  foundations first-authored by the Project team, excluded in turn and together.
- Part-specific coupling of each Part's own and exclusive references, and the
  number of Parts cited per record.
- Temporal trends with a citation-ageing baseline (foundations per pre-2002
  reference), five-year windows with bootstrap intervals, and annual counts.
- Survivorship: reproduction rates for all 134 foundations by strand, Part of
  origin, period, source type and authorship.
- Venues and WoS Research Areas per Part.
- Checks of the named research groups, repeat authors, and the tests of the
  submitted Table 1.
- Table 1 rebuilt from the coding sheet on the 221-paper corpus under the
  primary-author and any-author rules, with per-Part reconciliation and
  false-positive rates; paper-level association of citation function with
  reference overlap; Cohen's kappa for a blind second coder.

### Verification

On the licensed data the pipeline reproduces the 41 tables of the previous
scripts byte for byte. The number of shared foundations and every corpus count
are unchanged.

### Before release

- Add the completed coding sheets to `data/manual/` and rerun.
- Update `CITATION.cff` (version, date) and the README badge to the 1.1.0 record.

## five-part-scope (August 2026)

### Added

- `scripts/02_read_and_parse_wos.R` now restricts the citing corpus to records
  citing at least one of the five Parts by DOI. `part_dois` was defined in
  `R/config.R` for this purpose but never used, so the pipeline implemented the
  superseded eight-source path (323 - 4 - 17 = 302) rather than the published
  five-Part path (241 - 3 - 17 = 221).
- Synthetic demonstration exports are now committed to `data/raw/`. The README
  had claimed they were present, but the directory held only `README.md` and
  `UP_dois.csv`, so `source("scripts/00_run_all.R")` failed on a fresh clone.
- `results/` holds the tables and figures from the licensed Web of Science
  corpus reported in the paper, kept separate from `output/`, which holds the
  synthetic demo run.

### Changed

- `data-raw/make_synthetic_wos.py` retuned so the synthetic corpus mirrors the
  real chain: 323 raw records, 241 citing at least one Part, three base
  exclusions among them, 17 record-level false positives, 221 validated.
- README corrected throughout: the data notice, the run instructions, the
  `data/private/` override, and the provenance of `UP_dois.csv`.

### Not included

`corrected_citing_records.csv`, the full Web of Science records for the 221
citing papers, is withheld under the Clarivate licence. Accession numbers and
DOIs sufficient to reconstruct it are in `data/raw/UP_dois.csv` and
`results/tables/correction_audit_trail.csv`.


## github-synthetic-data

Prepares the project for public release without proprietary data:

- `data/raw/` now holds **synthetic** WoS-format exports (fabricated records;
  illustrative outputs only). Generator: `data-raw/make_synthetic_wos.py`
  (deterministic; reads the R config so identifiers stay in sync).
- `R/config.R` `resolve_input()` prefers real exports in git-ignored
  `data/private/` over the synthetic demo files, so real runs never touch
  tracked files.
- Added `.gitignore`, `LICENSE` (MIT, fill in holder), `data/raw/README.md`,
  `data/private/README.md`, and a data notice in the main README.

## pct-denominator

- `foundation_counts.csv` `pct_citers` is now computed on the bibliographic-
  coupling corpus (Part-citers, n = 221) instead of the full corrected corpus
  (n = 302), so the percentages agree with the manuscript text
  (e.g. Wilson 1999 = 27.6%, not 20.2%). `n_citers` is unchanged; only the
  percentage base changed. Stage 07 no longer reads `cit_cr_corrected.rds`.

## coupling-terminology

Aligns the codebase vocabulary with the manuscript (`Bibliometrics_methods_and_results_updated.docx`):

- Method renamed throughout from "forward triangulation" to **bibliographic
  coupling**. `scripts/06_triangulation_corrected.R` ->
  `scripts/06_bibliographic_coupling.R`; `triangulation` object -> `coupling`;
  `summary_triang` -> `summary_coupling`; `triangulation.rds`/`summary_triang.rds`
  -> `coupling.rds`/`summary_coupling.rds`; `triangulation_summary.csv` ->
  `coupling_summary.csv`.
- Uncertainty strand: `info_behaviour_keys` -> `uncertainty_keys`; column
  suffix `_ib` -> `_unc` (`n_shared_ib`/`mean_shared_ib` -> `n_shared_unc`/
  `mean_shared_unc`) across stages 06-07. Strand display labels were already
  "Uncertainty"/"Cognitive styles".
- The measure `n_shared` is documented as the manuscript's **intellectual
  base overlap**.
- Added the manuscript's three-way classification: intellectual heirs
  (>=3 shared), intermediate (1-2), surface citers (0). New outputs
  `intermediate_citers.csv` and `coupling_classification_summary.csv`.
- Note: descriptive text in the `note` column of `corpus_reconciliation.csv`
  changed "triangulation" -> "coupling analysis"; counts are unchanged.

## five-part

Accommodates the eight-to-five-Part restriction and hardens the pipeline
against accidental reversion:

- Source set fixed to the five JASIST 2002 Parts (`citing_jasist5.txt`).
  Wilson (1999, IP&M) now re-enters as an external foundation.
- Added five-Part invariant guards in `R/config.R` (UT/DOI counts, cross-citer
  subset) and a hard `nrow(up_raw) == 5` check in
  `scripts/02_read_and_parse_wos.R` so the old eight-record export fails loudly
  instead of producing eight-Part results.
- `scripts/03_apply_corrections.R` now always writes
  `manual_additions_missing_from_raw_export.csv` (header-only when empty), so a
  stale copy from a wider-corpus run cannot persist. In the five-Part corpus
  the three Ford 2004 additions are present, so the file is expected to be
  empty.
- `scripts/05_overlap_matrix.R` warns unless the matrix is 5x5 over the five
  named Parts.
- `Recompute_Parts.R`: corrected the swapped P1/P2 DOI/author-year mapping and
  changed the distribution denominator from the full corrected corpus (302) to
  the Part-citers (221), matching the bibliographic-coupling corpus.
- Documentation (`README.md`, `methods_note.md`) updated to five Parts; the
  legacy single-file workflow dropped from the project tree.

Reconciliation verified independently of `bibliometrix`: 323 raw -> 302
corrected -> 221 Part-citers; manual additions present = 3, missing = 0.

## final

- Consolidates corrected-corpus pipeline.
- Adds explicit corpus reconciliation output.
- Separates Part-level correction annotations from record-level removals.
- Uses scalar-safe `safe_pct()` for foundation percentages.
- Adjusts top-foundation and strand-comparison figure widths and label placement.
