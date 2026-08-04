#!/usr/bin/env python3
"""
make_synthetic_wos.py
=====================================================================
Generate SYNTHETIC Web of Science plain-text exports for the
Uncertainty Project bibliographic-coupling pipeline.

WHY THIS EXISTS
---------------
The real analysis is run on Web of Science Core Collection exports,
which are proprietary and cannot be redistributed. This utility
fabricates two WoS-format files with the SAME STRUCTURE the pipeline
expects -- the five Part UTs and DOIs, the citing-record UTs referenced
by R/corrections.R, the strand reference keys in R/lookups.R -- but with
entirely invented records (titles, authors, abstracts, and the specific
reference lists of citing papers).

IMPORTANT
---------
The outputs are ILLUSTRATIVE ONLY. Running the pipeline on these files
reproduces the *shape* of the analysis (corpus reconciliation, a coupling
distribution, strand asymmetry) but NOT the published numbers. Do not
cite figures produced from synthetic data.

The script reads R/config.R, R/corrections.R and R/lookups.R so the
fabricated identifiers stay in sync with the code. Output is written to
data/raw/citing_jasist5.txt and data/raw/323_references.txt.

This is a one-off data-fabrication helper. The analysis pipeline itself
is pure R and has no Python dependency.
"""

import os
import re
import random

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
R = os.path.join(ROOT, "R")
RAW = os.path.join(ROOT, "data", "raw")
os.makedirs(RAW, exist_ok=True)

SEED = 20020621
random.seed(SEED)

# --------------------------------------------------------------------------
# Parse identifiers out of the R source so the synthetic data matches the code
# --------------------------------------------------------------------------
def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()

def strip_r_comments(text):
    """Remove '# ...' comments that are outside string literals, line by line."""
    out = []
    for line in text.splitlines():
        in_str = False
        cut = len(line)
        for i, ch in enumerate(line):
            if ch == '"':
                in_str = not in_str
            elif ch == "#" and not in_str:
                cut = i
                break
        out.append(line[:cut])
    return "\n".join(out)

cfg = strip_r_comments(read(os.path.join(R, "config.R")))
corr = read(os.path.join(R, "corrections.R"))
look = strip_r_comments(read(os.path.join(R, "lookups.R")))

def c_block(text, name):
    m = re.search(name + r"\s*<-\s*c\((.*?)\)", text, re.S)
    if not m:
        return []
    return re.findall(r'"([^"]+)"', m.group(1))

all_five_uts = c_block(cfg, "all_five_uts")
jasist_uts   = c_block(cfg, "jasist_uts")
erratum_uts  = c_block(cfg, "erratum_uts")
part_dois    = c_block(cfg, "part_dois")

uncertainty_keys = c_block(look, "uncertainty_keys") or c_block(look, "info_behaviour_keys")
cognitive_keys   = c_block(look, "cognitive_styles_keys")
up_self_patterns = c_block(look, "up_self_patterns")

# Correction UTs by action, plus record-flag UTs (all must exist in the raw set)
def tribble_rows(text, varname):
    m = re.search(varname + r"\s*<-\s*tibble::tribble\((.*?)\n\)", text, re.S)
    return m.group(1) if m else ""

pc = tribble_rows(corr, "part_corrections")
# rows look like:  "WOS:...", "P4", "remove", "false_positive", "note"
remove_uts, retain_add_uts, all_corr_uts = set(), set(), set()
for ut, part, action in re.findall(r'"(WOS:\d+)",\s*"(P\d)",\s*"(\w+)"', pc):
    all_corr_uts.add(ut)
    if action == "remove":
        remove_uts.add(ut)
    elif action in ("retain", "add"):
        retain_add_uts.add(ut)
add_uts = set(re.findall(r'"(WOS:\d+)",\s*"P\d",\s*"add"', pc))

rf = tribble_rows(corr, "record_flags")
flag_uts = set(re.findall(r'"(WOS:\d+)"', rf))

base_excl = set(jasist_uts) | set(erratum_uts)
rec_fp = remove_uts - retain_add_uts            # records dropped entirely

print("Parsed from code:")
print(f"  Part UTs={len(all_five_uts)} DOIs={len(part_dois)} "
      f"base_excl={len(base_excl)} corr_UTs={len(all_corr_uts)} "
      f"flag_UTs={len(flag_uts)} rec_fp={len(rec_fp)} add={len(add_uts)}")
print(f"  uncertainty keys={len(uncertainty_keys)} cognitive keys={len(cognitive_keys)}")

# --------------------------------------------------------------------------
# Target corpus shape (mirrors the real study so the demo is recognisable)
# --------------------------------------------------------------------------
N_RAW          = 323
N_PART_CITERS  = 221       # Part-citers within the corrected corpus
N_SYNTH_FOUND  = 45        # extra fabricated (non-strand) foundations

