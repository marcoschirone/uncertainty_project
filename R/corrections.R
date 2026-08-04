# Correction layer for validated citation corpus.
# Update this file when full-corpus validation is complete.
#
# action values:
# - remove: confirmed false-positive citation; remove citing record from corrected forward corpus.
# - add: confirmed false-negative citation. If the record is already in the WoS citing export, it will be retained.
#        If it is not in the export, add its UT to `manual_add_uts` and ensure the record is present in the raw file or supply metadata separately.
# - retain: confirmed genuine citation; no removal.
#
# The part field records the Part-level source of the correction and is retained for auditability.
#
# Last updated: full-corpus verification pass, May 2026.
# Source documents: UP_corpus_verification_list.docx +
#                   up_corpus_verification___consolidated_close_reading_results.docx

part_corrections <- tibble::tribble(
  ~UT, ~part, ~action, ~status, ~note,

  # ── Group A: single-Part false positives (carried over from earlier work, confirmed) ─────────────

  "WOS:000213371100008", "P1", "remove", "false_positive",       "Burke 2006: P1 false positive",
  "WOS:000319977100015", "P1", "remove", "false_positive",       "Vassilakaki 2012: no UP paper in reference list",
  "WOS:000230407900008", "P1", "remove", "false_positive",       "Buzikashvili 2005a: reference-list only",
  "WOS:000231381100025", "P1", "remove", "false_positive",       "Buzikashvili 2005b: reference-list only",
  "WOS:000213012500005", "P1", "remove", "false_positive",       "Koc-Michalska 2014b: no citation / no reference item",

  "WOS:000251441600008", "P3", "remove", "false_positive",       "Tenopir 2008: Part 3 not cited",
  "WOS:000292625000003", "P3", "remove", "false_positive",       "Du & Evans 2011: Part 3 not cited",
  "WOS:000288876900008", "P3", "remove", "false_positive",       "Korobili 2011: Part 3 not cited",
  "WOS:000269387000006", "P3", "remove", "false_positive",       "Ford et al. 2009: Part 3 not cited",
  "WOS:000221352500055", "P3", "remove", "false_positive",       "Spink et al. 2004: wrong Spink 2002 paper",

  # ── Group A new: P2 false positives (full-corpus verification pass) ──────────────────────────────

  # Alexopoulou & Kotsopoulou 2015: conference version inaccessible and unverifiable; Library Review
  # version (separately identified) has no UP citation. Status is inaccessible, not positively
  # confirmed false positive. P4 for this record is unavailable — see Group D below.
  "WOS:000354859800006", "P2", "remove", "inaccessible",
    "Alexopoulou 2015: P2 conference version not accessible; Library Review version has no UP citation; status unverifiable (inaccessible), not positively confirmed false positive",

  # Malla & Wani 2026: UP Part 2 appears only in Further Reading section, not cited in body text.
  # Confirmed by direct close-reading.
  "WOS:001260354900001", "P2", "remove", "false_positive",
    "Malla & Wani 2026: P2 in Further Reading only; not cited in text; confirmed by close-reading",

  # Svarre & Larsen 2025: P2 appears only as a data row in Table 1 (this paper is itself a
  # bibliometric study of Wilson citations). No substantive in-text discussion. Treated as
  # non-substantive bibliometric data object; not counted as a citing instance.
  "WOS:001519032100012", "P2", "remove", "false_positive",
    "Svarre & Larsen 2025: P2 cited only as data row in Table 1 (bibliometric object); no substantive in-text discussion; confirmed by close-reading",

  # ── Group A new: P4 false positives (full-corpus verification pass) ──────────────────────────────

  # Cen et al. 2013: P4 is reference-list only (p.18); confirmed by close-reading. NOTE: Parts 1–3
  # are genuinely cited in body text. A paired retain entry on P1 below saves the record from
  # record-level removal.
  "WOS:000327450800015", "P4", "remove", "false_positive",
    "Cen 2013: P4 reference-list only (p.18); confirmed by close-reading; Parts 1-3 genuine (see paired retain on P1)",

  # Khorin 2021: P4 in reference list but not cited in body text. Only Ford 2004 (not a UP Part)
  # cited in-text. Confirmed by close-reading.
  "WOS:000612308900009", "P4", "remove", "false_positive",
    "Khorin 2021: P4 reference-list only; only Ford 2004 cited in text; confirmed by close-reading",

  # Ravuri et al. 2026: P4 entirely absent from both reference list and text. WoS source-data error
  # (phantom match), not merely reference-list-only. Confirmed and strengthened by close-reading.
  "WOS:001729215900001", "P4", "remove", "false_positive",
    "Ravuri 2026: P4 absent from reference list and text; WoS source-data error (phantom match); confirmed by close-reading",

  # Salarian et al. 2012: P4 in reference list; an informal name mention in Methods without year
  # does not constitute a formal citation. Confirmed by close-reading.
  "WOS:000342616700052", "P4", "remove", "false_positive",
    "Salarian 2012: P4 reference-list only; informal author-name mention in Methods (no year) is not a formal citation; confirmed by close-reading",

  # Gervais & Arsenault 2005: P4 and P5 false positives carried over from earlier work.
  # P4 confirmed by close-reading (reference-list only; most items in reference list not cited).
  "WOS:000420767600003", "P4", "remove", "false_positive",
    "Gervais & Arsenault 2005: P4 reference-list only; confirmed by close-reading",
  "WOS:000420767600003", "P5", "remove", "false_positive",
    "Gervais & Arsenault 2005: P5 not cited; carried over from earlier work",

  # Vilar & Zumer 2008b (JDoc 64(6), DOI 10.1108/00220410810912415, UT WOS:000262135600003):
  # P4 confirmed false positive by close-reading (P4 in Further Reading only; not cited in text).
  # The JASIST 2008a paper is a genuine perfunctory citation and is unaffected.
  "WOS:000262135600003", "P4", "remove", "false_positive",
    "Vilar & Zumer 2008b (JDoc 64(6)): P4 in Further Reading only; confirmed by close-reading; JASIST 2008a is a separate record and unaffected",

  # ── Group B: mixed-Part cases — records with both remove and retain/add entries ────────────────

  # Ford 2004a (JASIST 55(9), WOS:000227193400002):
  # P3: NOT cited — not in reference list or text; close-reading from PDF confirms removal.
  # P2: genuinely cited; Wilson et al. 2002 discussed substantively on p.770; coded reviewed.
  # P4: genuinely cited but perfunctory (p.769 parenthetical cluster; no developed discussion);
  #     missed by WoS pattern-matching; coded perfunctory (earlier note said 'applied' — corrected).
  "WOS:000227193400002", "P3", "remove", "false_positive_for_part",
    "Ford 2004a: P3 not found in paper (absent from reference list and text); confirmed by close-reading from PDF",
  "WOS:000227193400002", "P2", "retain", "confirmed",
    "Ford 2004a: P2 genuinely cited; Wilson et al. 2002 discussed substantively on p.770; coded reviewed",
  "WOS:000227193400002", "P4", "add",    "false_negative",
    "Ford 2004a: P4 genuinely cited but perfunctory (p.769 parenthetical cluster); missed by WoS; coded perfunctory (not applied)",

  # Cen 2013 — paired retain: saves the record from record-level removal.
  # P4 is a false positive (see Group A above), but Parts 1–3 are genuinely cited in body text.
  # The retain entry on P1 ensures the record stays in the corrected corpus.
  "WOS:000327450800015", "P1", "retain", "confirmed",
    "Cen 2013: Parts 1-3 cited in body text; retain entry on P1 keeps record in corpus despite P4 false positive",

  # ── Group C: false-positive reversals and Section E discoveries ───────────────────────────────────

  # Vibert et al. 2009 (WOS:000266892700010):
  # Earlier entries had remove on both P1 and P4. Both were wrong.
  # P4: substantive (reviewed) citation on pp.5 and 16; Section B reversal confirmed by close-reading.
  # P1: genuine in-text citation in introduction (p.1); discovered in close-reading (Section E).
  "WOS:000266892700010", "P4", "retain", "confirmed",
    "Vibert 2009: P4 substantive (reviewed) citation (pp.5 and 16); Section B reversal confirmed by close-reading; earlier P4 remove entry was incorrect",
  "WOS:000266892700010", "P1", "retain", "confirmed",
    "Vibert 2009: P1 (Spink et al. 2002) cited in introduction (p.1); Section E discovery; earlier P1 remove entry was incorrect",

  # Balagatabi et al. 2015 (WOS:000218552400028):
  # Earlier entries had remove on P1, P2, and P4. All three were wrong.
  # P1: genuine citation (section 5.2, ref [37]); Section E discovery.
  # P2: genuine citation (section 5.2, ref [38]); Section A false-positive claim overturned by close-reading.
  # P4: genuine applied citation (sections 5.2–5.3; questionnaire built on P4 framework);
  #     Section B reversal confirmed; coding changed from perfunctory to applied.
  "WOS:000218552400028", "P1", "retain", "confirmed",
    "Balagatabi 2015: P1 genuinely cited (section 5.2, ref [37]); Section E discovery; earlier P1 remove entry was incorrect",
  "WOS:000218552400028", "P2", "retain", "confirmed",
    "Balagatabi 2015: P2 genuinely cited (section 5.2, ref [38]); Section A false-positive claim overturned by close-reading; earlier P2 remove entry was incorrect",
  "WOS:000218552400028", "P4", "retain", "confirmed",
    "Balagatabi 2015: P4 applied citation (sections 5.2-5.3; questionnaire built on P4 framework); Section B reversal confirmed; coding corrected from perfunctory to applied",

  # Gardiner et al. 2006 (WOS:000241243200002):
  # Appeared in verification list Section A as a P2 false positive. Close-reading found genuine
  # perfunctory in-text citation (p.343). No remove entry was ever committed; retain entry added
  # here for audit-trail completeness.
  "WOS:000241243200002", "P2", "retain", "confirmed",
    "Gardiner 2006: P2 genuinely cited (perfunctory cluster, p.343); Section A false-positive claim overturned by close-reading",

  # Chan et al. 2014 (WOS:000345148600004):
  # Appeared in verification list Section A as a P4 false positive. Close-reading found genuine
  # in-text citation (p.11, negative emotion section + Table I); coded perfunctory. No remove entry
  # was ever committed; retain entry added here for audit-trail completeness.
  "WOS:000345148600004", "P4", "retain", "confirmed",
    "Chan 2014: P4 genuinely cited in body text (p.11 + Table I; perfunctory); Section A false-positive claim overturned by close-reading",

  # ── Group D: confirmed false negatives / missed citations ────────────────────────────────────────

  # Ford 2004a P4 add: see Group B above (WOS:000227193400002).

  # Ford 2004b (JASIST 55(13), WOS:000220651200006):
  # P4 cited substantively at two locations (p.1176 and p.1177); coded applied.
  # No other UP Parts found. Confirmed by close-reading from PDF.
  "WOS:000220651200006", "P4", "add", "false_negative",
    "Ford 2004b (JASIST 55(13)): P4 applied citation (p.1176 and p.1177; cognitive style effects on searching); confirmed by close-reading from PDF",

  # Ford 2004c (J Doc 60(2), WOS:000224364700006):
  # P4 cited substantively at two locations (p.191 and p.193); coded applied.
  # No other UP Parts found. Confirmed by close-reading from PDF.
  "WOS:000224364700006", "P4", "add", "false_negative",
    "Ford 2004c (J Doc 60(2)): P4 applied citation (p.191 and p.193; P4 findings as foundational evidence for educational-informatics model); confirmed by close-reading from PDF",

  # ── Group E: unavailable papers — retained in corpus, coded unavailable ──────────────────────────

  # Eaglestone et al. 2008: source not accessible from Sheffield or Boraas. Ford-co-authored
  # (special status under primary-authorship rule). Retained per Section C.
  # Flagged for P3 and P5 in WoS citation matching.
  "WOS:000263192600042", "P3", "retain", "unavailable",
    "Eaglestone 2008: source not accessible; Ford-co-authored (primary-authorship rule applies); retained per Section C; coded unavailable",
  "WOS:000263192600042", "P5", "retain", "unavailable",
    "Eaglestone 2008: source not accessible; Ford-co-authored (primary-authorship rule applies); retained per Section C; coded unavailable",

  # Dzokoto et al. 2014: source not accessible. Flagged for P5 in WoS citation matching.
  # (Earlier corrections.R had an erroneous P1 entry — removed; P1 had no basis in any
  # verification document.)
  "WOS:000341304100014", "P5", "retain", "unavailable",
    "Dzokoto 2014: source not accessible; retained per Section C; coded unavailable",

  # Persakis & Kostagiolas 2020: source not accessible from Sheffield or Boraas.
  # Springer book chapter in conference proceedings volume. Retained per Section C.
  "WOS:000546528700006", "P2", "retain", "unavailable",
    "Persakis 2020: source not accessible (Springer book chapter in conference proceedings volume); retained per Section C; coded unavailable",

  # Alexopoulou & Kotsopoulou 2015 — P4: conference paper not accessible. Retained per Section C.
  # (This is the same UT as the P2 inaccessible entry above; P2 and P4 have different statuses
  # for this record: P2 is removed as inaccessible, P4 is retained as unavailable. The retain
  # entry here keeps the record in the corrected corpus.)
  "WOS:000354859800006", "P4", "retain", "unavailable",
    "Alexopoulou 2015: P4 conference paper not accessible; retained per Section C; coded unavailable"
)

record_flags <- tibble::tribble(
  ~UT, ~flag_type,

  # Author self-citations under primary-authorship rule
  "WOS:000220281900006", "self_citation",
  "WOS:000229202000003", "self_citation",
  "WOS:000238550100016", "self_citation",
  "WOS:000252554200008", "self_citation",
  "WOS:000234324300003", "self_citation",
  "WOS:000276504800003", "self_citation",
  "WOS:000293064100002", "self_citation",
  "WOS:000227193400002", "self_citation",
  "WOS:000220651200006", "self_citation",
  "WOS:000224364700006", "self_citation",

  # Institutional citations
  "WOS:000186515800002", "institutional",
  "WOS:000242415500001", "institutional"
)

# If full validation identifies genuine citing records that are absent from the WoS citing export,
# list their UTs here and ensure their records are available in the raw citing export or a supplemental file.
manual_add_uts <- unique(part_corrections$UT[part_corrections$action == "add"])
