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
CLANGXX=${CLANGXX:-clang++-21}

cd "$(dirname "$0")/.."

mkdir -p test/data

# The C++ sources are here for one construct apiece that a C front end never
# emits.  They go through the same four levels as the rest: what a level emits
# is what its own pipeline emits, and exception handling is where the levels
# differ most, -O1 and above merging landing pads that -O0 writes out one per
# invoke.
for src in test/c/*.c test/c/*.cpp; do
    case "$src" in
    *.cpp)
        name=$(basename "$src" .cpp)
        compiler=$CLANGXX
        ;;
    *)
        name=$(basename "$src" .c)
        compiler=$CLANG
        ;;
    esac
    # -O1 is here because it is a level, not because these files at it contain
    # anything in particular.  It was left out at first as being between the
    # other two, which is the wrong way to choose: what a level emits is what
    # its own pipeline emits, and reading Olivine's own -O1 output crashed it on
    # a shape neither -O0 nor -O2 produces.  These sources do not happen to
    # produce that shape either — test/ll/order.ll is what pins it — so what
    # this buys is the level being exercised at all rather than any one
    # construct.
    for opt in O0 O1 O2; do
        "$compiler" "-$opt" -S -emit-llvm -o "test/data/$name-$opt.ll" "$src"
    done
    # A fourth level that is not one of clang's: the front end's own output,
    # with every middle-end pass turned off but the attributes an optimizing
    # level asks for.  -O0 is unoptimized and unusable as a test of the
    # optimizer, because clang stamps `noinline optnone` on a group every
    # function points at, and -O1 has already promoted the slots and folded the
    # arithmetic that Olivine is here to do.  This is the pair pulled apart:
    # allocas and reloads as written, and nothing telling anybody to leave them
    # alone.  It also carries !tbaa, which the -O0 files do not.
    "$compiler" -O1 -Xclang -disable-llvm-passes -S -emit-llvm \
        -o "test/data/$name-raw.ll" "$src"
done

echo "regenerated $(ls test/data/*.ll | wc -l) files with $("$CLANG" --version | head -1)"