# --------------------------------------------------------------------------
# Build the synthetic foundation pool
# --------------------------------------------------------------------------
synth_found = [f"SYNTHREF {i:03d}, {random.randint(1975, 2001)}, SYNTH J INFORM SCI, V{i%40+1}, P{i*3+1}"
               for i in range(1, N_SYNTH_FOUND + 1)]
# normalised keys for the synthetic foundations
def norm_key(cr):
    parts = re.split(r",\s*", cr)
    key = ", ".join(parts[:3]) if len(parts) >= 3 else parts[0]
    return re.sub(r"\s+", " ", key).strip().upper()

# Real strand keys are reference *keys*; turn them into plausible CR strings
def key_to_cr(key):
    # add volume/page so it looks like a WoS reference; first 3 comma fields
    # already equal the key, so normalisation round-trips exactly
    return f"{key}, V{random.randint(1,60)}, P{random.randint(1,400)}"

strand_crs = {k: key_to_cr(k) for k in (uncertainty_keys + cognitive_keys)}
all_found_crs = list(strand_crs.values()) + synth_found
all_found_keys = [norm_key(c) for c in all_found_crs]

GENERIC = ["[Anonymous], 2005, SYNTH WORKING PAPER", "*SYNTH ORG, 2009, SYNTH REPORT"]

# --------------------------------------------------------------------------
# WoS record writer
# --------------------------------------------------------------------------
JOURNALS = ["SYNTHETIC J INFORM SCI", "J SYNTH KNOWL ORG", "SYNTH INFORM RES",
            "INT J SYNTH INFORMETR", "SYNTH LIBR TRENDS"]

def record(ut, ti, py, so, crs, di=None, dt="Article", tc=0, au="Synthetic, A"):
    lines = []
    lines.append("PT J")
    lines.append(f"AU {au}")
    lines.append(f"AF {au}")
    lines.append(f"TI {ti}")
    lines.append(f"SO {so}")
    lines.append("LA English")
    lines.append(f"DT {dt}")
    lines.append("DE synthetic; demonstration")
    lines.append("AB Synthetic record generated for pipeline demonstration; not a real publication.")
    lines.append("C1 [Synthetic, A] Synthetic Univ, Dept Demo, Synth City, Synthland")
    lines.append(f"NR {len(crs)}")
    lines.append(f"TC {tc}")
    lines.append(f"PY {py}")
    if di:
        lines.append(f"DI {di}")
    if crs:
        lines.append(f"CR {crs[0]}")
        for c in crs[1:]:
            lines.append(f"   {c}")
    lines.append(f"UT {ut}")
    lines.append("ER")
    lines.append("")
    return "\n".join(lines)

def write_wos(path, records):
    with open(path, "w", encoding="utf-8") as f:
        f.write("FN Clarivate Analytics Web of Science\nVR 1.0\n")
        for r in records:
            f.write(r + "\n")
        f.write("EF\n")

# --------------------------------------------------------------------------
# 1) UP source file: the five Parts
# --------------------------------------------------------------------------
part_titles = [
    "Synthetic Part 1: a framework (DEMO DATA)",
    "Synthetic Part 2: uncertainty (DEMO DATA)",
    "Synthetic Part 3: successive search (DEMO DATA)",
    "Synthetic Part 4: cognitive styles (DEMO DATA)",
    "Synthetic Part 5: intermediary interaction (DEMO DATA)",
]
# self-citation reference strings (so the self-exclusion logic is exercised)
self_crs = [f"{p}, V53, P{600+i}, DOI {part_dois[i % len(part_dois)]}"
            for i, p in enumerate(up_self_patterns)]

up_records = []
for i, ut in enumerate(all_five_uts):
    # each Part cites: a slice of strand foundations + some synthetic + self + generic
    unc_slice = [strand_crs[k] for k in uncertainty_keys[i::len(all_five_uts)]]
    cog_slice = [strand_crs[k] for k in cognitive_keys[i::len(all_five_uts)]]
    syn_slice = random.sample(synth_found, k=min(12, len(synth_found)))
    crs = unc_slice + cog_slice + syn_slice + self_crs + GENERIC
    random.shuffle(crs)
    up_records.append(record(
        ut=ut, ti=part_titles[i], py=2002, so="J SYNTH ASSOC INFORM SCI TECHNOL",
        crs=crs, di=part_dois[i], tc=random.randint(50, 300), au="Synthetic, P"
    ))
write_wos(os.path.join(RAW, "citing_jasist5.txt"), up_records)

# --------------------------------------------------------------------------
# 2) Citing file: 323 records
# --------------------------------------------------------------------------
# Required UTs that must exist in the raw export (sorted for reproducibility:
# iterating a Python set has process-dependent order).
required = sorted(base_excl | all_corr_uts | flag_uts)
# Pad with fabricated UTs up to N_RAW
synth_uts = []
n_needed = N_RAW - len(required)
base_n = 9_000_000_000_000_00  # distinct synthetic UT block
for i in range(n_needed):
    synth_uts.append(f"WOS:{base_n + i:015d}")
