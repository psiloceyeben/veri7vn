#!/usr/bin/env python3
"""make_proved_json.py - on the research box, after static_box5.sh: write var/static/PROVED.json, the map the release fold
w551 reads (specialist id -> static kernel binary, whether it takes --specialist), with the source commit, the licence, the
author credit, every binary's sha256 and the parity numbers measured on the research box. Specialists whose family binary
did not build are left out (their replies are unchanged)."""
import hashlib
import json
import os
import subprocess

REPO = "/opt/veri7vn"
OUT = REPO + "/var/static"
fams = json.load(open(REPO + "/src/extract/families.json"))["families"]
commit = subprocess.run(["git", "-C", REPO, "log", "-1", "--format=%H"], capture_output=True, text=True).stdout.strip()
agree = json.load(open(REPO + "/var/parity/agree_box5.json"))
spec, bins = {}, {}
for f in fams:
    name = os.path.basename(f["binary"])
    p = os.path.join(OUT, name)
    if not os.path.isfile(p):
        continue
    bins[name] = hashlib.sha256(open(p, "rb").read()).hexdigest()
    for sid in f["specialists"]:
        spec[sid] = {"binary": name, "flag": bool(f.get("specialist_flag", True)), "family": f["family"], "session": f["session"]}
doc = {
    "what": "veri7vn proved kernels standing in for Oracle7 specialists, used by fold w551 as a cross-check (a reply is marked proved when its kernel agrees, withheld when its kernel answers differently, unchanged otherwise).",
    "source": "https://github.com/emberian/veri7vn (fork https://github.com/psiloceyeben/veri7vn)", "commit": commit,
    "licence": "CC0-1.0", "author": "ember arlynx",
    "build": "Isabelle2026-RC1 sessions built (proofs checked) on the research box, generated Standard ML exported and linked statically with the MLton shipped in Isabelle (Linux x86-64).",
    "parity": {"heldout_questions": sum(agree["totals"].values()), **agree["totals"],
               "note": "same held-out items; agree = same answer value (or both withheld); the disagreements measured were display rounding and ASCII vs Unicode working, not different answers"},
    "binaries": bins, "specialists": spec,
}
json.dump(doc, open(os.path.join(OUT, "PROVED.json"), "w"), indent=1)
print("PROVED.json: %d binaries, %d specialists, commit %s" % (len(bins), len(spec), commit[:12]))
