# Synthetic demonstration data

`wos_parts.txt` and `wos_citing.txt` are invented records in the Web of Science
plain-text format. They are not Web of Science data and do not reproduce the
published results. Do not cite numbers computed from them.

| File | Content |
|---|---|
| `wos_parts.txt` | Five synthetic Part records with reference lists |
| `wos_citing.txt` | 323 synthetic citing records, 241 of which cite a Part |
| `UP_dois.csv` | The 195 distinct DOIs of the real citing records, kept from v1.0.0; `results/tables/corpus_records.csv` supersedes it with accession numbers and DOIs of all 241 |

What is real: the accession numbers and DOIs of the five Parts, the accession
numbers used in the correction layer, and the reference keys of the strand
classification. These are identifiers already published in `data/`. Everything
else (titles, authors, venues, years, abstracts and the reference lists of the
citing records) is generated.

The files are produced by `data-raw/make_synthetic_wos.py`, which reads
`data/reference/` and `data/corrections/` so that the identifiers match. Rerun
it after editing those files:

```bash
python3 data-raw/make_synthetic_wos.py
```

The generator is deterministic (seed 20020621).
