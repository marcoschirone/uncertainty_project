# UP Bibliographic-Coupling Project

## Reconstructing the Intellectual Base of the Uncertainty Project

> **Data notice.** This repository ships **synthetic demonstration data**, not Web of Science Core Collection data. The pipeline runs end-to-end on the included synthetic files, but resulting statistics are illustrative only and do not reproduce the published findings. Real Web of Science exports are proprietary and are not redistributed.

---

## Overview

This repository contains a reproducible R workflow for reconstructing and analysing the intellectual base of the **Uncertainty Project (UP)** using bibliographic coupling.

The project combines:

- Web of Science–derived citation data
- Citation-corpus validation and correction
- Intellectual-base reconstruction
- Bibliographic-coupling analysis
- Temporal and strand-based analyses
- Fully reproducible outputs

A central contribution of the project is the incorporation of a **validated correction layer** that addresses false-positive and false-negative citation matching before coupling analysis is performed.

---

## Research Contributions

### Methodological

- Explicit five-Part definition of the Uncertainty Project corpus
- Record-level citation validation
- Correction of false-positive and false-negative citation matches
- Construction of a corrected bibliographic-coupling corpus
- Reconstruction of the intellectual foundations of the UP

### Software

- Modular R pipeline
- Reproducible workflow architecture
- Synthetic demonstration dataset
- Automated table and figure generation
- Audit-trail preservation

---

## Corpus Scope

### Constitutive Corpus

The constitutive corpus consists exclusively of the five JASIST 2002 Uncertainty Project Parts:

| Part | Lead Author |
|------|-------------|
| Part 1 | Spink |
| Part 2 | Wilson |
| Part 3 | Spink |
| Part 4 | Ford |
| Part 5 | Ellis |

### Excluded Precursors

The following publications are treated as contextual precursors rather than constitutive UP documents:

- Wilson (1999, IP&M)
- Wilson (1999, conference paper)
- Ford et al. (2000, ASIS)

Because these publications are excluded from the source corpus, they may appear as external intellectual foundations in the coupling analysis.

The five-Part scope is enforced by assertions within the codebase.

---

## Workflow

```text
WoS Source Records
        ↓
Reference Parsing
        ↓
Corpus Validation
        ↓
Correction Layer
        ↓
Intellectual Base Construction
        ↓
Bibliographic Coupling
        ↓
Classification & Analysis
        ↓
Tables, Figures & Audit Outputs
```

### Processing Steps

1. Read source records.
2. Read citing-record export.
3. Parse cited references.
4. Apply validated corrections.
5. Construct intellectual base.
6. Compute bibliographic coupling.
7. Generate classifications.
8. Export tables and figures.

---

## Repository Structure

```text
UP_bibliographic_coupling.Rproj
├── R/
│   ├── config.R
│   ├── corrections.R
│   └── lookups.R
├── scripts/
│   ├── 00_run_all.R
│   └── ...
├── data/
│   ├── raw/
│   └── private/
├── output/
│   ├── tables/
│   └── figures/
├── data-raw/
├── LICENSE
└── README.md
```

---

## Inputs

### Required Files

| File | Purpose |
|--------|---------|
| `citing_jasist5.txt` | Five UP source records |
| `323_references.txt` | Citing-record corpus |

### DOI Dataset

`UP_dois.csv` contains DOI information for the 241 citing documents identified in the study.

- 196 records with assigned DOIs
- 45 records without DOI assignments

---

## Data Availability

### Included

- Synthetic WoS-like source records
- Synthetic citing-record export
- DOI metadata file
- Reproducible workflow code

### Not Included

- Real Web of Science exports
- Licensed Clarivate data

Users wishing to reproduce the published analysis must supply their own licensed Web of Science exports.

---

## Citation-Corpus Validation

The correction layer is implemented in:

```text
R/corrections.R
```

The validation process records:

- confirmed false positives
- confirmed false negatives
- record-level corrections
- part-level corrections
- self-citation flags
- institutional-citation flags

An audit trail is preserved throughout the workflow.

---

## Running the Analysis

Open the project in RStudio and execute:

```r
source("scripts/00_run_all.R")
```

---

## Outputs

### Tables

| Category | Output |
|-----------|---------|
| Audit | correction_audit_trail.csv |
| Audit | corrected_citing_records.csv |
| Audit | part_level_correction_summary.csv |
| Reconciliation | corpus_reconciliation.csv |
| Reconciliation | record_level_correction_summary.csv |
| Coupling | foundation_counts.csv |
| Coupling | strand_summary.csv |
| Coupling | intellectual_heirs.csv |
| Coupling | temporal_summary.csv |

### Figures

| Figure |
|---------|
| overlap_heatmap.png |
| strand_comparison.png |
| temporal_mean_shared.png |
| temporal_strand.png |
| shared_foundations_distribution.png |
| top_foundations.png |

---

## Reproducibility

### Fully Reproducible

- Workflow execution
- Synthetic-data analysis
- Table generation
- Figure generation
- Validation logic

### Requires Licensed Data

- Reproduction of published quantitative results
- Reconstruction of the original Web of Science corpus

---

## Citation

If this repository is used in research, please cite the associated publication and software release.

---

## License

Code is distributed under the MIT License.

Synthetic data are fabricated for demonstration purposes and contain no proprietary Web of Science records.

Real Web of Science data remain the property of Clarivate and are not distributed through this repository.
