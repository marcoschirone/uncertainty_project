# Methods note

## Scope

The object of study is the five JASIST 2002 Parts (Spink et al., Part 1;
Wilson et al., Part 2; Spink et al., Part 3; Ford et al., Part 4; Ellis et al.,
Part 5). The three pre-2002 precursors (Wilson 1999 *IP&M*, Wilson 1999
conference paper, Ford et al. 2000 ASIS) are context, not Parts. The intellectual
base is therefore built from the references of the five Parts only, and only
references to the Parts themselves are excluded as self-references. Earlier
outputs of the research programme cited by a Part count as external
foundations; in this corpus that admits Wilson (1999, *Exploring the contexts
of information behaviour*) and Wilson (1997, uncertainty). Wilson (1999, *IP&M*)
is cited by no Part and so does not enter the base.

## Corpus construction

The citing export may cover more documents than the five Parts. Records that do
not cite a Part by DOI are dropped (the 323 to 241 step of the first retrieval).
Three records are then excluded as intra-series cross-citations or an erratum
(`data/corrections/base_exclusions.csv`; the fourth listed record, Part 2's own,
does not cite a Part and is absent from the 241).

Close reading is recorded per Part and applied per record
(`data/corrections/part_corrections.csv`):

- `remove`: the Part is not cited in the body text;
- `retain`: the citation is confirmed;
- `add`: a citation missed by Web of Science.

A record leaves the corpus only when every annotation on it is a removal. Mixed
records, false positives for one Part that cite another, stay. The number of
Part-level removal annotations (23) therefore differs from the number of
records removed (17).

For reporting, use `corpus_reconciliation.csv` and `corpus_records.csv` rather
than counting annotations.

## Reference keys

Each cited reference is reduced to its first three comma-separated fields,
normally author, year and source, upper-cased. Known variants are merged with
`data/reference/merge_rules.csv`. Keys without a year, such as in-press
citations, are excluded from the base because they reduce to an author name and
would match unrelated references.

## Part attribution

A citing record cites a Part when its references contain the Part's DOI or the
2002 volume-53 start page, after which the corrections are applied. Attribution
is used by the per-Part and Part-specific analyses; the coupling itself is
computed per record.