all_uts = required + synth_uts
assert len(all_uts) == N_RAW, (len(all_uts), N_RAW)

# Corrected corpus (302) = raw - base_excl - rec_fp
corrected = [u for u in all_uts if u not in base_excl and u not in rec_fp]
# Choose which corrected records cite a Part (Part-citers, target 221).
# Records that genuinely cite the UP in the correction layer (retain/add) must
# be Part-citers; fill the rest from synthetic UTs.
must_cite = [u for u in corrected if u in retain_add_uts]
pool = [u for u in corrected if u not in must_cite]
random.shuffle(pool)
n_more = max(0, N_PART_CITERS - len(must_cite))
part_citers = set(must_cite) | set(pool[:n_more])
# remaining corrected records reach the UP only via a (synthetic) precursor

PRECURSOR_CR = "Synthwilson TD, 1999, SYNTH INFORM PROCESS MANAG, V35, P839"

# A pool of references that NO UP Part cites -> never enter the intellectual
# base. Citing papers use these as realistic filler, so sharing a foundation
# is a genuine (not automatic) event and surface citers can occur.
NOISE_POOL = [f"NOISEREF {i:03d}, {random.randint(1990, 2025)}, NOISE J SYNTH, V{i%50+1}, P{i*2+3}"
              for i in range(1, 260 + 1)]

# Weighted foundation pool: uncertainty and synthetic foundations are more
# likely to be reproduced than cognitive-styles works, mirroring the real
# strand asymmetry.
FOUND_WEIGHTED = ([(strand_crs[k], 3.0) for k in uncertainty_keys] +
                  [(c, 2.0) for c in synth_found] +
                  [(strand_crs[k], 1.0) for k in cognitive_keys])

def weighted_sample(items_weights, t):
    """Weighted sampling without replacement (Efraimidis-Spirakis)."""
    if t <= 0:
        return []
    keyed = sorted(((random.random() ** (1.0 / w), c) for c, w in items_weights), reverse=True)
    return [c for _, c in keyed[:t]]

# Right-skewed shared-count distribution (~20% zeros, mean ~3.8, heavy tail).
SHARE_VALUES  = [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 21, 30]
SHARE_WEIGHTS = [20, 16, 16, 12, 9, 7, 5, 5, 4, 3, 2, 1]

def citing_crs(ut):
    crs = []
    if ut in part_citers:
        # cite 1-3 of the five Parts
        for d_i in random.sample(range(len(part_dois)), random.randint(1, 3)):
            crs.append(f"Synthpart {d_i+1}, 2002, J SYNTH ASSOC INFORM SCI TECHNOL, "
                       f"V53, P{600+d_i}, DOI {part_dois[d_i]}")
        # how many foundations this paper reproduces (0 => surface citer)
        t = random.choices(SHARE_VALUES, weights=SHARE_WEIGHTS)[0]
        crs += weighted_sample(FOUND_WEIGHTED, t)
    else:
        # precursor-only reach: no Part DOI
        crs.append(PRECURSOR_CR)
    # filler: non-foundation references (do not create overlap)
    crs += random.sample(NOISE_POOL, k=random.randint(6, 20))
    random.shuffle(crs)
    return crs

cit_records = []
for j, ut in enumerate(all_uts):
    if ut in all_five_uts or ut in jasist_uts:
        ti = "Synthetic intra-series cross-citation (DEMO DATA)"
    elif ut in erratum_uts:
        ti = "Synthetic correction/erratum (DEMO DATA)"
    else:
        ti = f"Synthetic citing study {j+1:03d} (DEMO DATA)"
    cit_records.append(record(
        ut=ut, ti=ti, py=random.randint(2003, 2026),
        so=random.choice(JOURNALS), crs=citing_crs(ut),
        dt="Article", tc=random.randint(0, 80),
        au=f"Synthauthor {j%50}, X"
    ))
write_wos(os.path.join(RAW, "323_references.txt"), cit_records)

# --------------------------------------------------------------------------
# Report (self-check of the structural counts)
# --------------------------------------------------------------------------
print("\nWrote synthetic exports to data/raw/:")
print(f"  citing_jasist5.txt : {len(up_records)} UP source records")
print(f"  323_references.txt : {len(cit_records)} citing records")
print(f"  -> corrected corpus (raw - base - rec_fp) = {len(corrected)}")
print(f"  -> Part-citers (cite >=1 Part DOI)        = {len(part_citers)}")
print(f"  -> distinct foundation keys available     = {len(set(all_found_keys))}")
print(f"  seed = {SEED}")
