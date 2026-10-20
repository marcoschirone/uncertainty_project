#!/usr/bin/env python3
"""Generate synthetic Web of Science exports for the demonstration run.

The licensed Web of Science records cannot be redistributed. This script writes
two plain-text exports in the WoS tagged format with the structure the pipeline
expects: the five Part records with their reference lists, and a citing set
that contains every accession number used by the correction layer. Titles,
authors, abstracts, venues and the reference lists of citing records are
invented. Results computed from these files are illustrative only.

Identifiers are read from data/reference/ and data/corrections/, so the script
must be re-run whenever those files change:

    python3 data-raw/make_synthetic_wos.py

Output: data/raw/wos_parts.txt and data/raw/wos_citing.txt. Deterministic
(seed 20020621).
"""

import csv
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "data", "raw")
SEED = 20020621
random.seed(SEED)

N_RAW = 323            # records in the citing export
N_PART_CITERS = 241    # records citing at least one Part by DOI
N_SYNTH_FOUND = 45     # invented foundations outside the two strands
EXPORT_PARTS = "2026-05-11"
EXPORT_CITING = "2026-06-22"


def read_csv(*path):
    with open(os.path.join(ROOT, "data", *path), encoding="utf-8") as f:
        return list(csv.DictReader(f))


parts = read_csv("reference", "parts.csv")
strands = read_csv("reference", "strand_keys.csv")
self_patterns = [r["pattern"] for r in read_csv("reference", "self_citation_patterns.csv")]
project_authors = [r["author"] for r in read_csv("reference", "project_authors.csv")]
corrections = read_csv("corrections", "part_corrections.csv")
flags = read_csv("corrections", "record_flags.csv")
base_exclusions = [r["UT"] for r in read_csv("corrections", "base_exclusions.csv")]

part_uts = [p["UT"] for p in parts]
part_dois = [p["doi"] for p in parts]
part_pages = [p["start_page"] for p in parts]
uncertainty_keys = [r["ref_key"] for r in strands if r["strand"] == "Uncertainty"]
cognitive_keys = [r["ref_key"] for r in strands if r["strand"] == "Cognitive styles"]

remove_uts = {r["UT"] for r in corrections if r["action"] == "remove"}
retain_add_uts = {r["UT"] for r in corrections if r["action"] in ("retain", "add")}
record_fp = remove_uts - retain_add_uts
flag_uts = {r["UT"] for r in flags}

# --------------------------------------------------------------------------
# Reference pools
# --------------------------------------------------------------------------


def key_to_cr(key):
    """A WoS-style reference whose first three fields reproduce the key."""
    return f"{key}, V{random.randint(1, 60)}, P{random.randint(1, 400)}"


strand_crs = {k: key_to_cr(k) for k in uncertainty_keys + cognitive_keys}
synth_found = [f"SYNTHREF {i:03d}, {random.randint(1975, 2001)}, SYNTH J INFORM SCI, "
               f"V{i % 40 + 1}, P{i * 3 + 1}" for i in range(1, N_SYNTH_FOUND + 1)]
noise_pool = [f"NOISEREF {i:03d}, {random.randint(1990, 2025)}, NOISE J SYNTH, "
              f"V{i % 50 + 1}, P{i * 2 + 3}" for i in range(1, 261)]
generic = ["[Anonymous], 2005, SYNTH WORKING PAPER", "*SYNTH ORG, 2009, SYNTH REPORT"]
in_press = ["SPINK A, IN PRESS INFORMATION", "WILSON TD, IN PRESS INFORMATI 2"]

journals = ["JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY",
            "INFORMATION RESEARCH-AN INTERNATIONAL ELECTRONIC JOURNAL",
            "JOURNAL OF DOCUMENTATION", "INFORMATION PROCESSING & MANAGEMENT",
            "SYNTHETIC JOURNAL OF INFORMATION STUDIES", "SYNTHETIC HEALTH INFORMATICS",
            "SYNTHETIC LEARNING TECHNOLOGIES"]
journal_weights = [6, 2, 2, 2, 5, 1, 1]
research_areas = {
    journals[0]: "Computer Science; Information Science & Library Science",
    journals[1]: "Information Science & Library Science",
    journals[2]: "Computer Science; Information Science & Library Science",
    journals[3]: "Computer Science; Information Science & Library Science",
    journals[4]: "Information Science & Library Science",
    journals[5]: "Health Care Sciences & Services; Medical Informatics",
    journals[6]: "Education & Educational Research; Computer Science",
}
doc_types = ["Article", "Proceedings Paper", "Article; Proceedings Paper", "Review"]
doc_weights = [78, 8, 7, 7]

# --------------------------------------------------------------------------
# WoS record writer
# --------------------------------------------------------------------------


def wos_author(name):
    """'SPINK A' -> 'Spink, A'; synthetic names pass through."""
    surname, _, initials = name.partition(" ")
    return f"{surname.title()}, {initials}" if initials else name


def record(ut, ti, py, so, crs, authors, export_date, di=None, dt="Article", tc=0):
    lines = ["PT J", "AU " + authors[0]] + ["   " + a for a in authors[1:]]
    lines += ["AF " + authors[0]] + ["   " + a for a in authors[1:]]
    lines += [f"TI {ti}", f"SO {so}", "LA English", f"DT {dt}",
              "DE synthetic; demonstration",
              "AB Synthetic record generated for pipeline demonstration; not a real publication.",
              f"C1 [{authors[0]}] Synthetic Univ, Dept Demo, Synth City, Synthland.",
              f"NR {len(crs)}", f"TC {tc}", f"PY {py}"]
    if di:
        lines.append(f"DI {di}")
    lines.append(f"SC {research_areas.get(so, 'Information Science & Library Science')}")
    if crs:
        lines.append(f"CR {crs[0]}")
        lines += ["   " + c for c in crs[1:]]
    lines += [f"DA {export_date}", f"UT {ut}", "ER", ""]
    return "\n".join(lines)


