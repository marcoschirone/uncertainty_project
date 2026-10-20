# Licensed inputs

This folder is ignored by git except for this file. Put the Web of Science
plain-text exports here to run the analysis on the licensed corpus:

```
data/private/wos_parts.txt     the five Part records
data/private/wos_citing.txt    records citing the Parts
```

The published results use the export of the 241 Part-citing records of
22 June 2026 and the Part export of 11 May 2026.

Optional: `manuscript_values.csv`, the numbers printed in the article, keyed by
the ids of `output/checks/reported_numbers.csv`. When present, the run writes
`output/checks/manuscript_check.csv`. Columns: `id`, `revised`, `submitted`,
`location`, `revised_judgement`, `submitted_judgement`, `note`.
