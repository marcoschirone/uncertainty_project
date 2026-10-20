# Correction layer

| File | Content |
|---|---|
| `part_corrections.csv` | Close-reading judgements, one row per record and Part |
| `record_flags.csv` | Self-citations under the primary-author rule and institutional citations |
| `base_exclusions.csv` | Intra-series cross-citations and the erratum |

`part_corrections.csv`: `action` is `remove` (Part not cited in the body
text), `retain` (citation confirmed) or `add` (citation missed by Web of
Science); `status` qualifies it (`false_positive`, `false_positive_for_part`,
`confirmed`, `false_negative`, `unavailable`, `inaccessible`); `category`
groups the rows; `note` gives the evidence. See `methods_note.md` for how the
judgements are applied.
