# The reception of the Uncertainty Project

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21804423.svg)](https://doi.org/10.5281/zenodo.21804423)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pipeline](https://github.com/marcoschirone/uncertainty_project/actions/workflows/pipeline.yaml/badge.svg)](https://github.com/marcoschirone/uncertainty_project/actions/workflows/pipeline.yaml)

Code and derived data for the bibliometric analysis of the Uncertainty Project,
the five-paper series published in the *Journal of the American Society for
Information Science and Technology* in 2002. The pipeline validates a Web of
Science citing corpus against a close-reading correction layer, reconstructs the
intellectual base of the five Parts, couples each citing paper to it, and runs
the sensitivity, temporal and citation-function analyses reported in the article.

> **Data.** Web of Science records cannot be redistributed. The repository ships
> synthetic exports in `data/raw/` so that the pipeline runs on a fresh clone;
> their output is illustrative only. The results obtained from the licensed
> corpus are in `results/`.

## Running the pipeline

The analysis is a [targets](https://docs.ropensci.org/targets/) pipeline. From
the project root, in R 4.3 or later:

```r
install.packages(c("targets", "bibliometrix", "dplyr", "tidyr", "stringr",
                   "purrr", "tibble", "ggplot2"))
targets::tar_make()
```

`tar_make()` skips every step whose code and inputs are unchanged since the last
run. `targets::tar_visnetwork()` draws the dependency graph and
`targets::tar_read(coupling)` returns any intermediate object. Outputs are
written to `output/` (not tracked).

Unit tests: `testthat::test_dir("tests/testthat")`. Both the tests and the full
pipeline on the synthetic data run on every push (GitHub Actions).

### With the licensed data

Place the two Web of Science plain-text exports in `data/private/`, which git
ignores:

| File | Content |
|---|---|
| `data/private/wos_parts.txt` | The five Part records, with their cited references |
| `data/private/wos_citing.txt` | Records citing the Parts (any export containing the 241 Part citers) |

When these files are present the pipeline uses them instead of the synthetic
data, checks the published corpus totals (221 citers, 134 foundations), and
refreshes `results/` with the derived tables and figures. The full citing
records and the author addresses are never copied to `results/`.

If `data/private/manuscript_values.csv` is present, the run also compares every
number reported in the article with the fresh output
(`output/checks/manuscript_check.csv`).

## Repository structure

| Path | Contents |
|---|---|
| `_targets.R` | Pipeline definition |
| `R/` | Functions, one file per stage (WoS parsing, corpus, intellectual base, coupling, sensitivity, temporal, coding, plots, reported numbers) |
| `data/reference/` | The five Parts, reference-key merge rules, self-citation patterns, strand classification, Project authors, the research groups named in the article |
| `data/corrections/` | The close-reading correction layer, record flags and base exclusions |
| `data/raw/` | Synthetic exports and `UP_dois.csv` |
| `data/manual/` | Citation-function coding templates; completed sheets go here |
| `data/private/` | Licensed exports (ignored by git) |
| `data-raw/` | Generator of the synthetic exports |
| `tests/testthat/` | Unit tests |
| `results/` | Tables and figures from the licensed corpus |

## Method in brief

1. **Corpus.** Records citing at least one Part by DOI (241) less three base
   exclusions and 17 record-level false positives give the validated corpus of
   221 papers. Corrections are recorded per Part and applied per record, so a
   paper that is a false positive for one Part but cites another stays in the
   corpus (`data/corrections/part_corrections.csv`).
2. **Intellectual base.** The external references of the five Parts after
   removing self-references, generic entries and keys without a year: 134
   foundations.
3. **Coupling.** For each citing paper, the number of foundations it shares
   with the base (Kessler, 1963), split by the uncertainty and cognitive-styles
   strands, with a three-way classification at three shared references.
4. **Sensitivity analyses.** Author overlap between citing and cited papers,
   Part-specific coupling, a citation-ageing baseline for the temporal trend,
   survivorship of all 134 foundations, venues and Research Areas.
5. **Citation function.** Table 1 rebuilt from the coding sheet on the same
   221-paper corpus, its association with reference overlap at paper level, and
   inter-coder reliability. These steps run once the coding files are in
   `data/manual/` (see the README there).

`methods_note.md` gives further detail on scope and reconciliation.

## Citation

Schirone, M. (2026). *UP Bibliographic Coupling Project* [Software]. Zenodo.
https://doi.org/10.5281/zenodo.21804423

`CITATION.cff` holds the machine-readable metadata.

## Licence

Code: MIT. The correction layer, reference classifications and derived tables
are the authors' own work and are released under the same terms. Web of
Science data remain subject to the Clarivate licence.
