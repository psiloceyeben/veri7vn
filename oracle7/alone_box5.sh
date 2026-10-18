#!/bin/sh
# alone_box5.sh - on the research box: each released Python specialist ALONE (no engine) over the same held-out
# questions the veri7vn kernels answered in parity_box5.sh, with the same harness; read-only on the release. The two runs
# are then compared item by item (agree_box5.py) to measure how often a proved kernel and the specialist it stands in
# for give the same answer. Output: /opt/veri7vn/var/parity/alone-<family>/
set -u
REPO=/opt/veri7vn
export PARITY_UPSTREAM=/opt/oracle7/release PYTHONDONTWRITEBYTECODE=1
PY=/opt/oracle7/venv/bin/python3
cd $REPO
for row in $(python3 -c "
import json
for f in json.load(open('src/extract/families.json'))['families']:
    print('%s:%s:%s' % (f['family'], f['binary'], ','.join(f['specialists'])))"); do
  fam=$(echo "$row" | cut -d: -f1); bin=$(echo "$row" | cut -d: -f2); ids=$(echo "$row" | cut -d: -f3)
  [ -x "$REPO/$bin" ] || continue
  echo "== $fam $(date -u +%FT%TZ)"
  nice -n 15 python3 -B tools/parity/harness.py --answerer "$PY tools/parity/answerers/oracle7.py --specialist {dir} --alone" \
    --specialist "$ids" --split heldout --out var/parity/alone-$fam > var/alone_box5_$fam.log 2>&1 \
    && echo "ALONE $fam DONE" || echo "ALONE $fam FAILED: $(tail -n 2 var/alone_box5_$fam.log | tr '\n' ' ')"
done
echo "ALONE_ALL_DONE $(date -u +%FT%TZ)"
