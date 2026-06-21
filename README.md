# UP Bibliographic-Coupling R Project — Corrected Corpus Version

> **Data notice.** This repository ships **synthetic** demonstration data, not
> Web of Science data. The pipeline runs end to end on the synthetic files in
> `data/raw/`, but the resulting numbers are **illustrative only and do not
> reproduce the published results**. The real analysis uses proprietary Web of
> Science Core Collection exports, which are not redistributed here. To run on
> real data, see "Inputs" below. Do not cite figures produced from synthetic data.

This project refactors the original single-file workflow into a modular pipeline and adds a correction layer for false-positive and false-negative citation matching.

## Corpus scope: five Parts (not eight)

The constitutive corpus is the **five JASIST 2002 Parts** only. The three
pre-2002 precursors — Wilson (1999, *IP&M*), Wilson (1999, conference), and
Ford et al. (2000, ASIS) — are treated as contextual, not constitutive, and
are excluded from the source set used to build the intellectual base.

A direct consequence of this restriction is that **Wilson (1999, *IP&M*)
re-enters the analysis as an external foundation** (it is no longer removed as
a self-citation). The five-Part scope is enforced by assertions in
`R/config.R` and `scripts/02_read_and_parse_wos.R`; pointing the source file at
the old eight-record export now stops the run rather than silently producing
eight-Part results.

## Design

The workflow uses a **curated / validated WoS-derived citation corpus** as the primary basis for bibliographic coupling to the intellectual base.

It proceeds as follows:

1. Read the five JASIST 2002 Uncertainty Project source records and the WoS citing-record export.
2. Parse cited references line by line.
3. Apply citation-corpus corrections:
   - remove confirmed false-positive citing records;
   - add confirmed missed citing records when present in the raw WoS export;
   - flag self-citations and institutional citations;
   - retain an audit trail.
4. Construct the Uncertainty Project intellectual base.
5. Run bibliographic coupling to the intellectual base on the corrected corpus.
6. Export tables, figures, and session information.

## Inputs

The pipeline reads two Web of Science plain-text exports (Full Record and Cited
References):

1. `citing_jasist5.txt` — the five JASIST 2002 Parts (Pt1 Spink, Pt2 Wilson,
   Pt3 Spink, Pt4 Ford, Pt5 Ellis); the source set for the intellectual base.
2. `323_references.txt` — the citing records.

**Synthetic demo data (shipped, safe to publish).** Synthetic versions of both
files live in `data/raw/`. They are fabricated records that keep only the
identifiers the code needs (Part UTs/DOIs, the citing UTs in `R/corrections.R`,
and the strand keys in `R/lookups.R`). Regenerate them with:

```
python3 data-raw/make_synthetic_wos.py
```

The generator is deterministic and reads the R config so the fabricated
identifiers stay in sync with the code. See `data/raw/README.md` for details.

**Real data (proprietary, not shipped).** Place the real WoS exports in
`data/private/` (git-ignored):

```
data/private/citing_jasist5.txt
data/private/323_references.txt
```

`R/config.R` automatically prefers `data/private/` when those files exist, so
the real run never modifies the tracked synthetic files.

## Correction layer

The current correction layer is stored in:

- `R/corrections.R`

It includes the verified corrections currently documented in the correction notes. When Tom finishes validating the whole corpus, update this file by adding all additional confirmed removals/additions.

## Running

Open `UP_bibliographic_coupling.Rproj` in RStudio (or set the working directory to the project root), then run:

```r
source("scripts/00_run_all.R")
```

## Main outputs

Correction outputs:
- `output/tables/correction_audit_trail.csv`
- `output/tables/part_level_correction_summary.csv`
- `output/tables/corrected_citing_records.csv`

Coupling outputs:
- `output/tables/coupling_summary.csv`
- `output/tables/coupling_classification_summary.csv`
- `output/tables/foundation_counts.csv`
- `output/tables/strand_summary.csv`
- `output/tables/intellectual_heirs.csv`
- `output/tables/intermediate_citers.csv`
- `output/tables/surface_citers.csv`
- `output/tables/temporal_summary.csv`

Figures:
- `output/figures/overlap_heatmap.png`
- `output/figures/strand_comparison.png`
- `output/figures/temporal_mean_shared.png`
- `output/figures/temporal_strand.png`
- `output/figures/shared_foundations_distribution.png`
- `output/figures/top_foundations.png`

## Important note

The correction layer operates at the citing-record level for the coupling analysis. It also preserves Part-level correction information in the audit trail. Once the whole corpus is validated, the corrected corpus should be treated as the primary analysis corpus.



## Reconciliation outputs

This consolidated version adds explicit reconciliation reporting:

- `output/tables/corpus_reconciliation.csv`
- `output/tables/record_level_correction_summary.csv`
- `output/tables/correction_audit_trail.csv`

The reconciliation separates Part-level correction annotations from record-level removals. This is important because a citing paper may be a false positive for one UP Part while remaining a genuine citer of another Part.


## Final project note

This version is the consolidated corrected-corpus workflow. It includes:

- corrected-corpus construction from the WoS-derived citing set;
- explicit reconciliation of raw records, base exclusions, record-level removals, and final corpus size;
- Part-level correction audit trail;
- corrected percentage calculations for foundation frequencies;
- adjusted figure dimensions and label placement for publication-quality plots.

## License

Code in this repository is offered under the MIT License (see `LICENSE`); fill
in the copyright holder before publishing. The **synthetic** data in `data/raw/`
is fabricated and carries no third-party rights. Real Web of Science data is
proprietary to Clarivate and is **not** included or licensed here.
