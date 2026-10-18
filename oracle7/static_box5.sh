#!/bin/sh
# static_box5.sh - on the research box: relink every built veri7vn family as a STATIC Linux x86-64 binary (no libgmp or
# glibc version needed on the user's machine), from the same .mlb the build compiled (generated kernel + commons +
# recognizer + main). Output /opt/veri7vn/var/static/<binary> plus SHA256SUMS. The proofs are unchanged: the generated SML
# is the same file the Isabelle build exported.
set -u
REPO=/opt/veri7vn
MLTON=$(ls -d /opt/isabelle/Isabelle2026-RC1/contrib/mlton-*/*/bin/mlton | head -n 1)
OUT=$REPO/var/static
mkdir -p $OUT
cd $REPO
for row in $(python3 -c "
import json
for f in json.load(open('src/extract/families.json'))['families']:
    print('%s:%s' % (f['family'], f['binary']))"); do
  fam=$(echo "$row" | cut -d: -f1); bin=$(echo "$row" | cut -d: -f2); name=$(basename "$bin")
  mlb=$REPO/var/$fam/build/$fam.mlb
  [ -f "$mlb" ] || { echo "STATIC $fam SKIPPED: no $mlb"; continue; }
  (cd $REPO/var/$fam/build && nice -n 15 "$MLTON" -link-opt -static -output "$OUT/$name" "$mlb" > $OUT/$fam.log 2>&1) \
    && echo "STATIC $fam OK" || echo "STATIC $fam FAILED: $(tail -n 2 $OUT/$fam.log | tr '\n' ' ')"
done
if [ -f $REPO/var/relations/bin/decide.mlb ]; then
  (cd $REPO/var/relations/bin && nice -n 15 "$MLTON" -link-opt -static -output "$OUT/decide" decide.mlb > $OUT/relations.log 2>&1) && echo "STATIC relations OK" || echo "STATIC relations FAILED"
fi
cd $OUT && sha256sum $(ls | grep -v '\.log$' | grep -v SHA256SUMS) > SHA256SUMS
echo "STATIC_ALL_DONE $(date -u +%FT%TZ)"
