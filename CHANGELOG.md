# Changelog

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