def write_wos(path, records):
    with open(path, "w", encoding="utf-8") as f:
        f.write("FN Clarivate Analytics Web of Science\nVR 1.0\n")
        for r in records:
            f.write(r + "\n")
        f.write("EF\n")


# --------------------------------------------------------------------------
# The five Parts
# --------------------------------------------------------------------------
part_titles = ["framework", "uncertainty", "successive searching", "cognitive styles",
               "intermediary interaction"]
self_crs = [f"{p}, V53, P{600 + i}, DOI {part_dois[i % len(part_dois)]}"
            for i, p in enumerate(self_patterns)]

part_records = []
for i, ut in enumerate(part_uts):
    crs = ([strand_crs[k] for k in uncertainty_keys[i::len(part_uts)]] +
           [strand_crs[k] for k in cognitive_keys[i::len(part_uts)]] +
           random.sample(synth_found, k=12) + self_crs + generic)
    if i in (2, 3):
        crs.append(in_press[i - 2])
    random.shuffle(crs)
    part_records.append(record(
        ut=ut, ti=f"Synthetic Part {i + 1}: {part_titles[i]} (DEMO DATA)", py=2002,
        so="JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY",
        crs=crs, authors=[wos_author(a) for a in ("SPINK A", "WILSON TD", "FORD N")],
        export_date=EXPORT_PARTS, di=part_dois[i], tc=random.randint(50, 300)))

# --------------------------------------------------------------------------
# The citing export
# --------------------------------------------------------------------------
required = sorted(set(base_exclusions) | {r["UT"] for r in corrections} | flag_uts)
synth_uts = [f"WOS:{900000000000000 + i:015d}" for i in range(N_RAW - len(required))]
all_uts = required + synth_uts

# Mirror the real corpus: records with a retain/add annotation and record-level
# false positives cite a Part; so do the base exclusions except Part 2's own
# record, which reaches the export only through a precursor.
base_non_citer = {base_exclusions[0]}
must_cite = (retain_add_uts | record_fp | (set(base_exclusions) - base_non_citer)) & set(all_uts)
pool = [u for u in all_uts if u not in must_cite and u not in base_non_citer]
random.shuffle(pool)
part_citers = must_cite | set(pool[:max(0, N_PART_CITERS - len(must_cite))])

found_weighted = ([(strand_crs[k], 3.0) for k in uncertainty_keys] +
                  [(c, 2.0) for c in synth_found] +
                  [(strand_crs[k], 1.0) for k in cognitive_keys])
share_values = [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 21, 30]
share_weights = [20, 16, 16, 12, 9, 7, 5, 5, 4, 3, 2, 1]


def weighted_sample(items, t):
    """Weighted sampling without replacement (Efraimidis-Spirakis)."""
    keyed = sorted(((random.random() ** (1.0 / w), c) for c, w in items), reverse=True)
    return [c for _, c in keyed[:t]]


def citing_crs(ut):
    crs = []
    if ut in part_citers:
        for d in random.sample(range(len(part_dois)), random.choice([1, 1, 1, 1, 2, 3])):
            crs.append(f"Synthpart {d + 1}, 2002, J AM SOC INF SCI TEC, V53, "
                       f"{part_pages[d]}, DOI {part_dois[d]}")
        crs += weighted_sample(found_weighted, random.choices(share_values, share_weights)[0])
        if random.random() < 0.02:
            crs.append(in_press[0])
    else:
        crs.append("Synthwilson TD, 1999, SYNTH INFORM PROCESS MANAG, V35, P839")
    crs += random.sample(noise_pool, k=random.randint(6, 20))
    random.shuffle(crs)
    return crs


synth_names = [f"Synthauthor{i:02d}, X" for i in range(60)]


def citing_authors(j):
    authors = random.sample(synth_names, k=random.randint(1, 3))
    if random.random() < 0.08:
        authors.insert(random.randint(0, len(authors)), wos_author(random.choice(project_authors[:6])))
    return authors


cit_records = []
for j, ut in enumerate(all_uts):
    if ut in base_exclusions[:-1]:
        ti = "Synthetic intra-series cross-citation (DEMO DATA)"
    elif ut == base_exclusions[-1]:
        ti = "Synthetic correction (DEMO DATA)"
    else:
        ti = f"Synthetic citing study {j + 1:03d} (DEMO DATA)"
    so = random.choices(journals, journal_weights)[0]
    cit_records.append(record(
        ut=ut, ti=ti, py=random.randint(2002, 2026), so=so, crs=citing_crs(ut),
        authors=citing_authors(j), export_date=EXPORT_CITING,
        di=f"10.9999/synthetic.{j + 1:04d}", dt=random.choices(doc_types, doc_weights)[0],
        tc=random.randint(0, 80)))

os.makedirs(RAW, exist_ok=True)
write_wos(os.path.join(RAW, "wos_parts.txt"), part_records)
write_wos(os.path.join(RAW, "wos_citing.txt"), cit_records)

print(f"wos_parts.txt : {len(part_records)} Part records")
print(f"wos_citing.txt: {len(cit_records)} citing records, {len(part_citers)} citing a Part, "
      f"{len(part_citers & set(base_exclusions))} base exclusions, "
      f"{len(part_citers & record_fp)} record-level false positives, "
      f"{len(part_citers - set(base_exclusions) - record_fp)} validated")
