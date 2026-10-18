#!/bin/sh
# build_kernel_box5.sh <slug> <Session> <binary-name> [extra session dir ...] - on the research box: build one veri7vn family
# session with the Linux Isabelle2026-RC1 in /opt/isabelle (its theorems are checked here; the build fails if a proof fails),
# export the generated Standard ML, and compile it with the MLton that ships inside Isabelle, the way the family's own
# build.sh does on macOS: generated kernel + commons + the untrusted recognizer + main.sml. Runs niced (the research
# programs share the box). Output: /opt/veri7vn/var/<slug>/bin/<binary-name>, its sha256 and the build log.
set -eu
SLUG=$1; SESSION=$2; BIN=$3; shift 3
ISA=/opt/isabelle/Isabelle2026-RC1
MLTON=$(ls -d $ISA/contrib/mlton-*/*/bin/mlton | head -n 1)
REPO=/opt/veri7vn
SRC=$REPO/src/extract/$SLUG
OUT=$REPO/var/$SLUG
export USER_HOME=/opt/isabelle/user-state
mkdir -p "$OUT/bin" "$OUT/build" "$USER_HOME"
DIRS="-d $SRC -d $REPO/src/extract/commons"
for d in "$@"; do DIRS="$DIRS -d $REPO/src/extract/$d"; done
cd "$REPO"
echo "== build $SESSION ($(date -u +%FT%TZ))"
nice -n 15 $ISA/bin/isabelle build -v -b $DIRS -j 1 -o threads=3 "$SESSION" > "$OUT/build.log" 2>&1 || { tail -40 "$OUT/build.log"; echo "BUILD FAILED"; exit 1; }
tail -3 "$OUT/build.log"
rm -rf "$OUT/export"
$ISA/bin/isabelle export -n $DIRS -O "$OUT/export" -x '*:code/**' "$SESSION" > /dev/null
GEN=$(find "$OUT/export" -type f -name '*.ML' -o -type f -name '*.sml' | grep -v -i test | head -n 1)
[ -n "$GEN" ] || GEN=$(find "$OUT/export" -type f | head -n 1)
[ -n "$GEN" ] || { echo "no generated SML under $OUT/export"; exit 1; }
cp "$GEN" "$OUT/build/${SLUG}_generated.sml"
{
  echo '$(SML_LIB)/basis/basis.mlb'
  echo "${SLUG}_generated.sml"
  [ -f "$REPO/src/extract/commons/commons.sml" ] && echo "$REPO/src/extract/commons/commons.sml"
  [ -f "$SRC/regex.sml" ] && echo "$SRC/regex.sml"
  [ -f "$SRC/recognizer.sml" ] && echo "$SRC/recognizer.sml"
  echo "$SRC/main.sml"
} > "$OUT/build/$SLUG.mlb"
echo "== mlton ($(date -u +%FT%TZ))"
nice -n 15 "$MLTON" -output "$OUT/bin/$BIN" "$OUT/build/$SLUG.mlb"
ls -l "$OUT/bin/$BIN"
sha256sum "$OUT/build/${SLUG}_generated.sml" "$OUT/bin/$BIN"
echo "KERNEL_BUILT $SLUG $(date -u +%FT%TZ)"
