#!/usr/bin/env python3
"""agree_box5.py - item by item, does each veri7vn kernel give the same answer as the released Python specialist it stands
in for? Reads the two parity runs on the research box (var/parity/box5-<family> = kernel, alone-<family> = specialist
alone, same held-out items). Per item:
  agree        both answered with the same answer value (the first number, within 0.1%), or both withheld
  disagree     both answered, numbers differ  <- the proved cross-check would withhold these
  kernel_only  the kernel answered, the specialist did not (the cross-check leaves the specialist's decline)
  organ_only   the specialist answered, the kernel did not (the cross-check leaves the specialist's answer)
Per specialist and totals; disagreements listed with both replies. Writes var/parity/agree_box5.json."""
import glob
import json
import os
import re
import sys
from collections import Counter

NUM = re.compile(r"-?\d[\d,]*(?:\.\d+)?(?:[eE][+-]?\d+)?")
base = sys.argv[1] if len(sys.argv) > 1 else "/opt/veri7vn/var/parity"


def nums(t):
    out = []
    for m in NUM.finditer(str(t or "")):
        try:
            out.append(float(m.group(0).replace(",", "")))
        except ValueError:
            pass
    return out


def same(a, b):
    na, nb = nums(a), nums(b)
    if not na or not nb:
        return a.strip() == b.strip()
    k = 1                                   # the answer value: the first number (the rest restate the working, in ASCII or Unicode)
    return all(abs(x - y) <= 1e-3 * max(abs(x), abs(y), 1e-12) for x, y in zip(na[:k], nb[:k]))


def load(path):
    out = {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            if line.strip():
                j = json.loads(line)
                out[j["id"]] = j.get("reply") or {}
    return out


tot, per, dis = Counter(), {}, []
for kf in sorted(glob.glob(os.path.join(base, "box5-*", "*.heldout.items.jsonl"))):
    fam = os.path.basename(os.path.dirname(kf))[5:]
    sid = os.path.basename(kf).split(".heldout")[0]
    K, A = load(kf), load(os.path.join(base, "alone-" + fam, os.path.basename(kf)))
    c = Counter()
    for iid, kr in K.items():
        ar = A.get(iid)
        if ar is None:
            c["no_pair"] += 1
            continue
        ka, aa = kr.get("status") == "answered", ar.get("status") == "answered"
        if ka and aa:
            if same(kr.get("response", ""), ar.get("response", "")):
                c["agree"] += 1
            else:
                c["disagree"] += 1
                dis.append({"specialist": sid, "item": iid, "kernel": str(kr.get("response"))[:220], "specialist_reply": str(ar.get("response"))[:220]})
        elif not ka and not aa:
            c["agree"] += 1
        elif ka:
            c["kernel_only"] += 1
        else:
            c["organ_only"] += 1
    per[sid] = dict(c, family=fam)
    tot.update(c)
json.dump({"totals": dict(tot), "per_specialist": per, "disagreements": dis}, open(os.path.join(base, "agree_box5.json"), "w"), indent=1)
print("TOTALS", dict(tot))
print("specialists fully in agreement:", sum(1 for v in per.values() if not v.get("disagree") and not v.get("no_pair")), "of", len(per))
for d in dis[:25]:
    print("DISAGREE", d["specialist"], "|", d["kernel"][:110], "||", d["specialist_reply"][:110])
