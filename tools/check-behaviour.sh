#!/bin/sh
# Compile each corpus file twice — as it is, and as olivine writes it back —
# link both against the same driver, and compare what they print.
#
# This is what replaces byte-identical output as the check on the core.  Once
# phi nodes are eliminated the text differs by design, so the question stops
# being whether the program comes back unchanged and becomes whether it comes
# back doing the same thing.
set -eu

CLANG=${CLANG:-clang-21}
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

olivine=$(cabal list-bin exe:olivine)
pass=0
fail=0

for pair in "arith ARITH" "branch BRANCH" "loop LOOP" "memops MEMOPS" "hello HELLO" \
            "escape ESCAPE" "jumps JUMPS" "unions UNIONS" "indirect INDIRECT" \
            "linkage LINKAGE" "hoist HOIST" "reload RELOAD" \
            "rotate ROTATE" "pick PICK" "bytes BYTES"; do
    set -- $pair
    base=$1
    macro=$2
    for level in O0 O1 O2; do
        name="$base-$level.ll"
        "$olivine" "test/data/$name" -o "$work/$name"
        "$CLANG" "-D$macro" -w test/c-driver.c "test/data/$name" -o "$work/before" 2>/dev/null
        "$CLANG" "-D$macro" -w test/c-driver.c "$work/$name" -o "$work/after" 2>/dev/null
        "$work/before" > "$work/before.txt" 2>&1 || true
        before=$?
        "$work/after" > "$work/after.txt" 2>&1 || true
        after=$?
        if [ "$before" = "$after" ] && cmp -s "$work/before.txt" "$work/after.txt"; then
            pass=$((pass + 1))
        else
            echo "DIFFERS: $name"
            diff "$work/before.txt" "$work/after.txt" | head -5 || true
            fail=$((fail + 1))
        fi
    done
done

# Hand written cases the corpus does not contain.
for name in swap dead fold unused promote order inline shared; do
    "$olivine" "test/ll/$name.ll" -o "$work/$name.ll"
    "$CLANG" -w "test/ll/$name-driver.c" "test/ll/$name.ll" -o "$work/before" 2>/dev/null
    "$CLANG" -w "test/ll/$name-driver.c" "$work/$name.ll" -o "$work/after" 2>/dev/null
    "$work/before" > "$work/before.txt" 2>&1 || true
    "$work/after" > "$work/after.txt" 2>&1 || true
    if cmp -s "$work/before.txt" "$work/after.txt"; then
        pass=$((pass + 1))
    else
        echo "DIFFERS: $name.ll"
        diff "$work/before.txt" "$work/after.txt" | head -5 || true
        fail=$((fail + 1))
    fi
done

echo "$pass modules behave identically, $fail differ"
[ "$fail" = 0 ]
