# data/raw — SYNTHETIC demonstration data

The two files here are **synthetic**. They are *not* Web of Science data and
they do *not* reproduce the published results.

| File | Role |
|------|------|
| `citing_jasist5.txt` | Five synthetic "Uncertainty Project" Part records (source set for the intellectual base). |
| `323_references.txt` | 323 synthetic citing records. |

## What is real and what is fabricated

- **Fabricated:** every record's title, authors, abstract, address, journal,
  year, citation count, and the specific reference list of each *citing* paper.
- **Kept from the code (so the pipeline runs):** the five Part UTs and DOIs
  (`R/config.R`), the citing-record UTs acted on by the correction layer
  (`R/corrections.R`), and the foundational reference *keys* used for strand
  classification (`R/lookups.R`). These are bibliographic identifiers/keys that
  already ship in the code; no proprietary WoS record content is included.

Running the pipeline on these files reproduces the **shape** of the analysis —
corpus reconciliation (323 → 302 → 221), a right-skewed coupling distribution,
and uncertainty-vs-cognitive-styles strand asymmetry — but the numbers are
illustrative only. **Do not cite figures produced from synthetic data.**

## Regenerating

```
python3 data-raw/make_synthetic_wos.py
```

The generator is deterministic (fixed seed) and reads `R/config.R`,
`R/corrections.R`, and `R/lookups.R` so the fabricated identifiers stay in sync
with the code.

## Running on the real (proprietary) data

Do not overwrite these tracked files. Instead place your real WoS exports in
`data/private/` (which is git-ignored):

```
data/private/citing_jasist5.txt
data/private/323_references.txt
```

`R/config.R` automatically prefers `data/private/` when those files exist.
