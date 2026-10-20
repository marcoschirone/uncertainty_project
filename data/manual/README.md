# Citation-function coding

The citation-function analyses run once coding files are placed in this folder.
Without them, those steps are skipped and the rest of the pipeline runs as
usual.

## Files

| File | Content |
|---|---|
| `R2_03_coding.csv` or `citation_function_codes.csv` | Primary coding, one row per paper and Part |
| `R2_06_second_coder.csv` or `citation_function_second_coder.csv` | Blind second coding of a sample |

Save the sheets from Excel as *CSV UTF-8*. Column names are not case-sensitive:

| Column | Values |
|---|---|
| `UT` | Web of Science accession number |
| `part` | `P1` to `P5` |
| `function` | `perfunctory`, `reviewed`, `supported`, `negative` or `applied` |
| `coder` | optional, e.g. `C1` |
| `notes` | optional |
| `contrastive`, `misattribution` | optional, `Y` when applicable |

The Excel exports (`R2_0*.csv`) are ignored by git because they may contain
quoted text. The run writes clean files with the first five columns to
`output/coding/`; deposit those.

## Analyses

- **Table 1** on the 221-paper corpus, under the primary-author rule (the
  cited Part's primary author is not an author of the citing paper) and the
  any-author rule, with tests, pairwise and cell-level comparisons, coverage
  of the coded links, per-Part reconciliation and false-positive rates.
- **Function and overlap.** Each paper is classed as perfunctory only or
  substantive (any reviewed, supported, negative or applied citation) and
  cross-tabulated with its overlap class, so that every paper counts once.
  The Part-by-function table is repeated for papers citing a single Part.
- **Reliability.** Raw agreement and Cohen's kappa for the five categories and
  for the binary collapse, computed on the blind codes before adjudication.
