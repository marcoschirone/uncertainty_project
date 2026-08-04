# UP Bibliographic-Coupling Project

## Reconstructing the Intellectual Base of the Uncertainty Project

> **Data notice.** This repository contains synthetic Web of Science–style demonstration data, not Web of Science Core Collection records. The workflow is fully executable on a fresh clone, but the resulting statistics, tables, and figures are illustrative and do not reproduce the published results.

---

## Overview

This repository provides a reproducible R workflow for reconstructing and analysing the intellectual base of the Uncertainty Project through bibliographic coupling.

The workflow demonstrates:

- citation parsing
- corpus validation
- correction-layer processing
- intellectual-base reconstruction
- bibliographic coupling
- temporal analysis
- figure generation

without redistributing proprietary Clarivate Web of Science data.

---

## Running the Analysis

The synthetic inputs are committed, so a fresh clone runs directly:

```r
source("scripts/00_run_all.R")
```

### Regenerating the synthetic data

`data-raw/make_synthetic_wos.py` rebuilds `data/raw/citing_jasist5.txt` and
`data/raw/323_references.txt`. It parses `R/config.R`, `R/corrections.R` and
`R/lookups.R` so the synthetic records carry the accession numbers, DOIs and
reference keys the code expects, which means it must be re-run whenever any of
those three files changes:

```bash
python data-raw/make_synthetic_wos.py
```

The generator is deterministic (seed 20020621), so regeneration is reproducible.

---

## Input Files

Inputs are resolved by `resolve_input()` in `R/config.R`, which looks in
`data/private/` first and falls back to `data/raw/`.

| File | Location | Description |
|---|---|---|
| `citing_jasist5.txt` | `data/raw/` (committed) | Synthetic export representing the five Uncertainty Project source articles and their cited references |
| `323_references.txt` | `data/raw/` (committed) | Synthetic citing-record export |
| `UP_dois.csv` | `data/raw/` (committed) | DOIs of the real citing corpus: 196 of the 241 retrieved records, the remaining 45 carrying no DOI in the source data |

### Using licensed Web of Science data

Holders of a Web of Science subscription can reproduce the published results by
placing their own exports in `data/private/`, which is gitignored:

```
data/private/citing_jasist5.txt
data/private/323_references.txt
```

`resolve_input()` will prefer these over the synthetic files. Nothing in
`data/private/` is tracked by git.

---

## Corpus Definition

For reference, the published analysis proceeds as follows:

| Step | Records |
|---|---|
| Retrieved from WoS CC (eight source documents) | 323 |
| Restricted to records citing at least one of the five Parts, by DOI | 241 |
| Base exclusions (intra-project cross-citations, erratum) | −3 |
| Record-level false positives removed after close reading | −17 |
| **Validated citing corpus** | **221** |

The correction layer in `R/corrections.R` records every Part-level judgement,
and `output/tables/correction_audit_trail.csv` documents how each was applied.

---

## Results

| Directory | Contents |
|---|---|
| `results/` | Tables and figures from the **licensed** Web of Science corpus, as reported in the paper |
| `output/` | Whatever the **synthetic** demonstration data produces when you run the pipeline |

The two are not comparable. `results/README.md` explains what is included, what
is withheld under the Clarivate licence, and how a subscriber can reconstruct
the full record set.

---

## Reproducibility Statement

This repository reproduces the analytical workflow but not the published
numerical results. Published results require licensed Web of Science data that
cannot be redistributed. The accession numbers and DOIs needed to reconstruct
the corpus from a Web of Science subscription are provided in
`data/raw/UP_dois.csv`.

---

## License

Code is distributed under the MIT License.
