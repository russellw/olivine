#!/bin/sh
# Regenerate the round-trip corpus in test/data from the C sources in test/c.
#
# Run from the repository root.  Paths are kept relative so that the
# source_filename in the output does not depend on where the checkout lives.
#
# The output embeds the clang version in !llvm.ident, so regenerating with a
# different clang produces a diff in every file.  That is expected; the corpus
# is a snapshot of one compiler's output, not a normative fixture.

set -eu

CLANG=${CLANG:-clang-21}

cd "$(dirname "$0")/.."

mkdir -p test/data

for src in test/c/*.c; do
    name=$(basename "$src" .c)
    for opt in O0 O2; do
        "$CLANG" "-$opt" -S -emit-llvm -o "test/data/$name-$opt.ll" "$src"
    done
done

echo "regenerated $(ls test/data/*.ll | wc -l) files with $("$CLANG" --version | head -1)"
