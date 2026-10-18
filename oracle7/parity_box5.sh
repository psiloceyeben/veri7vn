#!/bin/sh
# parity_box5.sh - on the research box: every built veri7vn family binary over the held-out exams of the released
# specialists it stands in for, scored by each specialist's own scorer with the fork's parity harness (read-only on the
# release; a held-out exam is not spent). Upstream = the installed Oracle7 release. Niced: research programs share the box.
# Output: /opt/veri7vn/var/parity/box5-<family>/ per family, and the board /opt/veri7vn/var/parity/BOARD_box5.md
set -u
REPO=/opt/veri7vn
export PARITY_UPSTREAM=/opt/oracle7/release PYTHONDONTWRITEBYTECODE=1
cd $REPO
RUNS=""
for row in $(python3 -c "
import json
for f in json.load(open('src/extract/families.json'))['families']:
    print('%s:%s:%s:%s' % (f['family'], f['binary'], int(f.get('specialist_flag', True)), ','.join(f['specialists'])))"); do
  fam=$(echo "$row" | cut -d: -f1); bin=$(echo "$row" | cut -d: -f2); flag=$(echo "$row" | cut -d: -f3); ids=$(echo "$row" | cut -d: -f4)
  [ -x "$REPO/$bin" ] || { echo "PARITY $fam SKIPPED: no binary $bin"; continue; }
  CMD="$REPO/$bin"; [ "$flag" = 1 ] && CMD="$CMD --specialist {id}"
  echo "== $fam ($ids) $(date -u +%FT%TZ)"
  nice -n 15 python3 -B tools/parity/harness.py --answerer "$CMD" --specialist "$ids" --split heldout --out var/parity/box5-$fam > var/parity_box5_$fam.log 2>&1 \
    && echo "PARITY $fam DONE" || echo "PARITY $fam FAILED: $(tail -n 2 var/parity_box5_$fam.log | tr '\n' ' ')"
  RUNS="$RUNS --run $fam=var/parity/box5-$fam"
done
python3 -B tools/parity/board.py $RUNS --out var/parity/BOARD_box5.md > /dev/null 2>&1 && echo "board: var/parity/BOARD_box5.md"
echo "PARITY_ALL_DONE $(date -u +%FT%TZ)"
