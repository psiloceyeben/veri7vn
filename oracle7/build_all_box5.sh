#!/bin/sh
# build_all_box5.sh - on the research box: build EVERY veri7vn family in one pass instead of one at a time.
#   1. one `isabelle build` over all family sessions with -j 2 (Isabelle schedules shared parents once; proofs are
#      checked here, a failed proof fails that session only and the rest continue)
#   2. each family's own build.sh exports its generated SML and compiles it with Isabelle's MLton (ISABELLE_APP points
#      at the Linux Isabelle; shasum is shimmed to sha256sum; their lock and user-state paths point at ours)
#   3. relations: exported into var/relations/export-remote as its build.sh expects, then compiled with the Linux MLton
# Runs niced; the research programs share the box. Log: /opt/veri7vn/build_all.log; summary line per family.
set -u
ISA=/opt/isabelle/Isabelle2026-RC1
REPO=/opt/veri7vn
EX=$REPO/src/extract
export USER_HOME=/opt/isabelle/user-state
export ISABELLE_APP=$ISA
mkdir -p $REPO/var/native-scaffold /opt/isabelle/shim
[ -e $REPO/var/native-scaffold/user-state ] || ln -s /opt/isabelle/user-state $REPO/var/native-scaffold/user-state
touch $REPO/var/native-scaffold/build.lock
[ -x /opt/isabelle/shim/shasum ] || { printf '#!/bin/sh\n[ "$1" = "-a" ] && shift 2\nexec sha256sum "$@"\n' > /opt/isabelle/shim/shasum; chmod +x /opt/isabelle/shim/shasum; }
export PATH=/opt/isabelle/shim:$PATH
MLTON=$(ls -d $ISA/contrib/mlton-*/*/bin/mlton | head -n 1)
DIRS=""
for d in $EX/*/; do [ -f "$d/ROOT" ] && DIRS="$DIRS -d $d"; done
FAMS=$(python3 -c "import json; print(' '.join(sorted({x['family'] for x in json.load(open('$EX/families.json'))['families'] if x['family'] != 'variants'})))")
SESS=$(python3 -c "import json; print(' '.join(sorted({x['session'] for x in json.load(open('$EX/families.json'))['families']})))")
cd $REPO
echo "== isabelle build: $SESS Veri7vn_Relations ($(date -u +%FT%TZ))"
nice -n 15 $ISA/bin/isabelle build -v -b $DIRS -j 2 -o threads=2 $SESS Veri7vn_Relations > $REPO/var/isabelle_build_all.log 2>&1
echo "isabelle build exit $? ($(date -u +%FT%TZ))"
grep -E "^Finished|FAILED|Unfinished|Timing" $REPO/var/isabelle_build_all.log | grep -v Timing
for f in $FAMS; do
  [ "$f" = acoustics ] && [ -x $REPO/var/acoustics/bin/acoustics ] && { echo "FAMILY acoustics OK (built earlier)"; continue; }
  if nice -n 15 sh $EX/$f/build.sh > $REPO/var/build_$f.log 2>&1; then
    echo "FAMILY $f OK $(tail -n 1 $REPO/var/build_$f.log)"
  else
    echo "FAMILY $f FAILED: $(tail -n 3 $REPO/var/build_$f.log | tr '\n' ' ')"
  fi
done
rm -rf $REPO/var/relations/export-remote
$ISA/bin/isabelle export -n $DIRS -O $REPO/var/relations/export-remote/Veri7vn_Relations -x '*:code/**' Veri7vn_Relations > /dev/null 2>&1
sed "s#^MLTON=.*#MLTON=$MLTON#" $EX/relations/build.sh > $EX/relations/build_linux.sh
if nice -n 15 sh $EX/relations/build_linux.sh > $REPO/var/build_relations.log 2>&1; then echo "FAMILY relations OK"; else echo "FAMILY relations FAILED: $(tail -n 3 $REPO/var/build_relations.log | tr '\n' ' ')"; fi
ls -l $REPO/var/*/bin/ 2>/dev/null
echo "BUILD_ALL_DONE $(date -u +%FT%TZ)"
