# Methods note

## Corpus scope

The constitutive corpus is the five JASIST 2002 Parts (Spink Pt1, Wilson Pt2,
Spink Pt3, Ford Pt4, Ellis Pt5). The three pre-2002 precursors (Wilson 1999
*IP&M*; Wilson 1999 conference; Ford et al. 2000 ASIS) are contextual and are
not used to construct the intellectual base. Because the precursors are no
longer treated as part of the series, Wilson (1999, *IP&M*) re-enters the
analysis as an external foundation reference rather than being suppressed as a
self-citation.

The forward citation corpus was first assembled from Web of Science and then validated using a correction layer derived from close reading. Confirmed false-positive citing records were removed from the forward corpus, while confirmed missed citations were retained or added where the record was present in the raw export. The resulting corpus is therefore a curated WoS-derived citation corpus.

The correction layer preserves Part-level audit information, but the bibliographic coupling is computed at the citing-record level. This means that mixed cases, where a paper is false-positive for one Part but a genuine citation for another, are retained in the corrected forward corpus.

Once full-corpus validation is complete, update `R/corrections.R` and rerun `scripts/00_run_all.R`.

## Reconciliation language

For manuscript reporting, use the `corpus_reconciliation.csv` output rather than manually calculating corpus changes from Part-level corrections. The number of Part-level false-positive annotations is not necessarily equal to the number of records removed, because mixed cases are retained where another citation to the UP is verified.
