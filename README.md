# UP Bibliographic-Coupling Project

## Reconstructing the Intellectual Base of the Uncertainty Project

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21804423.svg)](https://doi.org/10.5281/zenodo.21804423)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Data notice.** This repository contains synthetic Web of Science–style
> demonstration data, not Web of Science Core Collection records. The workflow is
> fully executable on a fresh clone, but the statistics, tables and figures it
> produces are illustrative and do not reproduce the published results. The
> published results are in `results/`.

---

## Overview

A reproducible R workflow for reconstructing and analysing the intellectual base
of the Uncertainty Project, a five-paper series published in the *Journal of the
American Society for Information Science and Technology* in 2002, through
bibliographic coupling of its citing literature.

The pipeline covers citation parsing, corpus validation, correction-layer
processing, intellectual-base reconstruction, bibliographic coupling, temporal
analysis and figure generation, without redistributing proprietary Clarivate Web
of Science data.

---

## Repository structure

| Path | Contents |
|---|---|
| `R/` | Configuration, lookups, the correction layer, and helper functions |
| `scripts/` | The pipeline, `00_run_all.R` through `08_session_log.R` |
| `data/raw/` | Synthetic inputs (committed) and `UP_dois.csv` |
| `data/private/` | Where licensed Web of Science exports go (gitignored) |
| `data-raw/` | `make_synthetic_wos.py`, the synthetic data generator |
| `results/` | Tables and figures from the licensed corpus, as reported in the paper |
| `output/` | Whatever the synthetic data produces when you run the pipeline (gitignored) |

`results/` and `output/` are **not comparable**. `results/README.md` explains what
is included, what is withheld under the Clarivate licence, and how a subscriber
can reconstruct the full record set.

---

## Requirements

- R 4.6.0 or later, with `bibliometrix` (5.3.0), `dplyr`, `tidyr`, `stringr`,
  `purrr` and `ggplot2`
- Python 3 for the synthetic data generator only

`output/logs/session_info.txt` records the exact package versions used for the
published run.

---

## Running the analysis

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

## Input files

Inputs are resolved by `resolve_input()` in `R/config.R`, which looks in
`data/private/` first and falls back to `data/raw/`.

| File | Location | Description |
|---|---|---|
| `citing_jasist5.txt` | `data/raw/` (committed) | Synthetic export representing the five source articles and their cited references |
| `323_references.txt` | `data/raw/` (committed) | Synthetic citing-record export |
| `UP_dois.csv` | `data/raw/` (committed) | DOIs of the real citing corpus: 196 of the 241 retrieved records; the remaining 45 carry no DOI in the source data |

### Using licensed Web of Science data

Holders of a Web of Science subscription can reproduce the published results by
placing their own exports in `data/private/`, which is gitignored:

```
data/private/citing_jasist5.txt
data/private/323_references.txt
```

`resolve_input()` prefers these over the synthetic files. Nothing in
`data/private/` is tracked by git.

---

## Corpus definition

The published analysis proceeds as follows:

| Step | Records |
|---|---|
| Retrieved from WoS CC (eight source documents) | 323 |
| Restricted to records citing at least one of the five Parts, by DOI | 241 |
| Base exclusions (intra-project cross-citations, erratum) | −3 |
| Record-level false positives removed after close reading | −17 |
| **Validated citing corpus** | **221** |

The correction layer in `R/corrections.R` records every Part-level judgement, and
`results/tables/correction_audit_trail.csv` documents how each was applied.

---

## Reproducibility statement

This repository reproduces the analytical workflow but not the published
numerical results, which require licensed Web of Science data that cannot be
redistributed. The accession numbers and DOIs needed to reconstruct the corpus
from a subscription are in `data/raw/UP_dois.csv`, and the validation decisions
are in `results/tables/correction_audit_trail.csv`.

---

## Citation

Schirone, M. (2026). *UP Bibliographic Coupling Project* (Version v1.0.0)
[Software]. Zenodo. https://doi.org/10.5281/zenodo.21804423

Machine-readable metadata is in `CITATION.cff`, which GitHub uses to populate the
**Cite this repository** button.

---

## License

Code is distributed under the [MIT License](LICENSE).
