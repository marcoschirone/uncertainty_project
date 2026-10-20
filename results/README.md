# Results from the licensed corpus

Tables and figures computed from the Web of Science Core Collection exports
(citing records retrieved 22 June 2026, Part records exported 11 May 2026).
The pipeline writes this folder whenever it runs on the licensed data; the
synthetic demonstration never touches it.

## What is included and what is withheld

The Clarivate licence restricts redistribution of Web of Science records, not
the counts, classifications and judgements derived from them. This folder holds
only the latter:

- aggregate tables and test results;
- the correction layer and its audit trail, which record the authors'
  close-reading judgements;
- the intellectual base, i.e. reference keys from the reference lists of the
  five Parts;
- per-record tables restricted to accession number, DOI, title, year, source,
  author names and derived measures.

Withheld: the full citing records (`corrected_citing_records.csv`: abstracts,
cited-reference fields, addresses, funding) and the author addresses in
`author_overlap_records.csv`. `tables/corpus_records.csv` lists the accession
number and DOI of each of the 241 retrieved records, with its status, so that
a subscriber can rebuild the corpus.

## Contents

| Path | Content |
|---|---|
| `tables/corpus_records.csv` | The 241 records: status (retained, removed, base exclusion), validated Parts, removal reason |
| `tables/corpus_reconciliation.csv` | 241 retrieved, 3 base exclusions, 17 false positives, 221 validated |
| `tables/correction_audit_trail.csv` | Every Part-level judgement and how it was applied |
| `tables/*_correction_summary.csv` | Corrections by Part and by record |
| `tables/up_foundations.csv`, `foundation_in_up.csv`, `foundation_exclusion_summary.csv` | The 134 foundations and the exclusions |
| `tables/overlap_matrix.csv` | Foundations shared between Parts |
| `tables/coupling_summary.csv`, `coupling_classification_summary.csv` | Coupling of the 221 papers: 178 share a foundation; 105 / 73 / 43 high, limited and no overlap |
| `tables/intellectual_heirs.csv`, `intermediate_citers.csv`, `surface_citers.csv` | The papers in each class |
| `tables/foundation_counts.csv`, `strand_summary.csv`, `temporal_summary.csv` | Reproduced foundations, strands, years |
| `tables/revision_R1/` | Sensitivity, Part-specific, temporal, survivorship, venue and claim-check tables added in revision |
| `figures/`, `figures/revision_R1/` | The figures |
| `reported_numbers.csv` | Every number reported in the article, recomputed |
| `logs/session_info.txt` | Corpus totals and the R session of the run |

## Provenance

The tables in this version were generated on 20 October 2026 with R 4.3.3 and
bibliometrix 5.3.0 (`logs/session_info.txt`). The run of 30 September 2026
with R 4.6.1 gave the same values, except the Wilcoxon p-value in
`revision_R1/strand_contrast_all_foundations.csv` (0.137 instead of 0.138) and
the last printed digit of one Jaccard index.
